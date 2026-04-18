## 1. Research & Verification

- [x] 1.1 Analyze `BookingCalendarViewModel` for all usages of `CalendarController` properties with null assertion operator (`!`).

## 2. Implementation

- [x] 2.1 Refactor `_safeDisplayDate` to handle null `controller.displayDate` and return a default value.
- [x] 2.2 Update `_viewStateStream` to safely handle potentially null `controller.view`.
- [x] 2.3 Update `minDate` getter to safely handle potentially null `controller.view`.
- [x] 2.4 Verify all other usages of `controller` in the view model are null-safe.

## 3. Validation

- [x] 3.1 Run `flutter analyze` to ensure no new static analysis issues.
- [x] 3.2 Run existing tests to ensure no regressions.
