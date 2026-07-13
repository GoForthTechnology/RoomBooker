## Why

When an org owner invites a user by email via the Admin Invite flow, the invitee receives no notification — they only discover the pending invite if they happen to open the app and land on that org's booking page. This makes the invite effectively invisible, leaving invitees waiting without knowing to take action.

## What Changes

- A Cloud Functions Firestore trigger fires when a document is created in `orgs/{orgID}/pending-invites/{email}`.
- The trigger sends a transactional email to the invited address explaining they have been invited to become an administrator of the org, with a direct link to the org's booking page (or the app's root URL if no deep link is available).
- No Flutter/Dart changes are required; the fix lives entirely in `functions/index.js`.

## Capabilities

### New Capabilities

- `admin-invite-email`: Sends a notification email to the invitee when a pending admin invite is created, using the existing `sendEmail` helper and the `mail` Firestore collection (Firebase Extension).

### Modified Capabilities

- `admin-invite`: The invite lifecycle now includes an outbound email notification step at creation time.

## Impact

- **`functions/index.js`**: New `onDocumentCreated` trigger on `orgs/{orgID}/pending-invites/{email}`.
- **`functions/test/`**: New test file covering the email trigger.
- **Firestore / Firebase Extension**: No changes needed — the existing `mail` collection trigger handles delivery.
- **Flutter code**: No changes.
