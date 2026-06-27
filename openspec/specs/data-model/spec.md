# Data Model Specification: Room Booker

## Purpose
This document specifies the core data entities and their properties for the Room Booker system.

## [DATA-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.
## Requirements
### Requirement: Request Entity
The system SHALL include a `Request` entity that represents a booking for a
room. The `Request` entity SHALL NOT include a `meetingUrl` field. The
`Request` entity SHALL include an optional `bookedVia` field identifying
the origin of a booking (e.g. Kiosk-originated "In-Room" bookings).

#### Scenario: Verify Request Fields
- **WHEN** creating a new `Request`
- **THEN** it includes fields for `id`, `eventStartTime`, `eventEndTime`,
  `roomID`, `roomName`, `status`, and `bookedVia`, and does not include
  `meetingUrl`.

#### Scenario: Default bookedVia is absent
- **WHEN** creating a `Request` without specifying `bookedVia`
- **THEN** the `bookedVia` field SHALL be `null`/absent, and existing
  stored `Request` documents without a `bookedVia` field SHALL deserialize
  successfully with `bookedVia == null`.

#### Scenario: Kiosk-originated booking
- **WHEN** a `Request` is created via the Kiosk's Quick Book feature
- **THEN** its `bookedVia` field SHALL identify it as Kiosk-originated

### Requirement: Recurrance Support
The `Request` entity SHALL support recurrence through a `RecurrancePattern`.

#### Scenario: Define Recurrence
- **WHEN** a user selects a daily frequency
- **THEN** the `RecurrancePattern` specifies a daily interval with an optional end date.

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

### Requirement: User Profile
The system SHALL support a `UserProfile` entity for authenticated users.

#### Scenario: Store User Info
- **WHEN** a user signs in for the first time
- **THEN** a `UserProfile` is created with their UID, display name, and email.

### Requirement: Firestore Collections
Data SHALL be organized into logical Firestore collections: `requests`, `private_request_details`, `users`, and `rooms`.

#### Scenario: Check Firestore Structure
- **WHEN** inspecting the Firestore database
- **THEN** the specified collections are present with their respective documents.

### Requirement: Meeting URL Migration
The system MUST migrate existing `confirmed-requests` documents with a
non-null `meetingUrl` field to the corresponding
`PrivateRequestDetails.meetingUrl` before the `Request.meetingUrl` field is
removed from the deployed application, so that no meeting links are lost.

#### Scenario: Backfill existing confirmed requests
- **WHEN** the migration script runs against an org's `confirmed-requests`
  collection
- **THEN** every document with a non-null `meetingUrl` has that value copied
  into its `private-request-details/{requestID}` document's `meetingUrl`
  field, and the `meetingUrl` field is removed from the `confirmed-requests`
  document.

