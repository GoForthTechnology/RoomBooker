# Kiosk Meet Provisioning Specification: Room Booker

## Purpose
This document specifies the automatic provisioning of a Google Meet Space
when a Kiosk instant booking is created, including the Cloud Function
lifecycle, Meet API integration, failure cleanup, and error signaling.

## [KIOSK-MEET-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119.

## ADDED Requirements

### Requirement: Meet Space Provisioning Trigger
The system SHALL provide a Cloud Function `onKioskBookingCreated` that
triggers on the creation of any `confirmed-requests/{bookingID}` document.
The function SHALL exit without side effects if the document does not have
`bookedVia` equal to `'kiosk'`.

#### Scenario: Non-Kiosk Booking Is Ignored
- **WHEN** a `confirmed-requests/{bookingID}` document is created without
  `bookedVia: 'kiosk'`
- **THEN** `onKioskBookingCreated` SHALL exit immediately without calling
  the Meet API, writing to `request-details`, or writing to
  `provisioning-errors`

#### Scenario: Kiosk Booking Triggers Provisioning
- **WHEN** a `confirmed-requests/{bookingID}` document is created with
  `bookedVia: 'kiosk'`
- **THEN** `onKioskBookingCreated` SHALL attempt to create a Google Meet
  Space via the Meet REST API (`meet.googleapis.com/v2/spaces`)

### Requirement: Meet Space Creation on Success
On a successful Meet API call, `onKioskBookingCreated` SHALL write the
returned `meetingUri` to the `meetingUrl` field of the corresponding
`orgs/{orgID}/request-details/{bookingID}` document.

#### Scenario: Meet API Returns a URI
- **WHEN** the Meet REST API call succeeds and returns a `meetingUri`
- **THEN** the function SHALL update `request-details/{bookingID}` with
  `{ meetingUrl: <meetingUri> }`
- **AND** the function SHALL NOT write to `provisioning-errors`

### Requirement: Cleanup and Error Signaling on Failure
On a Meet API error or function timeout, `onKioskBookingCreated` SHALL:
1. Write a transient error document to
   `orgs/{orgID}/rooms/{roomID}/provisioning-errors/{errorID}` containing
   at least `{ bookingID, message, timestamp }`.
2. Delete `confirmed-requests/{bookingID}`.
3. Delete `request-details/{bookingID}`.

The error document message SHALL be a generic, user-facing string
(e.g., `"Couldn't generate Meet link. Please try again."`). Detailed
error information SHALL be written to Cloud Function logs only.

#### Scenario: Meet API Fails
- **WHEN** the Meet REST API call throws an error or returns a non-success
  response
- **THEN** the function SHALL write a `provisioning-errors` document for
  the booking's room, then delete both `confirmed-requests/{bookingID}` and
  `request-details/{bookingID}`

#### Scenario: Function Timeout Triggers Self-Cleanup
- **WHEN** the Cloud Function reaches its execution timeout (15 seconds)
  before receiving a Meet API response
- **THEN** any cleanup code that has not yet run SHALL be skipped by the
  runtime; the remaining cleanup (booking deletion) is left to the
  Kiosk client-side timeout path

### Requirement: Function Timeout Configuration
The `onKioskBookingCreated` Cloud Function SHALL have its timeout configured
to 15 seconds to ensure fast failure and timely cleanup signaling ahead of
the Kiosk's 30-second client-side watchdog.

#### Scenario: Function Is Configured
- **WHEN** the function is deployed
- **THEN** it SHALL have a `timeoutSeconds` of 15

### Requirement: Meet Provisioner Service Account
The Google Meet REST API calls in `onKioskBookingCreated` SHALL authenticate
using a dedicated `meet-provisioner` service account with the
`https://www.googleapis.com/auth/meetings.space.created` scope. This
service account SHALL have no Firebase Admin or Firestore permissions.

#### Scenario: Service Account Is Scoped
- **WHEN** the `meet-provisioner` service account is used to call any API
  other than `meet.googleapis.com`
- **THEN** the call SHALL be rejected by Google's authorization layer

### Requirement: Provisioning Idempotency Guard
Before calling the Meet API, `onKioskBookingCreated` SHALL check whether
`request-details/{bookingID}.meetingUrl` is already set. If it is, the
function SHALL exit without creating a new Meet Space.

#### Scenario: meetingUrl Already Present
- **WHEN** `onKioskBookingCreated` fires for a booking whose
  `request-details/{bookingID}` already has a non-null `meetingUrl`
- **THEN** the function SHALL exit without calling the Meet API or writing
  any documents
