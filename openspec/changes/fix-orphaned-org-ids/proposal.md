## Why

When an admin is removed from an org, or an admin request is denied, the org ID
is never removed from the user's `UserProfile.orgIDs` array. The org continues
to appear on the user's landing screen even though all reads and writes are
blocked by Firestore rules. The root cause is a permissions gap: the Firestore
`users/{userID}` rule only allows `request.auth.uid == userID`, so no third
party (including an org admin) can update another user's profile from the
client. Fixes issue #35.

## What Changes

- **`functions/index.js` — `onAdminRequestRevoked`**: Extend the existing
  `onDelete` trigger on `orgs/{orgID}/active-admins/{userID}` to also remove
  `orgID` from `users/{userID}.orgIDs` via `FieldValue.arrayRemove`. (The
  email notification in this function stays unchanged.)
- **`functions/index.js` — `onAdminRequestDenied`** (new): Add a new
  `onDelete` trigger on `orgs/{orgID}/admin-requests/{userID}`. Because this
  path is deleted on both approval and denial, the function checks whether
  `active-admins/{userID}` now exists; if not, it removes `orgID` from the
  user's `orgIDs`.
- **`packages/roombooker_core/lib/data/repos/org_repo.dart`**: Remove the
  dead commented-out `_userRepo.removeOrg` call from `removeAdmin`. No other
  Dart changes are needed.
- **Tests**: Add a Jest test for `onAdminRequestDenied` covering the deny
  path and the approve-no-op path.

## Capabilities

### New Capabilities

- none

### Modified Capabilities

- `data-repo-layer`: The contract for admin lifecycle operations now requires
  that `UserProfile.orgIDs` is kept in sync on both addition *and* removal
  paths (remove admin, deny request). The mechanism is Cloud Function triggers
  rather than client-side writes.

## Impact

- `functions/index.js` — two function changes (one new, one extended)
- `packages/roombooker_core/lib/data/repos/org_repo.dart` — dead code removal
- `functions/test/` — new Jest test
- No Flutter/Dart logic changes; no Firestore rule changes; no new dependencies
