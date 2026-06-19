## Context

Kiosk instant bookings (`bookedVia: 'kiosk'`) write two Firestore documents atomically: `confirmed-requests/{id}` (the booking) and `request-details/{id}` (a `PrivateRequestDetails` with `meetingUrl: null`). The Kiosk dashboard already conditionally renders a JOIN button based on `meetingUrl` — the button simply never appears for instant bookings because the field is never populated.

The project uses Google Workspace, enabling service-account-based access to the Google Meet REST API. Cloud Functions are Node.js v1 (`firebase-functions/v1`). The Kiosk is a Flutter app running in Android `LockTaskMode`; its dashboard widget is a stateful Flutter widget (`_KioskDashboardState`) that streams booking data from Firestore.

## Goals / Non-Goals

**Goals:**
- Automatically create a Google Meet Space when a Kiosk instant booking is created and write the URL to `request-details/{id}.meetingUrl`.
- Surface a clear in-progress state on the Kiosk while provisioning is underway.
- On Meet API failure: clean up the booking fully and surface a high-level error message so the user can retry.
- On client timeout (30s): self-clean the booking and surface a timeout message.
- Log error details to Cloud Function logs for operator investigation.

**Non-Goals:**
- Auto-provisioning for portal bookings (portal users are expected to supply their own link for now).
- Auto-retry on failure (user manually retries via Quick Book).
- Surfacing Meet API error details on the Kiosk screen.
- Creating Google Calendar events alongside the Meet Space.

## Decisions

### D1: Service Account (dedicated, not shared)
A dedicated `meet-provisioner` service account is created rather than reusing the Firebase Admin SDK account. Rationale: least-privilege — this account needs only `meetings.space.created` scope and no Firebase Admin access. The key is stored in Secret Manager and injected into the Cloud Function via environment config.

**Alternative considered:** Reuse the existing Admin SDK service account. Rejected: that account has broad Firebase Admin permissions; mixing Meet API access into it violates least-privilege and complicates future key rotation.

### D2: Meet Space, not Calendar Event
`meet.googleapis.com/v2/spaces` (POST) creates a standalone Meet Space owned by the service account. This returns a stable `meetingUri` (`meet.google.com/xxx-yyy-zzz`) without creating a Calendar event.

**Alternative considered:** Google Calendar API + `conferenceData` to create an event that auto-generates a Meet link. Rejected: the room booking system is the calendar — creating a parallel Google Calendar event would be redundant and harder to keep in sync.

### D3: Trigger — `onRequestApproved` sibling, not modification
A new Cloud Function `onKioskBookingCreated` listens to the same `onCreate` event on `confirmed-requests/{orgID}/{bookingID}` as the existing `onRequestApproved`. It exits immediately if `bookedVia !== 'kiosk'`, making the two functions fully independent.

**Alternative considered:** Adding Meet provisioning logic inside `onRequestApproved`. Rejected: the existing function handles email notifications for portal bookings; mixing provisioning into it would tightly couple unrelated concerns and make future scoping changes harder.

### D4: Error Signaling via Transient Error Document
On failure, the CF writes a document to `orgs/{orgID}/rooms/{roomID}/provisioning-errors/{errorID}` before deleting the booking. The Kiosk subscribes to this subcollection for its room. On user dismissal, the Kiosk deletes the error doc.

**Alternative considered:** Writing a `provisioningState: 'failed'` field to `request-details/{id}` before deletion. Rejected: the booking deletion races with the Kiosk reading the error field — the Kiosk may see the doc disappear before it sees the state change.

**Alternative considered:** Separate `kiosk-status` document per room. Rejected: more complex to manage; the subcollection approach naturally handles multiple concurrent events without a single document being a write bottleneck.

### D5: Provisioning State Inferred, Not Stored
The Kiosk infers the PROVISIONING state from: `bookedVia == 'kiosk' AND meetingUrl == null`. No extra field is written to represent "in progress." This avoids an intermediate Firestore write that could be lost if the function crashes mid-execution.

### D6: Client Timeout of 30s, CF Timeout of 15s
The Cloud Function's timeout is set to 15s — enough for Meet API calls (typically <3s) with headroom for cold starts. The client-side watchdog fires at 30s, giving the CF 15s of buffer to finish and write the error doc before the client acts unilaterally. On client timeout, the Kiosk deletes `confirmed-requests/{id}` (it already has Firestore write access to its room's confirmed-requests per existing rules) and shows a timeout banner. The `request-details/{id}` orphan is cleaned up by the CF's `onDelete` trigger or accepted as a minor data leak until a future cleanup job.

**Alternative considered:** Client-side 15s timeout (same as CF). Rejected: if the CF just barely times out and is writing the error doc when the client fires, there's a race. The 15s gap between CF timeout (15s) and client timeout (30s) eliminates this race.

### D7: No Auto-Retry
Retry is manual — user re-taps a Quick Book button. The Meet API is generally reliable; automatic retry with backoff adds complexity (duplicate space creation risk, state machine complexity) for a rare failure mode.

## Risks / Trade-offs

**[Risk] CF cold start delays push past client timeout** → Mitigated by the 15s gap (CF at 15s, client at 30s). Cold starts on Node.js functions are typically 2-5s; the 15s CF timeout still leaves ample execution time. If cold starts become a recurring issue, setting `minInstances: 1` on the function eliminates them.

**[Risk] Meet API outage** → CF catches the error, cleans up, writes error doc. Kiosk shows "Couldn't generate Meet link, tap to retry." The room is freed immediately. No booking is left in a zombie state.

**[Risk] Kiosk deletes its booking (timeout path) while CF is still executing** → CF's update to `request-details/{id}` will encounter a missing parent context but will not crash the app. The CF may also try to delete the already-deleted `confirmed-requests/{id}` — Firestore deletes are idempotent and will succeed silently.

**[Risk] Service account key rotation** → Key is in Secret Manager; rotation requires updating the secret version and redeploying the function. Should be documented in the ops runbook.

**[Risk] `provisioning-errors` docs accumulate if Kiosk is offline** → Error docs are only written when provisioning fails. The Kiosk reads them on reconnect and shows the error retroactively. Since the booking was already deleted, the room is available — the error banner is informational. A TTL policy on the subcollection could auto-expire old docs if this becomes noisy.

## Migration Plan

1. **Terraform apply**: create `meet-provisioner` service account, enable Meet API, create Secret Manager secret with the SA key.
2. **Set function config**: `firebase functions:config:set meetprovisioner.key="$(base64 -w0 key.json)"` (or via Secret Manager reference).
3. **Deploy Cloud Functions**: `firebase deploy --only functions` — new `onKioskBookingCreated` is additive; no existing functions are modified.
4. **Deploy Firestore rules**: `firebase deploy --only firestore:rules` — new `provisioning-errors` rule is additive.
5. **Ship Kiosk APK**: new PROVISIONING/ERROR/TIMEOUT states are backwards-compatible; existing bookings without `bookedVia: 'kiosk'` are unaffected.

**Rollback**: delete the `onKioskBookingCreated` function, revert Firestore rules. Kiosk APK gracefully handles `meetingUrl == null` (no Join button) — no rollback needed on the Flutter side.

## Open Questions

- **Meet Space join policy**: Should the Meet Space created by the service account require a lobby/waiting room, or allow anyone with the link to join immediately? This is governed by Workspace policy for service-account-owned spaces and should be verified in the Workspace Admin Console after initial deployment.
- **Secret Manager vs. environment config**: The function can consume the SA key via Secret Manager (more secure, supports rotation without redeployment) or `functions.config()` (simpler, less secure). Prefer Secret Manager if the Firebase plan supports it.
