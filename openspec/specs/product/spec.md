# Product Specification: Room Booker

## Purpose
This document defines the high-level goals, target audience, and core features of the Room Booker application.

## [PROD-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Cross-Platform Support
The application SHALL be available on iOS, Android, and Web from a single codebase.

#### Scenario: Verify Platform Availability
- **WHEN** building the application
- **THEN** it can be targeted for iOS, Android, and Web platforms

### Requirement: Guest Access
Unauthenticated users MUST be able to view the room calendar and submit booking requests.

#### Scenario: Submit Request as Guest
- **WHEN** a guest user selects an available time slot
- **THEN** they are prompted for their email address and can submit a request

### Requirement: Email Confirmation for Guests
Guest users MUST receive a confirmation link via email after submitting a request.

#### Scenario: Receive Confirmation Link
- **WHEN** a guest user submits a booking request
- **THEN** an email with a unique management link is sent to their address

### Requirement: Authenticated User Management
Users who sign up/login MUST be able to manage all their bookings within the application.

#### Scenario: View My Bookings
- **WHEN** an authenticated user navigates to the "My Bookings" section
- **THEN** they see all their past and upcoming reservations

### Requirement: Prevent Double-Booking
The system MUST NOT allow any room to be booked for overlapping time slots.

#### Scenario: Attempt Overlapping Booking
- **WHEN** a user tries to book a slot that overlaps with an existing confirmed booking
- **THEN** the system rejects the request or shows a conflict warning

### Requirement: Accurate Audit Logs
The system SHALL maintain an audit log of all booking-related actions, correctly attributing each action to the person who performed it (the actor).

#### Scenario: Verify Admin Action Attribution
- **WHEN** an admin approves or denies a booking request
- **THEN** the audit log SHALL record the admin's email as the actor for that action.
