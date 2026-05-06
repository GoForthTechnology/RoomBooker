## 1. Research & Verification (TDD)

- [x] 1.1 Create a regression test in `test/data/repos/booking_repo_test.dart` that fails when rescheduling an instance to a different day.
- [x] 1.2 Verify the test failure matches the reported bug (incorrect override key usage).

## 2. Core Implementation (Fix)

- [x] 2.1 Update `BookingRepo.updateBooking` and `BookingService.updateBooking` to accept `originalStartTime` as an optional parameter.
- [x] 2.2 Modify `BookingRepo._updateConfirmedBooking` to use the provided `originalStartTime` for `RecurringBookingEditChoice.thisInstance` overrides.
- [x] 2.3 Update `_overrideRecurrance` helper to use the `originalStartTime` as the map key.
- [x] 2.4 Update `deleteBooking` in `BookingRepo` to use `eventStartTime` instead of `eventEndTime` for consistency and correctness.

## 3. Integration & Validation

- [x] 3.1 Update `RequestEditorViewModel` to pass the correct `originalStartTime` when saving a single instance edit.
- [x] 3.2 Verify that the regression test from 1.1 now passes.
- [x] 3.3 Add a new test case for single-instance deletion to verify the fix in 2.4.
- [x] 3.4 Perform a manual end-to-end check of the rescheduling flow in the UI (if possible in this environment).
