## Why

When an admin is removed from an org, or an admin request is denied, the org ID
is never removed from the user's `UserProfile.orgIDs` array. The org continues
to appear on the user's landing screen even though all reads and writes are
blocked by Firestore rules. Fixes issue #35.

## What Changes

- **`OrgRepo.removeAdmin`**: Uncomment the already-written `_userRepo.removeOrg`
  call that was commented out since the initial commit.
- **`OrgRepo.denyAdminRequest`**: Wrap the existing `delete()` call in a
  `runTransaction` and add `_userRepo.removeOrg(t, userID, orgID)` inside it so
  the profile update is atomic with the request deletion.
- **Tests**: Update `removeAdmin deletes admin` and `denyAdminRequest deletes
  request` in `org_repo_test.dart` to stub and verify `mockUserRepo.removeOrg`.

## Capabilities

### New Capabilities

- none

### Modified Capabilities

- `data-repo-layer`: The contract for admin lifecycle operations now requires
  that `UserProfile.orgIDs` is kept in sync on both addition *and* removal paths
  (remove admin, deny request).

## Impact

- `packages/roombooker_core/lib/data/repos/org_repo.dart` — two method changes
- `packages/roombooker_core/test/data/repos/org_repo_test.dart` — two test updates
- No UI changes; no interface changes; no new dependencies
