## 1. Entity Changes

- [x] 1.1 Add `meetingUrl` field to `PrivateRequestDetails` in
  `packages/roombooker_core/lib/data/entities/request.dart` (constructor,
  `copyWith`, `toString`/JSON annotations, `==`, `hashCode`).
- [x] 1.2 Run `dart run build_runner build --delete-conflicting-outputs` to
  regenerate `request.g.dart` for both `PrivateRequestDetails` and `Request`.
- [x] 1.3 Update all `PrivateRequestDetails(...)` construction sites
  (production and test code) to pass `meetingUrl` where relevant.

## 2. Portal Request Editor

- [x] 2.1 Update `request_editor_view_model.dart` so
  `meetingUrlController` is populated from and saved to
  `PrivateRequestDetails.meetingUrl` instead of `Request.meetingUrl`.
- [x] 2.2 Update `request_editor_view_model_test.dart` and
  `request_editor_test.dart` for the new data source.

## 3. Kiosk Dashboard

- [x] 3.1 In `packages/roombooker_kiosk/lib/main.dart`, when a
  `currentBooking` is identified, fetch its `PrivateRequestDetails` via
  `BookingService.getRequestDetails(orgID, currentBooking.id)`.
- [x] 3.2 Update the "Join Meeting" button to use
  `PrivateRequestDetails.meetingUrl` instead of
  `currentBooking.meetingUrl`, handling the loading/null states.
- [x] 3.3 Update/add Kiosk widget tests covering the "Join Meeting" button
  with the new data source.

## 4. Remove `meetingUrl` from `Request`

- [x] 4.1 Remove the `meetingUrl` field from `Request` (constructor,
  `copyWith`, `toString`, `==`, `hashCode`, JSON annotations) in
  `request.dart`.
- [x] 4.2 Regenerate `request.g.dart` again after the removal.
- [x] 4.3 Search for and update any remaining `Request(...).meetingUrl`
  references across `roombooker_core`, `roombooker_portal`, and
  `roombooker_kiosk` (production and test code).

## 5. Migration Script

- [x] 5.1 Add `functions/scripts/migrate_meeting_urls.js`: iterate every org's
  `confirmed-requests` collection, and for each document with a non-null
  `meetingUrl`, write that value to
  `private-request-details/{requestID}.meetingUrl` and remove `meetingUrl`
  from the `confirmed-requests` document (use a batched write/transaction
  per document).
- [x] 5.2 Add a short usage note (how to run it, against which project) as a
  comment header in the script.
- [x] 5.3 Run the script against the Firestore emulator
  (`scripts/start_emulators.sh`) with seeded data and verify the
  before/after state.

## 6. Validation

- [x] 6.1 Run `(cd packages/roombooker_core && flutter test)`.
- [x] 6.2 Run `(cd packages/roombooker_portal && flutter test)`.
- [x] 6.3 Run `flutter analyze` from the workspace root.
- [ ] 6.4 Manually verify in the Kiosk: a confirmed booking with a meeting
  link shows the "Join Meeting" button and launches correctly. (Requires
  physical Kiosk hardware; the underlying `JoinMeetingButton` widget is
  covered by automated tests in 3.3.)
