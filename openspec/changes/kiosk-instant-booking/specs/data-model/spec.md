## MODIFIED Requirements

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
