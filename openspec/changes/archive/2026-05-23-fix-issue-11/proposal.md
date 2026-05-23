## Why

When users attempt to dismiss the request editor via a system back navigation or swipe gesture (common on iOS/Android), the app exhibits confusing behavior by failing to close the editor and eventually closing the entire application. This change is needed to provide standard platform-expected navigation behavior and prevent accidental app closures.

## What Changes

- Intercept the system back/pop navigation gesture when the request editor is open.
- Handle the swipe back gesture by properly closing the editor instead of allowing the system to pop the underlying route.

## Capabilities

### New Capabilities

### Modified Capabilities
- `ui-ux`: Update the UX requirements to specify that system back gestures must close the active request editor panel if it is open, rather than popping the underlying calendar route.

## Impact

- Request editor UI components (e.g., `PopScope` integration)
- App navigation routing handling
