## Context

The system supports recurring bookings through `RecurrancePattern`. It handles exceptions (rescheduling/deleting individual instances) via a `recurranceOverrides` map on the `Request` object. Currently, the key for this map is derived from the *new* event time, which breaks the lookup logic during series expansion.

## Goals / Non-Goals

**Goals:**
- Fix the logic for indexing recurrence overrides to use the original instance date.
- Ensure TDD approach: create a failing test case before implementing the fix.
- Standardize the key extraction logic across `updateBooking` and `deleteBooking`.

**Non-Goals:**
- Refactoring the entire recurrence system (e.g., moving to a specialized library).
- Modifying the UI/UX of the rescheduling flow.

## Decisions

### Decision 1: Use `originalStartTime` as the index key
- **Rationale**: When `Request.expand` iterates through a series, it has access to the current "calculated" date of the instance. It needs a deterministic key to check for overrides. The original date is the only piece of information that remains stable between the rule and the override.
- **Alternatives**: 
    - Using an `originalDate` field in the override request: More complex to manage and redundant if we use the map key correctly.
    - Searching the entire map for matching IDs: Extremely inefficient (O(n) per instance).

### Decision 2: Update `BookingRepo` internal signatures
- **Rationale**: `_updateConfirmedBooking` and `_deleteBooking` (via `RecurringBookingEditChoice.thisInstance`) currently lack the "Original Start Time" of the specific instance being modified. We must pass this information from the `BookingService` or UI layer.
- **Implementation**: Update `updateBooking` and `deleteBooking` parameters to include the `originalStartTime` if they are targeting a specific instance.

## Risks / Trade-offs

- **[Risk]** Data Inconsistency → Existing overrides that used the "wrong" key will become invisible or remain orphaned.
- **[Mitigation]** Since the current system is reported as "broken" for rescheduling, the impact on existing data is likely small. We could consider a migration script, but for a prototype/early stage app, we will focus on forward-fixing.
- **[Risk]** Daylight Savings Time → Moving events across DST boundaries could shift the "day" part of the key.
- **[Mitigation]** Ensure keys are generated using `_stripTime` which sets hours/minutes to 0, and use UTC or local consistently as per the `Request` entity standards.
