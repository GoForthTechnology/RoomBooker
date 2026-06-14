## Context

`packages/roombooker_core/lib/data/services/booking_service.dart` (350
lines) wraps a single `BookingRepo` and is the only class UI code (Portal,
Kiosk) is permitted to call for booking operations. This change documents
its *current* behavior as a spec; it does not change any code. The spec is
derived by reading the existing implementation
(`booking_service.dart`, plus the `Request`, `PrivateRequestDetails`, and
`BlackoutWindow` entities it operates on).

## Goals / Non-Goals

**Goals:**
- Document `getRequestsStream`'s expand-then-enrich pipeline: recurring
  `Request`s are expanded into per-occurrence instances via `Request.expand`
  for the requested window, and, only for admins, each instance's
  `publicName` is overwritten with `"<eventName> (Private)"` from
  `PrivateRequestDetails` when no public name was set.
- Document `validateRequest`'s single rule (end time must not be before
  start time) and that it is applied by every write path
  (`submitBookingRequest`, `updateBooking`, `addBooking`).
- Document `findOverlappingBookings`'s contract: it re-uses
  `getRequestsStream` (as admin, confirmed-only), skips requests with
  `ignoreOverlaps == true`, groups by `roomID`, and returns `OverlapPair`s
  for any two requests in the same room whose `[eventStartTime,
  eventEndTime)` intervals intersect.
- Document `listBlackoutWindows`'s contract: confirmed requests on the org's
  `globalRoomID` (if set) within the window are converted to
  `BlackoutWindow`s via `BlackoutWindow.fromRequest` and combined with two
  fixed default daily windows ("Too Early" 00:00-05:59, "Too Late"
  22:00-23:59, both `FREQ=DAILY`).
- Document the pass-through methods (`submitBookingRequest`, `updateBooking`,
  `addBooking`, `endBooking`, `ignoreOverlaps`, `confirmRequest`,
  `denyRequest`, `revisitBookingRequest`, `deleteBooking`, `decorateLogs`,
  `listRequests`, `getRequestDetails`, `getRequest`) as a thin delegation
  layer to `BookingRepo`, so the spec makes explicit that `BookingService`
  adds no additional side effects beyond validation for these calls.

**Non-Goals:**
- No new requirements or behavior changes — this is a backfill of the
  as-built system.
- Not re-documenting `BookingRepo`'s storage/transaction contracts (already
  covered by `data-repo-layer`) or `Request.expand`'s recurrence semantics
  (already covered by `instance-rescheduling`/`data-model`) — this spec
  references them rather than restating them.
- Not documenting `OverlapPair`'s equality/`toString()` implementation
  details beyond what's needed to describe the overlap-detection contract.

## Decisions

- **One capability spec, four requirement groups** (request streaming and
  enrichment; validation; overlap detection; blackout windows) plus one
  "pass-through" requirement group, mirroring the `data-repo-layer` spec's
  approach of one spec per cohesive concern rather than one spec per public
  method.
- **Describe the admin-enrichment rule precisely** (including the
  `"<eventName> (Private)"` suffix format) since it's the most
  behaviorally non-obvious part of `getRequestsStream` and the part most
  likely to be silently changed or duplicated in UI code.
- **Treat pass-through methods as a single requirement** stating they
  delegate to the corresponding `BookingRepo` method (with validation where
  applicable), rather than one requirement per method — these are
  intentionally thin and the value of the spec is in flagging that they are
  thin (so future logic should go in `BookingService`, not the UI).

## Risks / Trade-offs

- [Spec drift if `BookingService` changes without updating the spec] → The
  spec text references concrete method names and the enrichment string
  format so future diffs touching them are an obvious trigger to update the
  spec; this is normal spec-maintenance, not enforced by tooling.
- [The "Internal overlap checks should probably see everything?" comment in
  `findOverlappingBookings` suggests the `isAdmin: true` choice may be
  provisional] → Document the current (`isAdmin: true`, i.e. enrichment-
  enabled) behavior as the contract; if this is later found to be a bug, a
  follow-up change should update both the code and this spec together.

## Migration Plan

N/A — documentation only, no code or data changes.
