## Context

Users rescheduling an event currently experience a conflict where calendar taps trigger new booking flows instead of updating the active edit. The system needs to distinguish between "Browsing/Creating" mode and "Rescheduling" mode.

## Goals / Non-Goals

**Goals:**
- Enable "Tap to Move" behavior in Day and Week views when an event is being rescheduled.
- Preserve the duration of the event during the move.
- Prevent accidental moves in Month view by disabling cell taps during rescheduling.

**Non-Goals:**
- Implementing Drag-and-Drop (which is a separate complex interaction).
- Modifying the month view navigation logic.

## Decisions

### Decision 1: `RequestEditorViewModel` as the State Authority
- **Rationale**: The `RequestEditorViewModel` already knows if it has an `initialRequest` (existing event) and if `editingEnabled` is true. It is the natural place to define `isRescheduling`.
- **Implementation**: Expose a `bool get isRescheduling` property.

### Decision 2: Duration-Preserving Move Logic
- **Rationale**: When rescheduling, the user typically wants the same event duration at a different time. 
- **Implementation**: Add `moveEventTo(DateTime newStart)` to `RequestEditorViewModel`. It will calculate the current duration and update both start and end times relative to the new start point.

### Decision 3: View-Aware Tap Handling in `ViewBookingsViewModel`
- **Rationale**: The Month view provides `00:00` as the tapped time, which would wipe out the event's specific start hour/minute. 
- **Implementation**: Check `details.view` in `_onTapDate`. If `CalendarView.month` and `isRescheduling`, ignore the tap.

## Risks / Trade-offs

- **[Risk]** Accidental moves in Day/Week view → If a user taps the calendar to "look around" while editing, the event will jump.
- **[Mitigation]** The user can always click "Cancel" or "Close" without saving to revert. The benefit of fast rescheduling outweighs the risk of accidental moves.
