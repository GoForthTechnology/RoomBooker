## ADDED Requirements

### Requirement: BookingAmendment Entity
The system SHALL include a `BookingAmendment` entity that represents a
pending proposed change to a confirmed booking. It SHALL contain the full
proposed `Request` state, the full proposed `PrivateRequestDetails`, the
amendment scope (`AmendmentScope`), and a `proposedAt` timestamp. The entity
SHALL be serializable to/from Firestore JSON via `json_serializable`.

#### Scenario: BookingAmendment fields are present
- **WHEN** a `BookingAmendment` is created
- **THEN** it contains `proposedRequest` (a `Request`), `proposedDetails`
  (a `PrivateRequestDetails`), `scope` (an `AmendmentScope`), and
  `proposedAt` (a `DateTime`).

### Requirement: AmendmentScope Enum
The system SHALL include an `AmendmentScope` enum with values `thisInstance`
and `thisAndFuture`. This value is stored on `BookingAmendment` and
determines the apply logic used by `BookingRepo`.

#### Scenario: Scope values are serializable
- **WHEN** an `AmendmentScope` value is serialized to JSON and back
- **THEN** the deserialized value equals the original.

### Requirement: hasPendingAmendment Flag on Request
The `Request` entity SHALL include an optional `hasPendingAmendment` boolean
field. When absent from a Firestore document it SHALL deserialize as `false`.
This field SHALL NOT be included in `toJson` output when `false` or `null`
(to avoid polluting existing documents).

#### Scenario: Absent hasPendingAmendment deserializes as false
- **WHEN** a `Request` is deserialized from a Firestore document that does
  not contain a `hasPendingAmendment` field
- **THEN** `request.hasPendingAmendment` is `false`.

#### Scenario: hasPendingAmendment true is preserved through serialization
- **WHEN** a `Request` with `hasPendingAmendment: true` is serialized and
  deserialized
- **THEN** the round-trip value is `true`.

## MODIFIED Requirements

### Requirement: Private Request Details
Sensitive information about a booking MUST be stored separately in
`PrivateRequestDetails`, including the booking's video conference link. The
`PrivateRequestDetails` entity is also used as the proposed details payload
within `BookingAmendment` — its fields represent the desired state if the
amendment is applied.

#### Scenario: Verify Sensitive Info Separation
- **WHEN** a guest submits a booking
- **THEN** their name, email, and phone are stored in a
  `PrivateRequestDetails` record.

#### Scenario: Verify Meeting URL Storage
- **WHEN** a booking has an associated video conference link
- **THEN** the link is stored as `meetingUrl` on that booking's
  `PrivateRequestDetails` record, and not on the `Request` record.

#### Scenario: PrivateRequestDetails used as amendment proposed payload
- **WHEN** a `BookingAmendment` is created
- **THEN** its `proposedDetails` field is a `PrivateRequestDetails` instance
  containing the full desired contact and event details for the amended booking.
