## Why

Currently, when the request editor panel is visible on the calendar screen, the Floating Action Button (FAB) for adding new bookings remains visible. This can clutter the UI and potentially confuse users, as they are already in the context of editing or viewing a specific request. Hiding the FAB when the editor is open provides a cleaner and more focused user experience.

## What Changes

- Hide the Floating Action Button (FAB) on the `ViewBookingsScreen` whenever the request editor panel is visible.
- Ensure the FAB reappears when the editor panel is closed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `ui-ux`: Update the requirements for the calendar screen to hide the new booking action when the editor panel is active.

## Impact

- `lib/ui/screens/view_bookings/view_bookings_screen.dart` will be updated to conditionally render the FAB based on the `viewState.showEditor` flag.
