## Context

When the Request Editor is open in the `ViewBookingsScreen`, users on mobile platforms (like iOS) often attempt to dismiss it by swiping back or pressing the system back button. Currently, the screen does not intercept this system gesture. As a result, the system back gesture pops the entire `ViewBookingsScreen` off the navigation stack (or closes the app if it's the root route) instead of simply closing the editor panel.

## Goals / Non-Goals

**Goals:**
- Intercept system back gestures (like iOS swipe back and Android back button) when the inline Request Editor panel is visible.
- Close the Request Editor panel when a back gesture is detected, rather than popping the screen route.
- Preserve normal back navigation behavior when the Request Editor is closed.

**Non-Goals:**
- Change the visual appearance of the Request Editor panel.
- Implement custom gesture detectors outside of standard system back handling.

## Decisions

- **Use `PopScope` to intercept back gestures**: `PopScope` is the standard Flutter widget for intercepting back navigation. By wrapping the `Scaffold` in `ViewBookingsScreen` with a `PopScope`, we can dynamically control the back behavior based on `viewState.showEditor`.
  - **Rationale**: `PopScope` integrates seamlessly with `auto_route` and the system's back dispatcher. When `viewState.showEditor` is true, we set `canPop: false` and use `onPopInvoked` to trigger closing the editor.
  - **Alternative**: Using a custom `GestureDetector` to detect horizontal swipes. This is rejected because it doesn't integrate with Android hardware back buttons or the standard system gesture recognizer, leading to inconsistent behavior.

## Risks / Trade-offs

- **[Risk] Normal back navigation is broken** → **Mitigation**: Ensure `canPop` dynamically evaluates to `!viewState.showEditor`. When the editor is closed, `canPop` becomes true and normal navigation is restored.
- **[Risk] Conflicting with full-screen dialogs** → **Mitigation**: When the editor is displayed as a full-screen dialog (on very small screens), the dialog pushes a new route which handles its own back navigation properly. `PopScope` on the main screen only needs to intercept when the editor is shown as a side panel, though closing the view state editor flag is still safe.
