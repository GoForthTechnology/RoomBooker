## 1. UI Navigation Handling

- [x] 1.1 Wrap the `Scaffold` in `ViewBookingsScreen` with a `PopScope` widget.
- [x] 1.2 Configure `canPop` to evaluate to `!viewState.showEditor`.
- [x] 1.3 Add an `onPopInvoked` callback to the `PopScope` that calls `viewModel.closeEditor()` if the editor was open, effectively closing the editor without popping the screen.

## 2. Verification

- [x] 2.1 Test that swiping back (or pressing the back button) when the editor is open closes the editor without popping the `ViewBookingsScreen`.
- [x] 2.2 Test that swiping back when the editor is closed correctly performs the default navigation (popping the route).
