## 1. Data model: `bookedVia` field

- [x] 1.1 In `packages/roombooker_core/lib/data/entities/request.dart`, add
      `enum BookingSource { kiosk }` and an optional `final BookingSource?
      bookedVia` field on `Request` (constructor, `copyWith`, JSON
      annotations).
- [x] 1.2 Run `dart run build_runner build --delete-conflicting-outputs`
      from the workspace root to regenerate `request.g.dart`.
- [x] 1.3 Add/update a `roombooker_core` test verifying a `Request` without
      `bookedVia` deserializes with `bookedVia == null`, and a `Request`
      with `bookedVia: BookingSource.kiosk` round-trips through
      `toJson`/`fromJson`.

## 2. Gap computation and Quick Book panel

- [x] 2.1 Create `packages/roombooker_kiosk/lib/quick_book_panel.dart`
      with a stateless `QuickBookPanel` widget taking `List<Request>
      bookings`, `DateTime now`, and `void Function(Duration) onBook`.
- [x] 2.2 Implement gap computation: find the first booking with
      `eventStartTime.isAfter(now)` (or none), and enable each of
      15m/30m/60m only if `now.add(duration)` does not exceed that
      booking's `eventStartTime` (or is unbounded if none).
- [x] 2.3 Render three buttons (15m/30m/60m) styled consistently with the
      existing dashboard (large, high-contrast), disabling buttons whose
      duration doesn't fit the gap.

## 3. Wire Quick Book into the Kiosk Dashboard

- [x] 3.1 In `_KioskDashboardState.build` (`main.dart`), render
      `QuickBookPanel` only when `status == RoomStatus.available`, passing
      `bookings` and `now`.
- [x] 3.2 Implement the `onBook(Duration)` callback: build a `Request`
      (`eventStartTime: now`, `eventEndTime: now.add(duration)`, `roomID`,
      `roomName`, `publicName: "In-Room Booking"`, `status:
      RequestStatus.confirmed`, `bookedVia: BookingSource.kiosk`) and a
      `PrivateRequestDetails` (`name: "In-Room Hub"`, empty
      `email`/`phone`/`message`, `eventName: "In-Room Booking"`, no
      `meetingUrl`), then call
      `_bookingService.addBooking(orgID, request, privateDetails)`.
- [x] 3.3 Surface errors from `addBooking` (e.g. a `SnackBar`), consistent
      with other error handling in `_KioskDashboardState`.

## 4. Portal: display Kiosk attribution

- [x] 4.1 In the Portal's request log/agenda rendering
      (`packages/roombooker_portal/lib/ui/`), where the actor's
      email/name is normally shown, check
      `request.bookedVia == BookingSource.kiosk` and display "Booked via
      Kiosk" instead of the (null) admin email.
- [x] 4.2 Add/update a `roombooker_portal` widget test covering the
      "Booked via Kiosk" label for a request with `bookedVia ==
      BookingSource.kiosk`, and the normal admin-email display when
      `bookedVia == null`.

## 5. Kiosk tests

- [x] 5.1 Add `packages/roombooker_kiosk/test/quick_book_panel_test.dart`
      covering: buttons hidden/shown based on room status (via the
      dashboard integration in 3.1, or directly on `QuickBookPanel`), gap
      computation enabling/disabling 15m/30m/60m against a stubbed next
      booking, and the `onBook` callback firing with the tapped duration.

## 6. Firestore rules (added after manual testing)

- [x] 6.1 Update `firestore.rules` so an authorized Kiosk can `create`
      `request-logs` entries for bookings in its own room (the
      `addBooking` `_log` write was rejected by the `isAdmin()`-only
      rule, surfacing as a "Failed to book room" error).
- [x] 6.2 Add `functions/test/firestore.rules.test.js` coverage for the
      new `request-logs` create rule (allowed for own-room kiosk, denied
      for other-room kiosk, denied for ungranted clients, reads remain
      admin-only).

## 7. Validation

- [x] 7.1 Run `(cd packages/roombooker_core && flutter test)` and confirm
      all tests pass.
- [x] 7.2 Run `(cd packages/roombooker_kiosk && flutter test)` and confirm
      all tests pass.
- [x] 7.3 Run `(cd packages/roombooker_portal && flutter test)` and
      confirm all tests pass.
- [x] 7.4 Run `flutter analyze` from the repo root and confirm no new
      issues.
- [x] 7.5 Run `openspec validate kiosk-instant-booking --strict` and
      confirm the change's spec deltas are valid.
