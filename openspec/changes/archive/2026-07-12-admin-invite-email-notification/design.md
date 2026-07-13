## Context

The existing Cloud Functions use the v1 Firebase Functions API (`functions.firestore.document().onCreate()`) to send transactional emails via the `mail` Firestore collection (picked up by a Firebase Extension). Triggers already exist for admin requests, approvals, and removals. The `sendEmail(to, subject, message)` helper encapsulates the write.

When `addAdminInvite` is called from the Flutter client, it writes to `orgs/{orgID}/pending-invites/{email}`. No Cloud Function currently listens for this event, so the invitee receives no notification.

## Goals / Non-Goals

**Goals:**
- Send a notification email to the invited address when a pending invite document is created.
- Use the org name in the email body for clarity.
- Include a direct link to the org's join page so the invitee can act immediately.

**Non-Goals:**
- Firebase Dynamic Links or deferred deep links for users without an account.
- Retry logic for email delivery failures (consistent with existing pattern).
- Email templating or HTML email — all existing emails are plain text.

## Decisions

**D1: Use v1 `functions.firestore.document().onCreate()` trigger**
All existing Cloud Function triggers use the v1 API style. Using v1 keeps the codebase consistent and avoids introducing a v2 import alongside the existing v1 imports.

**D2: Derive recipient address from document ID, not document data**
The `pending-invites` document is keyed by the normalised email address. The document also stores `email` in its body, but reading the document ID is zero-cost and avoids any potential mismatch. Use `context.params.email` as the recipient.

**D3: Look up org name via `getOrg(orgID)`**
The same helper is used by `onNewAdminRequest`, `onAdminRequestApproved`, and `onAdminRequestRevoked`. The email body should name the org, so a Firestore read is necessary. Reuse the existing helper rather than duplicating the read logic.

**D4: Link to `/join/{orgID}` on the Portal**
The Portal router has a `/join/:orgID` route designed for the org join flow, where the pending invite claim dialog appears. The base URL is derived from the `PORTAL_BASE_URL` environment variable, falling back to `https://roombooker-5e947.web.app` if unset. This avoids hardcoding while providing a safe default.

**D5: Swallow email delivery errors, log them**
Consistent with `onAdminRequestRevoked`, a failed email should not propagate as a function error (which would cause Cloud Functions to retry the trigger). Wrap `sendEmail` in a try/catch and log failures.

## Risks / Trade-offs

- **Email delivery failure is silent to the sender**: The org owner has no visibility that the invite email bounced. → Mitigation: log the error; a future change could add owner notification on failure.
- **Link is useless to non-account-holders until sign-up**: The `/join/:orgID` route requires sign-in. → Mitigation: the existing invite spec already handles this case (the invite stays dormant until first sign-in); the email body should note the requirement.
- **No idempotency guard on the trigger**: If the document is deleted and re-created (e.g., an owner cancels and re-invites), the email fires again. → This is the desired behaviour — a re-invite should re-notify.

## Migration Plan

1. Add the `onAdminInviteCreated` trigger export to `functions/index.js`.
2. Add a `PORTAL_BASE_URL` environment variable to the Functions configuration (optional; defaults to `https://roombooker-5e947.web.app`).
3. Deploy functions: `firebase deploy --only functions`.
4. No Firestore rule or index changes required.
5. Rollback: remove the export and redeploy.
