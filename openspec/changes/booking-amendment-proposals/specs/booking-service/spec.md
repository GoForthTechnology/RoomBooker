## ADDED Requirements

### Requirement: Submit Amendment
`BookingService.submitAmendment` SHALL accept an `orgID`, the confirmed
`Request` being amended, a `BookingAmendment` payload, and delegate to
`BookingRepo.submitAmendment`. The repo SHALL atomically create the
`amendment-details/{requestID}` document and set `hasPendingAmendment: true`
on the confirmed-request document. If `hasPendingAmendment` is already `true`
on the confirmed-request, the operation SHALL throw an `StateError`.

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

## MODIFIED Requirements

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
