# Spec: Calendar Swipe Optimization

## Background
The `SfCalendar` from Syncfusion is a powerful but heavy widget. In its current implementation within `RoomBooker`, it is driven by a stream that emits a completely new `CalendarViewState` object whenever data or visible windows change. This causes the widget to discard its internal state and rebuild from scratch, which is particularly noticeable as jank during day-view swipes.

## Requirements
1. **Fluidity**: Transitions between calendar days must be smooth (targeting <16ms per frame).
2. **Persistence**: Data for neighboring days should be pre-fetched so that swiping is immediate.
3. **Efficiency**: Use `CalendarDataSource`'s internal update notifications to refresh appointments without widget reconstruction.

## Implementation Details

### `CalendarViewModel` Changes
- Add `final _DataSource _dataSource = _DataSource([]);`
- Update `_viewStateStream` to call `_dataSource.updateAppointments(out)` instead of `dataSource: _DataSource(out)`.
- Use `ViewChangedDetails` to update `_visibleWindowController` immediately.

### `BookingCalendarView` Changes
- Map `onViewChanged` to `viewModel.handleViewChanged`.
- Ensure the `SfCalendar` is only rebuilt when high-level configuration changes (like `currentView`), not on every appointment update.
