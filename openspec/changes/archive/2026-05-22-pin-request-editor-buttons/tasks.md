# Tasks: Pin Request Editor Buttons

- [x] Modify `RequestEditor` to return a `Column` containing a pinned title, an `Expanded` form area, and a pinned button row.
- [x] Remove `_getButtons()` from the `formContents` list in `RequestEditor` and place it at the bottom of the new `Column`.
- [x] Remove the outer `SingleChildScrollView` wrapping `RequestEditor` in `ViewBookingsScreen` to avoid infinite height constraint exceptions.
- [x] Test the `RequestEditor` dialog on small screen resolutions to verify the form scrolls independently of the pinned action buttons.
- [x] Ensure `flutter test` completes successfully with no widget test failures resulting from the layout change.
