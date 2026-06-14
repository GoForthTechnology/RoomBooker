## 1. Widen the booking query window

- [ ] 1.1 In `packages/roombooker_kiosk/lib/main.dart`, replace the
      `now - 1h` / `now + 4h` `_bookingsStream` query with a full local-day
      window (`[startOfDay(now), startOfDay(now) + 1 day)`), keeping the
      existing `includeRoomIDs`/`includeStatuses: {RequestStatus.confirmed}`
      filters.
- [ ] 1.2 Verify `currentBooking` derivation (start <= now < end) still
      works against the widened result set.

## 2. Agenda list widget

- [ ] 2.1 Create `packages/roombooker_kiosk/lib/agenda_list.dart` with a
      stateless `AgendaListView` widget taking `List<Request> bookings` and
      `DateTime now`, sorting by `eventStartTime` and rendering a
      `ListView` of rows (start-end time + `publicName` or "Private
      Meeting").
- [ ] 2.2 Highlight the row whose booking is currently in progress
      (start <= now < end) with a distinct visual style.
- [ ] 2.3 Render an empty-state message ("No meetings scheduled") when
      `bookings` is empty.
- [ ] 2.4 Apply Tactical Information Density styling (large fonts, high
      contrast) consistent with the existing dashboard's dark theme.

## 3. Wire into the Kiosk Dashboard

- [ ] 3.1 In `_KioskDashboardState.build`, render `AgendaListView` below the
      existing hero status section, passing the day's bookings and `now`.
- [ ] 3.2 Adjust the dashboard layout (e.g. `Expanded`/`SizedBox` sizing) so
      both the hero section and the agenda list are visible/scrollable
      without the hero section crowding out the agenda.

## 4. Tests

- [ ] 4.1 Add `packages/roombooker_kiosk/test/agenda_list_test.dart` covering:
      chronological ordering, current-booking highlighting, "Private
      Meeting" fallback for unnamed bookings, and the empty-state message.
- [ ] 4.2 Update `packages/roombooker_kiosk/test/widget_test.dart` (and/or
      add a new dashboard test) to stub `BookingService.listRequests` with
      a full-day window and assert the agenda list renders the stubbed
      bookings.

## 5. Validation

- [ ] 5.1 Run `(cd packages/roombooker_kiosk && flutter test)` and confirm
      all tests pass.
- [ ] 5.2 Run `flutter analyze` from the repo root and confirm no new
      issues.
- [ ] 5.3 Run `openspec validate kiosk-agenda-view --strict` and confirm the
      change's spec delta is valid.
