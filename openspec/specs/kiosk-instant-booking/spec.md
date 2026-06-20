# Kiosk Instant Booking Specification: Room Booker

## Purpose
This document specifies the Kiosk Dashboard's "Quick Book" feature: instant,
auto-confirmed bookings of the assigned room for fixed durations, gap-aware
enabling/disabling, and "In-Room User" attribution in the Portal.

## [KIOSK-IB-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Quick Book Buttons
The Kiosk Dashboard SHALL display "Quick Book" buttons for 15, 30, and 60
minute durations when the assigned room's current status is AVAILABLE, and
SHALL NOT display them when the room is OCCUPIED.

#### Scenario: Room available
- **WHEN** the assigned room's current status is AVAILABLE
- **THEN** the Kiosk Dashboard SHALL display Quick Book buttons for 15m,
  30m, and 60m

#### Scenario: Room occupied
- **WHEN** the assigned room's current status is OCCUPIED
- **THEN** the Kiosk Dashboard SHALL NOT display Quick Book buttons

### Requirement: Quick Book Respects the Available Gap
A Quick Book duration SHALL only be selectable if booking it would not
overlap the room's next confirmed booking for the current local day.

#### Scenario: Next booking is far enough away
- **WHEN** the room is AVAILABLE and the next confirmed booking starts more
  than 60 minutes from now (or there is no later booking today)
- **THEN** the 15m, 30m, and 60m Quick Book buttons SHALL all be enabled

#### Scenario: Next booking limits the available gap
- **WHEN** the room is AVAILABLE and the next confirmed booking starts in
  20 minutes
- **THEN** the 15m Quick Book button SHALL be enabled, and the 30m and 60m
  Quick Book buttons SHALL be disabled

### Requirement: Quick Book Creates an Auto-Confirmed Booking
Tapping an enabled Quick Book button SHALL create a confirmed booking for
the assigned room, starting at the current time and ending after the
selected duration, attributed to the Kiosk (REQ-21).

#### Scenario: Tap 30m Quick Book
- **WHEN** the user taps the 30m Quick Book button on an AVAILABLE room
- **THEN** the system SHALL create a confirmed booking for the assigned
  room from now until 30 minutes from now, with `bookedVia` set to
  identify it as Kiosk-originated, and without requiring further
  confirmation

### Requirement: In-Room User Attribution
Bookings created via Quick Book SHALL be identifiable as Kiosk-originated
(the "In-Room User") wherever booking attribution is shown, without
requiring a per-Kiosk admin account.

#### Scenario: Portal displays Kiosk attribution
- **WHEN** an admin views a booking or log entry for a request created via
  Quick Book
- **THEN** the Portal SHALL display an indication that the booking was
  "Booked via Kiosk" (or equivalent "In-Room Hub" label) in place of an
  admin email

### Requirement: Provisioning In-Progress State
After a Quick Book action, the Kiosk Dashboard SHALL display a
"provisioning in progress" state while the Kiosk booking has no `meetingUrl`
and no provisioning error is active. This state is inferred from the
Firestore stream: a booking with `bookedVia == 'kiosk'` and
`meetingUrl == null`.

#### Scenario: Booking Created, URL Not Yet Written
- **WHEN** a Quick Book booking is created and `request-details/{id}.meetingUrl`
  is null
- **THEN** the Kiosk Dashboard SHALL display a loading indicator and a
  "Generating Meet link…" message in place of the JOIN button

#### Scenario: URL Written by Cloud Function
- **WHEN** `request-details/{id}.meetingUrl` becomes non-null via the
  Firestore stream
- **THEN** the Kiosk Dashboard SHALL transition from the provisioning state
  to the normal OCCUPIED state with the JOIN button visible and active

### Requirement: Provisioning Error State
The Kiosk Dashboard SHALL subscribe to its room's
`orgs/{orgID}/rooms/{roomID}/provisioning-errors` subcollection. When one
or more error documents are present, the Dashboard SHALL display a
high-level error banner with a dismiss action.

#### Scenario: Provisioning Error Document Appears
- **WHEN** a document is written to
  `orgs/{orgID}/rooms/{roomID}/provisioning-errors`
- **THEN** the Kiosk Dashboard SHALL display an error banner containing
  the document's `message` field and a "Retry" or "OK" dismiss button

#### Scenario: User Dismisses Error Banner
- **WHEN** the user taps the dismiss button on the error banner
- **THEN** the Kiosk Dashboard SHALL delete the error document from
  Firestore and return to the AVAILABLE state (since the booking was
  already cleaned up by the Cloud Function)

#### Scenario: No Error Documents
- **WHEN** the `provisioning-errors` subcollection for the room is empty
- **THEN** no error banner SHALL be displayed

### Requirement: Client-Side Provisioning Timeout
The Kiosk Dashboard SHALL start a 30-second watchdog timer immediately after
a Quick Book action completes. If the provisioning state is still active
(no `meetingUrl`, no error document) when the timer expires, the Dashboard
SHALL self-clean the booking and display a timeout banner.

#### Scenario: Timeout Fires with Booking Still Present
- **WHEN** 30 seconds elapse after a Quick Book action and
  `request-details/{id}.meetingUrl` is still null and no error document
  exists for the room
- **THEN** the Kiosk Dashboard SHALL delete `confirmed-requests/{id}` from
  Firestore and display a timeout error banner prompting the user to retry

#### Scenario: Provisioning Completes Before Timeout
- **WHEN** `meetingUrl` is written or an error document appears before the
  30-second timer expires
- **THEN** the watchdog timer SHALL be cancelled and no timeout action
  SHALL be taken

#### Scenario: User Dismisses Timeout Banner
- **WHEN** the user taps dismiss on the timeout error banner
- **THEN** the banner SHALL be hidden and the Dashboard SHALL display the
  AVAILABLE state with Quick Book buttons
