## Why

Resizing the window triggers many UI rebuilds. `ViewBookingsScreen` was using `ChangeNotifierProvider.value` to create its view models directly inside the `build` method. This caused it to instantiate brand new ViewModels on every single frame during a resize.

Each new `ViewBookingsViewModel` concurrently tried to load the request from the database and initialize the `RequestEditorViewModel`, leading to the `Current data subscription already initialized!` exception and a massive memory leak.

## What Changes

- **Stabilize ViewModels**: Replaced `ChangeNotifierProvider.value` with `ChangeNotifierProvider(create: ...)` in `ViewBookingsScreen`.
- **Robust Initialization**: Updated `RequestEditorViewModel` to gracefully cancel any existing subscription before starting a new one, rather than throwing an exception.
- **Resource Cleanup**: Added a `dispose` method to `ViewBookingsViewModel` to ensure stream subscriptions are cancelled and subjects are closed when the ViewModel is no longer needed.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- None

## Impact
- `lib/ui/screens/view_bookings/view_bookings_screen.dart`
- `lib/ui/screens/view_bookings/view_bookings_view_model.dart`
- `lib/ui/widgets/request_editor/request_editor_view_model.dart`
