## 1. Extend onAdminRequestRevoked

- [ ] 1.1 In `functions/index.js`, inside `onAdminRequestRevoked`, after the email send, add `arrayRemove` of `orgID` from `users/{userID}.orgIDs` using the Admin SDK (guard with a `.exists()` check on the profile doc first)

## 2. Add onAdminRequestDenied trigger

- [ ] 2.1 In `functions/index.js`, add a new `onDelete` trigger on `orgs/{orgID}/admin-requests/{userID}` named `onAdminRequestDenied`
- [ ] 2.2 Inside the trigger, check whether `orgs/{orgID}/active-admins/{userID}` exists; if it does, return early (request was approved, not denied)
- [ ] 2.3 If no active-admin entry exists, remove `orgID` from `users/{userID}.orgIDs` via `arrayRemove` (guard with `.exists()` check on the profile doc)

## 3. Remove dead Dart code

- [ ] 3.1 In `packages/roombooker_core/lib/data/repos/org_repo.dart`, delete the commented-out `_userRepo.removeOrg` line from `removeAdmin`

## 4. Tests

- [ ] 4.1 In `functions/test/`, add a Jest test for `onAdminRequestDenied` — denial path: no active-admin entry → `arrayRemove` is called on the user profile
- [ ] 4.2 Add a Jest test for `onAdminRequestDenied` — approval path: active-admin entry exists → function returns without updating profile

## 5. Verify

- [ ] 5.1 Run `(cd functions && npm test)` — all tests pass
- [ ] 5.2 Run `flutter analyze` — no issues from the dead code removal
