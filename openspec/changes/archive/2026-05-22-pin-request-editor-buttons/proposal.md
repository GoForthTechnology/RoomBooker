# Proposal: Pin Request Editor Buttons

## Context
When creating a room booking using the `RequestEditor` widget on smaller screens, the "Submit" (or "Save") action buttons appear at the bottom of a scrollable view.

## Problem
Because the action buttons are inside the `SingleChildScrollView` alongside the form fields, they are pushed below the fold on smaller screens. Users may not realize they need to scroll down to find the submit buttons, leading to a confusing user experience.

## Goal
Improve the UX by ensuring the primary action buttons in the `RequestEditor` are always visible (pinned to the bottom) regardless of the scroll position or screen size.

## Scope
- Restructure the layout of `RequestEditor` to separate the scrollable form from the pinned action buttons.
- Update parent widgets (like the side panel in `ViewBookingsScreen`) to remove any redundant outer scroll views that would break the pinned layout constraint.
