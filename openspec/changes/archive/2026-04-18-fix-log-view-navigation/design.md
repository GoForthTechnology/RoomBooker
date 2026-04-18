## Context

The request log "View" functionality currently only performs a basic navigation to the calendar screen with a date parameter. This leaves the user with several manual steps: scrolling to the correct time, finding the event, and clicking it to see details. Furthermore, the UI lacks a back button on large screens when deep-linked, and navigation might not correctly return to the settings screen.

## Goals / Non-Goals

**Goals:**
- Automatically center the calendar on the event's start time when navigating from a log.
- Automatically open the booking editor/info panel (as a sidebar on large screens or a dialog on small screens).
- Ensure the back button correctly returns the user to the previous screen (e.g., Settings).

**Non-Goals:**
- Modifying how logs are fetched or stored.
- Changing the layout of the calendar or editor itself.

## Decisions

### 1. Enhanced Navigation Parameters
Modify `ViewBookingsRoute` to include the `requestID`. When `requestID` is present, the `ViewBookingsViewModel` will prioritize loading and focusing on this specific request.

### 2. Auto-Focus and Open Panel
- **Logic**: In `ViewBookingsViewModel`, when an `existingRequestID` is provided, fetch the request and:
  1. Initialize the `RequestEditorViewModel` with the request details (already done).
  2. Call `calendarViewModel.scrollToTime(request.eventStartTime)`.
  3. If on a small screen, call `showEditorAsDialog()`.
- **Rationale**: This provides an "all-in-one" transition where the user immediately sees the context they asked for.

### 3. Vertical Centering in Calendar
- **Implementation**: Add a `scrollToTime(DateTime time)` method to `CalendarViewModel` that interacts with the `SfCalendar` controller.
- **Rationale**: While `displayDate` handles the day, `scrollToTime` is necessary for the vertical scroll position in Day and Week views.

### 4. Dynamic Leading Widget in AppBar
- **Logic**: In `ViewBookingsScreen`, the `leading` widget will be determined by:
  - If `router.canPop()`, show a `BackButton`.
  - Else if NOT `isSmallView()`, show the `IconButton` for the menu (room selector).
  - Else, return `null` (letting the Scaffold handle the default drawer menu icon).
- **Rationale**: This ensures that a back path is always available if the screen was pushed, while preserving the room selector toggle on large screens when it's the root view.

## Risks / Trade-offs

- [Risk] Racing between calendar build and `scrollToTime` call. → [Mitigation] Use `WidgetsBinding.instance.addPostFrameCallback` or wait for the calendar to be initialized.
- [Risk] Multiple back buttons if nested incorrectly. → [Mitigation] Rely on `AutoRouter.canPop()` which tracks the stack accurately.
