## Why

`packages/roombooker_core/lib/data/services/booking_service.dart` is the
single domain-logic facade that all UI code (Portal, Kiosk) MUST go through
for booking operations (per `CLAUDE.md`'s "Booking logic must go through
`BookingService`" convention), yet it has no corresponding spec. The
`data-repo-layer` spec documents `BookingRepo`'s storage contracts, and
`instance-rescheduling`/`data-model` cover recurrence and entity shapes, but
none of them describe `BookingService`'s own value-add: request-stream
expansion/enrichment for admins, overlap detection, request validation, and
blackout-window derivation. This makes it easy for future changes to
duplicate this logic in the UI layer or silently change its behavior with no
spec to check against. This is a documentation-only change (no behavior
changes) to backfill that gap.

## What Changes

- Add a new `booking-service` capability spec documenting the contracts of
  `BookingService`:
  - **Request Stream Expansion and Enrichment**: `getRequestsStream` expands
    recurring requests into per-window instances and, for admins, enriches
    each instance with its private event name (suffixed " (Private)" when
    no public name is set) by joining against `getRequestDetails`.
  - **Request Validation**: `validateRequest`/`submitBookingRequest`/
    `updateBooking`/`addBooking` reject requests whose `eventEndTime` is
    before `eventStartTime`.
  - **Overlap Detection**: `findOverlappingBookings` derives overlapping
    confirmed-request pairs (excluding requests with `ignoreOverlaps`) per
    room from the expanded request stream.
  - **Blackout Window Derivation**: `listBlackoutWindows` combines a fixed
    set of default daily blackout windows ("Too Early"/"Too Late") with
    confirmed requests on the org's global room, converted to
    `BlackoutWindow`s.
  - **Pass-Through Write/Read Delegation**: `BookingService` is documented as
    a thin, validating pass-through to `BookingRepo` for
    submit/update/add/end/confirm/deny/revisit/delete booking operations,
    `decorateLogs`, and read streams (`listRequests`, `getRequestDetails`,
    `getRequest`).
- No modifications to existing specs and no code changes — this is a spec
  backfill describing current, already-implemented behavior.

## Capabilities

### New Capabilities
- `booking-service`: Contracts for `BookingService`, the domain-logic facade
  in `roombooker_core/lib/data/services/booking_service.dart` that UI code
  uses for all booking operations (request streaming/enrichment, validation,
  overlap detection, blackout windows, and pass-through writes/reads to
  `BookingRepo`).

### Modified Capabilities
(none)

## Impact

- **Affected code**: None (documentation only). Reference file:
  `packages/roombooker_core/lib/data/services/booking_service.dart`.
- **Affected specs**: Adds `openspec/specs/booking-service/spec.md`.
- **Dependencies**: Builds on `data-repo-layer` (BookingRepo contracts),
  `data-model` (entity shapes), and `instance-rescheduling` (recurrence
  expansion).
