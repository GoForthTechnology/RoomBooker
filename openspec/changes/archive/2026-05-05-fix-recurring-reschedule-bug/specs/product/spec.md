## MODIFIED Requirements

### Requirement: Prevent Double-Booking
The system MUST NOT allow any room to be booked for overlapping time slots. This MUST include rescheduled instances of recurring bookings, ensuring they do not conflict with other confirmed bookings on their new dates.

#### Scenario: Attempt Overlapping Booking with Rescheduled Instance
- **WHEN** a user tries to book a slot that overlaps with a rescheduled instance of a recurring booking
- **THEN** the system rejects the request or shows a conflict warning
