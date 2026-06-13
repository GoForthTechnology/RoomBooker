## 1. LogRepo error propagation

- [ ] 1.1 In `log_repo.dart`, `await` (and stop swallowing) the
      `request-logs` `.add()` call in `addLogEntry` so a Firestore write
      failure completes `addLogEntry`'s `Future` with an error.
- [ ] 1.2 Add/update a `log_repo_test.dart` (or extend
      `booking_repo_test.dart`) case covering "Mutation succeeds but logging
      fails": stub `LogRepo.addLogEntry` (or the underlying Firestore write)
      to fail and assert the `BookingRepo` mutation rethrows.

## 2. UserRepo.addOrg transactional fix

- [ ] 2.1 In `user_repo.dart`, rewrite `addOrg(Transaction t, userID, orgID)`
      to read the profile via `t.get` and write via `t.set`/`t.update`
      instead of non-transactional `profileRef.get()`/`profileRef.set()`.
- [ ] 2.2 In `org_repo.dart`, update `addOrgForCurrentUser` to perform all
      transaction reads (including `addOrg`'s profile read) before any
      writes, replace `_db.collection("orgs").add(...)` with `t.set` on a
      pre-allocated `doc()` reference, and `await _userRepo.addOrg(t, ...)`.
- [ ] 2.3 In `org_repo.dart`, update `addAdminRequestForCurrentUser` the same
      way: read-before-write ordering and `await _userRepo.addOrg(t, ...)`.
- [ ] 2.4 Update `user_repo_test.dart` and `org_repo_test.dart` to cover the
      transactional `addOrg` behavior (profile created/updated atomically
      with the org/admin-request document) using `fake_cloud_firestore`.

## 3. OrgRepo.removeOrg transactional delete

- [ ] 3.1 In `org_repo.dart`, change `removeOrg` to delete the org document
      via `t.delete(orgRef)` instead of `await orgRef.delete()`.
- [ ] 3.2 Update `org_repo_test.dart` to confirm `removeOrg` deletes the org
      doc and updates `users/{uid}.orgIDs` atomically.

## 4. BookingRepo null edit-choice no-ops

- [ ] 4.1 In `booking_repo.dart`, change `deleteBooking`'s `case null:` to
      return without throwing `UnimplementedError` and without writing a
      `DeleteBooking` audit log entry (restructure the `try`/`finally` so
      `_log` is skipped for this case).
- [ ] 4.2 In `booking_repo.dart`, make `_updateConfirmedBooking` signal
      "no changes made" when `choice == null` (e.g. return a `bool`), and
      have `updateBooking` skip the `privateDetailsRef` write and the
      post-transaction `_log` call when no changes were made.
- [ ] 4.3 Update `booking_repo_test.dart` to cover both no-op scenarios:
      `updateBooking`/`deleteBooking` called on a recurring request with the
      `RecurringBookingEditChoiceProvider` resolving to `null` results in no
      Firestore writes and no audit log entries.

## 5. Validation

- [ ] 5.1 Run `(cd packages/roombooker_core && flutter test)` and confirm all
      tests pass.
- [ ] 5.2 Run `flutter analyze` from the repo root and confirm no new issues.
- [ ] 5.3 Run `openspec validate fix-data-repo-layer-bugs --strict` and
      confirm the change's spec delta is valid.
