# Data Model Specification: Room Booker

## Purpose
This document specifies the core data entities and their properties for the Room Booker system.

## [DATA-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Request Entity
The system SHALL include a `Request` entity that represents a booking for a room.

#### Scenario: Verify Request Fields
- **WHEN** creating a new `Request`
- **THEN** it includes fields for `id`, `eventStartTime`, `eventEndTime`, `roomID`, `roomName`, and `status`.

### Requirement: Recurrance Support
The `Request` entity SHALL support recurrence through a `RecurrancePattern`.

#### Scenario: Define Recurrence
- **WHEN** a user selects a daily frequency
- **THEN** the `RecurrancePattern` specifies a daily interval with an optional end date.

### Requirement: Private Request Details
Sensitive information about a booking MUST be stored separately in `PrivateRequestDetails`.

#### Scenario: Verify Sensitive Info Separation
- **WHEN** a guest submits a booking
- **THEN** their name, email, and phone are stored in a `PrivateRequestDetails` record.

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
