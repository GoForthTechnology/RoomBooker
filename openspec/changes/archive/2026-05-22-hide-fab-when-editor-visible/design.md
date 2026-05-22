## Context

The Floating Action Button (FAB) on the `ViewBookingsScreen` is currently used to add new bookings when the calendar view is not the day view. When a user opens the request editor panel (to view or edit an existing booking), the FAB remains visible. This can be distracting and leads to a cluttered user interface, as the user is already engaged in an active workflow within the editor panel.

## Goals / Non-Goals

**Goals:**
- Hide the FAB on the calendar screen whenever the request editor panel is visible.
- Ensure the FAB reappears smoothly when the editor panel is closed.

**Non-Goals:**
- Changing the functionality of the FAB itself (adding bookings).
- Changing how or when the editor panel is displayed.
- Modifying the FAB behavior in views where it is already intentionally hidden (e.g., Day view).

## Decisions

**1. Conditionally render the FAB based on `viewState.showEditor`**
- *Rationale*: `viewState.showEditor` is already the source of truth for determining if the editor panel is currently visible on the `ViewBookingsScreen`. By including `!showEditor` in the condition for rendering the `FloatingActionButton`, we ensure that the FAB is hidden precisely when the panel is open.
- *Alternatives considered*: Managing a separate state variable for the FAB's visibility. This was rejected because it introduces unnecessary state synchronization logic when `viewState.showEditor` already accurately represents the condition we care about.

## Risks / Trade-offs

- **[Risk]** The FAB might unexpectedly disappear if `viewState.showEditor` is toggled inadvertently.
  → *Mitigation*: The `showEditor` state is well-tested and controlled tightly by the `ViewBookingsViewModel`. The change is strictly visual and does not affect the underlying data or core booking logic.
