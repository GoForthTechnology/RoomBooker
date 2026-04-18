# Fix Resize Crash

## Objective
Resolve the `Current data subscription already initialized!` exception that occurs when resizing the `ViewBookingsScreen`. This exception is caused by the `ViewBookingsViewModel`, `CalendarViewModel`, and `RequestEditorViewModel` being recreated on every UI frame during a window resize.

## Key Files & Context
- `lib/ui/screens/view_bookings/view_bookings_screen.dart`: The screen providing the view models via `ChangeNotifierProvider.value`.
- `lib/ui/widgets/request_editor/request_editor_view_model.dart`: The view model throwing the exception upon duplicate initialization attempts.

## Implementation Steps
1. **Fix Provider Lifecycle (`ViewBookingsScreen`)**:
   - Locate the `ChangeNotifierProvider.value` constructors in `_content` or `build` that instantiate `createCalendarViewModel` (or `_createCalendarViewModel`), `createRequestEditorViewModel` (or `_createRequestEditorViewModel`), and `createViewModel` (or `_createViewModel`).
   - Replace them with `ChangeNotifierProvider(create: (context) => ...)` to ensure the view models are created only once per widget lifecycle and their instances remain stable across rebuilds.
2. **Add Resilience (`RequestEditorViewModel`)**:
   - Locate the `_initializeCurrentDataSubscription` method.
   - Remove the `throw Exception("Current data subscription already initialized!");` check.
   - Replace it with a call to `_cancelCurrentDataSubscription();` to safely clean up any existing subscription before creating a new one.

## Verification & Testing
- Navigate to the "View Bookings" screen by clicking "View" on an existing request log entry.
- Resize the browser window or emulator rapidly from a small width to a large width.
- Verify that the app does not crash or throw the `Current data subscription already initialized!` exception.
- Verify that the network console or backend logs do not show redundant request fetches during the resize event.