## Why

Currently, when a user is in the process of rescheduling an existing event, tapping an empty slot on the calendar starts a new booking flow instead of moving the active event. This is unintuitive and breaks the expected "teleportation" interaction for rescheduling.

## What Changes

- Update `ViewBookingsViewModel` to branch calendar tap logic based on the current editor state.
- Update `RequestEditorViewModel` to support "teleporting" an active edit session to a new date while preserving its duration.
- Disable calendar cell interaction for month view while rescheduling to prevent accidental midnight-hour shifts.

## Capabilities

### New Capabilities
- `tap-to-reschedule`: Enables moving an active booking by tapping the desired destination on the calendar (supported in day/week views).

### Modified Capabilities
- `ui-ux`: Update calendar interaction requirements to account for the rescheduling state.

## Impact

- `ViewBookingsViewModel`: Logic change in `_onTapDate`.
- `RequestEditorViewModel`: New properties and methods to support rescheduling state and movement.
- `CalendarViewModel`: No direct changes expected, but depends on its reported view type.
