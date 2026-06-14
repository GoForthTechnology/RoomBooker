## Context

`Request.meetingUrl` is a top-level field on documents in the
`orgs/{orgID}/confirmed-requests` collection, which Firestore rules make
publicly readable (`allow read: if true`). `PrivateRequestDetails` already
exists as a sibling `private-request-details/{requestID}` document holding
`name`, `email`, `phone`, `message`, `eventName`, and is already protected by
rules that only allow admins and the room-scoped Kiosk to read it
(`kiosk-access-control`). Moving `meetingUrl` there closes the public
exposure with no new security-rule work.

Two consumers currently read `Request.meetingUrl` directly:
- Portal `RequestEditorViewModel` (read for editing, write on save).
- Kiosk `KioskDashboard` (`_launchMeeting`), which only reads `Request` via
  `BookingService.listRequests` — it does not currently fetch
  `PrivateRequestDetails` for the current booking.

## Goals / Non-Goals

**Goals:**
- `meetingUrl` lives exclusively on `PrivateRequestDetails` going forward.
- No existing meeting links are lost during the transition.
- Kiosk "Join Meeting" button continues to work for the active booking.

**Non-Goals:**
- Changing Firestore security rules (REQ-13 access is already in place).
- Implementing auto-provisioning of Meet links (Phase 5 / REQ-14, REQ-18).
- Building the Quick Book flow (4d) — this change only clears the
  prerequisite.

## Decisions

### 1. Field move, not field duplication
`meetingUrl` is removed from `Request` (entity + JSON ser/deser) rather than
kept as a deprecated mirror. Keeping a synced copy on both documents would
re-create the public-exposure problem this change exists to fix, and would
require write-path code to keep them consistent indefinitely.
- Alternative considered: keep `Request.meetingUrl` nullable and
  read-only/deprecated for backward compat. Rejected — the field itself is
  the privacy leak; any non-null value sitting in a publicly-readable
  document defeats the purpose.

### 2. One-time backfill script, not a dual-read transition window
The proposal's REQ-12 allows either migrating existing documents or being
read-compatible during a transition. Given the small, single-org-per-deploy
scale of this project (per `PROGRAM_PLAN.md` / `data-model`), a one-time
admin script run immediately before deploying the new code is simpler and
avoids permanent dual-read branches in `BookingRepo`.
- Script lives at `functions/scripts/migrate_meeting_urls.js`, uses
  `firebase-admin` with application-default credentials (consistent with
  other one-off admin tooling in this repo), iterates every
  `orgs/{orgID}/confirmed-requests` doc with a non-null `meetingUrl`, and
  upserts that value into the doc's `private-request-details/{requestID}`,
  then clears `meetingUrl` from the `confirmed-requests` doc.
- Alternative considered: Cloud Function migration triggered on deploy.
  Rejected as overkill for a single-run backfill; would leave dead code in
  `functions/index.js` after running once.

### 3. Kiosk fetches `PrivateRequestDetails` for the current booking
The Kiosk dashboard currently never calls
`BookingService.getRequestDetails`. To show "Join Meeting", it now fetches
`PrivateRequestDetails` for `currentBooking.id` once a current booking is
identified, using the existing room-scoped read access from
`kiosk-access-control`.
- Alternative considered: have `BookingService.listRequests`/`getRequestsStream`
  always join `PrivateRequestDetails` for every returned request. Rejected —
  `booking-service`'s enrichment already does targeted detail fetches only
  where needed (e.g. private event names for admins); adding a full join for
  all list views would multiply Firestore reads for data the Portal calendar
  views don't need.

### 4. Portal request editor reads/writes via `PrivateRequestDetails`
`RequestEditorViewModel` already loads and saves `PrivateRequestDetails` for
name/email/phone/message/eventName via `BookingService.getRequestDetails` and
`updateBooking`/`addBooking`/`submitBookingRequest`. `meetingUrl` becomes
just another field on that same object — no new data-loading path needed.

## Risks / Trade-offs

- [Risk] A `confirmed-requests` doc created between "backfill script runs"
  and "new app version deployed" could still write `meetingUrl` onto
  `Request` using the old client. → Mitigation: this is a low-traffic,
  single-tenant deployment (per `version-driven-cd`); run the backfill
  script as part of the same release that ships the new code, immediately
  before/after deploy, minimizing the window. Any link written in that
  window is still readable publicly but is a pre-existing condition, not a
  regression.
- [Risk] Forgetting to update one of the ~10 call sites
  (`request.dart`/`request.g.dart`/view models/tests) leaves a stale
  reference to `Request.meetingUrl`, which will fail to compile once the
  field is removed — this is actually a feature: `flutter analyze` /
  `flutter test` will catch any missed call site.

## Migration Plan

1. Add `meetingUrl` to `PrivateRequestDetails` (entity + generated code),
   keep `Request.meetingUrl` for now so the app still compiles against
   current Firestore data.
2. Update Portal/Kiosk read paths to prefer
   `PrivateRequestDetails.meetingUrl`.
3. Run `functions/scripts/migrate_meeting_urls.js` against the production
   project to backfill `PrivateRequestDetails.meetingUrl` and clear
   `Request.meetingUrl` on existing `confirmed-requests` docs.
4. Remove `meetingUrl` from `Request` (entity + generated code + write
   paths) and update all tests.
5. Deploy.

Rollback: if step 4's deploy needs to be rolled back before step 3's script
has run, no data has changed yet — safe. If rolled back after the script has
run, the previous app version reads `Request.meetingUrl`, which the script
cleared; in that narrow window "Join Meeting" would not show on rolled-back
clients until the new version is redeployed. Given this is a low-traffic
internal tool, this is an acceptable trade-off and is not automated.

## Open Questions

None.
