## 1. Fix removeAdmin

- [ ] 1.1 In `OrgRepo.removeAdmin`, uncomment `_userRepo.removeOrg(t, userID, orgID)` inside the existing transaction

## 2. Fix denyAdminRequest

- [ ] 2.1 In `OrgRepo.denyAdminRequest`, replace the bare `.delete()` call with a `_db.runTransaction` that calls `t.delete(_adminRequestRef(orgID, userID))` and `_userRepo.removeOrg(t, userID, orgID)`

## 3. Update tests

- [ ] 3.1 In `removeAdmin deletes admin` test: stub `mockUserRepo.removeOrg` and add `verify(() => mockUserRepo.removeOrg(any(), userId, orgId)).called(1)`
- [ ] 3.2 In `denyAdminRequest deletes request` test: stub `mockUserRepo.removeOrg` and add `verify(() => mockUserRepo.removeOrg(any(), userId, orgId)).called(1)`

## 4. Verify

- [ ] 4.1 Run `(cd packages/roombooker_core && flutter test)` — all tests pass
- [ ] 4.2 Run `flutter analyze` — no issues
