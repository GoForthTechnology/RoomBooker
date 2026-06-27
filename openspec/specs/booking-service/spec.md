# Booking Service Specification: Room Booker

## Purpose
This document specifies the contracts of `BookingService`
(`packages/roombooker_core/lib/data/services/booking_service.dart`), the
domain-logic facade that UI code (Portal, Kiosk) MUST go through for booking
operations: request-stream expansion/enrichment, validation, overlap
detection, blackout-window derivation, and pass-through delegation to
`BookingRepo`.

## [BSVC-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Request Stream Expansion and Enrichment
`BookingService.getRequestsStream` SHALL expand recurring `Request`s
returned by `BookingRepo.listRequests` into per-occurrence instances within
the requested `[start, end)` window via `Request.expand`. When the caller is
an admin, each expanded instance SHALL be enriched by joining against
`BookingRepo.getRequestDetails` for its original request ID: if the
instance's `publicName` is null or empty, it SHALL be replaced with
`"<eventName> (Private)"` from the corresponding `PrivateRequestDetails`.
Non-admin callers SHALL receive the expanded instances without enrichment.

#### Scenario: Recurring request expanded into instances
- **WHEN** `getRequestsStream` is called with a window that spans multiple
  occurrences of a recurring `Request`
- **THEN** the emitted list SHALL contain one expanded instance per
  occurrence that falls within `[start, end)`.

#### Scenario: Admin sees private event name for unnamed public requests
- **WHEN** `getRequestsStream` is called with `isAdmin: true` and an expanded
  instance has no `publicName` (or an empty one) but has corresponding
  `PrivateRequestDetails` with `eventName` set
- **THEN** the instance's `publicName` SHALL be set to
  `"<eventName> (Private)"`.

#### Scenario: Non-admin does not receive private details enrichment
- **WHEN** `getRequestsStream` is called with `isAdmin: false`
- **THEN** the emitted instances SHALL be the expanded requests as returned
  by `BookingRepo`, without querying `getRequestDetails`.

#### Scenario: Empty window produces no emissions to enrich
- **WHEN** `getRequestsStream`'s expansion step produces an empty list of
  instances for the requested window
- **THEN** the stream SHALL emit an empty list without querying
  `getRequestDetails`.

### Requirement: Request Validation
`BookingService.validateRequest` SHALL reject a `Request` whose
`eventEndTime` is before its `eventStartTime` by throwing an `ArgumentError`.
This validation SHALL be applied by `submitBookingRequest`, `updateBooking`
(on `updatedRequest`), and `addBooking` before delegating to `BookingRepo`.

#### Scenario: End time before start time is rejected
- **WHEN** `validateRequest` is called with a `Request` whose `eventEndTime`
  is before its `eventStartTime`
- **THEN** an `ArgumentError` SHALL be thrown.

#### Scenario: Valid request passes validation
- **WHEN** `validateRequest` is called with a `Request` whose `eventEndTime`
  is not before its `eventStartTime`
- **THEN** no error SHALL be thrown.

#### Scenario: Write methods validate before delegating
- **WHEN** `submitBookingRequest`, `updateBooking`, or `addBooking` is called
  with a request that fails `validateRequest`
- **THEN** an `ArgumentError` SHALL be thrown and the corresponding
  `BookingRepo` method SHALL NOT be called.

### Requirement: Overlap Detection
`BookingService.findOverlappingBookings` SHALL derive overlapping pairs of
confirmed `Request`s, using `getRequestsStream` (with `isAdmin: true` and
`includeStatuses: {RequestStatus.confirmed}`) for the requested
`[startTime, endTime)` window. Requests with `ignoreOverlaps == true` SHALL
be excluded. Remaining requests SHALL be grouped by `roomID`, and within each
room, two requests SHALL be considered overlapping (and returned as an
`OverlapPair`) if and only if they share the same `roomID` and their
`[eventStartTime, eventEndTime)` intervals intersect.

#### Scenario: Overlapping confirmed requests in the same room are paired
- **WHEN** `findOverlappingBookings` is called for a window containing two
  confirmed `Request`s in the same room whose `[eventStartTime,
  eventEndTime)` intervals intersect
- **THEN** the emitted list SHALL contain an `OverlapPair` for that pair.

#### Scenario: Non-overlapping requests are not paired
- **WHEN** two confirmed `Request`s in the same room have
  `[eventStartTime, eventEndTime)` intervals that do not intersect (one
  starts at or after the other ends)
- **THEN** the emitted list SHALL NOT contain an `OverlapPair` for that pair.

#### Scenario: Requests in different rooms are never paired
- **WHEN** two confirmed `Request`s have overlapping times but different
  `roomID`s
- **THEN** the emitted list SHALL NOT contain an `OverlapPair` for that pair.

#### Scenario: Requests with ignoreOverlaps are excluded
- **WHEN** a confirmed `Request` has `ignoreOverlaps == true`
- **THEN** it SHALL NOT be included when computing overlaps, even if its
  time range intersects another request's.

### Requirement: Blackout Window Derivation
`BookingService.listBlackoutWindows` SHALL return a list combining (a) every
confirmed `Request` within `[startTime, endTime)` whose `roomID` equals the
organization's `globalRoomID` (if set), converted to a `BlackoutWindow` via
`BlackoutWindow.fromRequest`, and (b) two fixed default daily
`BlackoutWindow`s: `"Too Early"` (00:00-05:59, `FREQ=DAILY`) and
`"Too Late"` (22:00-23:59, `FREQ=DAILY`).

#### Scenario: Confirmed global-room request becomes a blackout window
- **WHEN** `listBlackoutWindows` is called for an org with `globalRoomID`
  set and there is a confirmed `Request` on that room within the window
- **THEN** the result SHALL include a `BlackoutWindow` derived from that
  request via `BlackoutWindow.fromRequest`.

#### Scenario: Requests on non-global rooms are excluded
- **WHEN** a confirmed `Request` within the window has a `roomID` different
  from the org's `globalRoomID`
- **THEN** it SHALL NOT be converted into a `BlackoutWindow`.

#### Scenario: Default daily windows are always included
- **WHEN** `listBlackoutWindows` is called for any org and window
- **THEN** the result SHALL include the `"Too Early"` and `"Too Late"`
  default daily `BlackoutWindow`s regardless of whether any confirmed
  requests exist.

### Requirement: Submit Amendment
`BookingService.submitAmendment` SHALL accept an `orgID`, the confirmed
`Request` being amended, a `BookingAmendment` payload, and delegate to
`BookingRepo.submitAmendment`. The repo SHALL atomically create the
`amendment-details/{requestID}` document and set `hasPendingAmendment: true`
on the confirmed-request document. If `hasPendingAmendment` is already `true`
on the confirmed-request, the operation SHALL throw a `StateError`.

#### Scenario: Successful amendment submission
- **WHEN** `BookingService.submitAmendment` is called for a confirmed booking
  without an existing pending amendment
- **THEN** `BookingRepo.submitAmendment` is called, resulting in an atomic
  batch write that creates `amendment-details/{requestID}` and sets
  `hasPendingAmendment: true` on the confirmed-request document.

#### Scenario: Submission rejected when amendment already pending
- **WHEN** `BookingService.submitAmendment` is called for a confirmed booking
  that already has `hasPendingAmendment: true`
- **THEN** a `StateError` is thrown and no Firestore writes are performed.

### Requirement: Get Amendment
`BookingService.getAmendment` SHALL return a `Stream<BookingAmendment?>` for
a given `orgID` and `requestID`, delegating to `BookingRepo.getAmendment`
which reads from `amendment-details/{requestID}`. The stream SHALL emit
`null` if no amendment document exists.

#### Scenario: Amendment stream emits the current amendment
- **WHEN** `getAmendment` is called for a booking with a pending amendment
- **THEN** the stream emits the `BookingAmendment` stored in
  `amendment-details/{requestID}`.

#### Scenario: Amendment stream emits null when no amendment exists
- **WHEN** `getAmendment` is called for a booking without a pending amendment
- **THEN** the stream emits `null`.

### Requirement: Apply Amendment
`BookingService.applyAmendment` SHALL accept an `orgID`, the current
confirmed `Request`, and the `BookingAmendment` to apply, then delegate to
`BookingRepo.applyAmendment`. The repo SHALL atomically:
- Apply the proposed `Request` fields to the confirmed-request document
  (respecting `AmendmentScope` for recurring bookings using the same
  split/override logic as `updateBooking`).
- Update `request-details/{requestID}` with the proposed `PrivateRequestDetails`.
- Clear `hasPendingAmendment` on the confirmed-request document.
- Delete `amendment-details/{requestID}`.

#### Scenario: Applying a one-off amendment updates the confirmed booking
- **WHEN** `BookingService.applyAmendment` is called for a non-recurring
  confirmed booking
- **THEN** the confirmed-request document is updated with the proposed
  fields, `request-details` is updated, `hasPendingAmendment` is cleared,
  and `amendment-details` is deleted — atomically.

#### Scenario: Applying a this-instance amendment creates a recurrence override
- **WHEN** `BookingService.applyAmendment` is called for a recurring booking
  with `scope == AmendmentScope.thisInstance`
- **THEN** the proposed changes are stored as a `recurranceOverride` on the
  series document for the specific instance date.

#### Scenario: Applying a this-and-future amendment splits the series
- **WHEN** `BookingService.applyAmendment` is called for a recurring booking
  with `scope == AmendmentScope.thisAndFuture`
- **THEN** the original series is ended before the instance date and a new
  confirmed-request document is created from that date with the proposed
  fields, consistent with the existing "this and future" edit logic.

### Requirement: Reject Amendment
`BookingService.rejectAmendment` SHALL accept an `orgID` and `requestID`
and delegate to `BookingRepo.rejectAmendment`. The repo SHALL atomically
clear `hasPendingAmendment` on the confirmed-request document and delete
`amendment-details/{requestID}`. The confirmed booking SHALL remain unchanged.

#### Scenario: Rejecting an amendment clears the flag and deletes the detail doc
- **WHEN** `BookingService.rejectAmendment` is called
- **THEN** `hasPendingAmendment` is cleared on the confirmed-request document
  and `amendment-details/{requestID}` is deleted atomically. The confirmed
  booking's fields and `request-details` are unchanged.

### Requirement: Pass-Through Write and Read Delegation
`BookingService` SHALL delegate the following operations directly to the
corresponding `BookingRepo` method, applying only the validation described
above where applicable, without additional side effects:
`submitBookingRequest`, `updateBooking`, `addBooking`, `endBooking`,
`ignoreOverlaps`, `confirmRequest`, `denyRequest`, `revisitBookingRequest`,
`deleteBooking`, `decorateLogs`, `listRequests`, `getRequestDetails`,
`getRequest`, `submitAmendment`, `getAmendment`, `applyAmendment`, and
`rejectAmendment`.

#### Scenario: Pass-through write delegates to BookingRepo
- **WHEN** `confirmRequest`, `denyRequest`, `endBooking`, `ignoreOverlaps`,
  `revisitBookingRequest`, `deleteBooking`, `submitAmendment`,
  `applyAmendment`, or `rejectAmendment` is called on `BookingService`
- **THEN** `BookingService` SHALL call the identically-named method on
  `BookingRepo` with the same arguments and return its result.

#### Scenario: Pass-through read delegates to BookingRepo
- **WHEN** `listRequests`, `getRequestDetails`, `getRequest`,
  `decorateLogs`, or `getAmendment` is called on `BookingService`
- **THEN** `BookingService` SHALL return the stream produced by the
  identically-named method on `BookingRepo`.
