# Design: Pin Request Editor Buttons

## Architecture
The UI restructure will change how `RequestEditor` distributes available height. Instead of letting its content define its height (which happens when it returns a `SingleChildScrollView`), it will use bounded height constraints to pin the footer.

### `RequestEditor` Layout Refactor
Currently, `RequestEditor` returns:
```dart
return SingleChildScrollView(
  child: Padding(
    padding: const EdgeInsets.all(4),
    child: Form(key: viewModel.formKey, child: formContents), // formContents includes _getButtons()
  ),
);
```

**New Structure**:
```dart
return Column(
  children: [
    _title(viewModel, context),
    Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Form(key: viewModel.formKey, child: formFieldsOnly),
        ),
      ),
    ),
    SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _getButtons(state, context),
      ),
    ),
  ],
);
```

### `ViewBookingsScreen` Side Panel Adjustments
In `lib/ui/screens/view_bookings/view_bookings_screen.dart`, the side panel currently wraps `RequestEditor` in a `SingleChildScrollView`:
```dart
child: SingleChildScrollView(child: RequestEditor()),
```
Since `SingleChildScrollView` provides unbounded vertical space, using `Expanded` inside `RequestEditor` will throw a layout exception. We must remove this outer `SingleChildScrollView`. 

**New Structure**:
```dart
child: RequestEditor(),
```
The existing `OverflowBox` passing bounded dimensions from the screen height will ensure the `Column` inside `RequestEditor` correctly expands and pins the bottom buttons.

## Alternatives Considered
1. **AppBar Actions**: Placing "Save" or "Submit" in the `AppBar` actions list. This is problematic because `RequestEditorViewModel` can return multiple actions (e.g., "Approve" and "Reject"), which are better suited for a button row.
2. **Floating Action Button**: Adding a FAB inside the `RequestEditor`. This could work, but a standard pinned button row provides a more predictable and platform-agnostic experience for form submission, especially given the multiple possible actions.
