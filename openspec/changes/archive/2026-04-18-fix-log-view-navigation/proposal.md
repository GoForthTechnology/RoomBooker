## Why

The current implementation of the request log's "View" functionality provides a disjointed user experience. When a user clicks "View" on a log entry, they are taken to the calendar but the relevant event is not centered, and the details panel remains closed, forcing the user to hunt for the event manually. Additionally, a navigation bug prevents users from returning to the settings screen when hitting back, breaking the expected navigation flow.

## What Changes

- **Modify** log view navigation to center the target booking on the calendar.
- **Modify** log view navigation to automatically open the booking info/editor panel upon arrival.
- **Fix** the navigation stack behavior to ensure that hitting "back" from the calendar (when navigated from settings) returns the user to the settings screen instead of exiting or getting lost.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `ui-ux`: Clarify navigation and interaction requirements for deep-linking from logs to the calendar view, specifically around centering and panel states.

## Impact

- `lib/ui/screens/settings_screen.dart` (or wherever the log widget is): Update navigation logic.
- `lib/ui/screens/calendar_view_screen.dart`: Update to handle centering and auto-opening the panel based on navigation parameters.
- `lib/router.dart`: Ensure route configuration supports the desired back-stack behavior.
