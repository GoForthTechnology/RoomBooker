## 1. Calendar View Model Updates

- [x] 1.1 Add `activeRequestID` field to `CalendarViewState` in `lib/ui/widgets/booking_calendar/view_model.dart`.
- [x] 1.2 Update the `_viewStateStream` mapping logic to populate `activeRequestID` from the `newAppointment` subject.

## 2. UI Implementation

- [x] 2.1 Modify `_appointmentBuilder` in `lib/ui/widgets/booking_calendar/booking_calendar.dart` to accept the `activeRequestID` from `CalendarViewState`.
- [x] 2.2 Implement conditional border rendering in the `BoxDecoration` of the appointment container.
- [x] 2.3 Update border color to black to ensure visibility against the white calendar background.
- [x] 2.4 Add drop shadow effect to the active appointment's `BoxDecoration`.

## 3. Verification

- [x] 3.1 Verify that the active booking shows both a black border and a drop shadow.
- [x] 3.2 Verify that the indicator disappears when the editor is closed.
- [x] 3.3 Verify that clicking a different booking updates the indicator location.
