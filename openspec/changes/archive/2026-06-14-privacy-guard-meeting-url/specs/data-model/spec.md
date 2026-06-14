## MODIFIED Requirements

### Requirement: Request Entity
The system SHALL include a `Request` entity that represents a booking for a
room. The `Request` entity SHALL NOT include a `meetingUrl` field.

#### Scenario: Verify Request Fields
- **WHEN** creating a new `Request`
- **THEN** it includes fields for `id`, `eventStartTime`, `eventEndTime`,
  `roomID`, `roomName`, and `status`, and does not include `meetingUrl`.

### Requirement: Private Request Details
Sensitive information about a booking MUST be stored separately in
`PrivateRequestDetails`, including the booking's video conference link.

#### Scenario: Verify Sensitive Info Separation
- **WHEN** a guest submits a booking
- **THEN** their name, email, and phone are stored in a
  `PrivateRequestDetails` record.

#### Scenario: Verify Meeting URL Storage
- **WHEN** a booking has an associated video conference link
- **THEN** the link is stored as `meetingUrl` on that booking's
  `PrivateRequestDetails` record, and not on the `Request` record.

## ADDED Requirements

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
