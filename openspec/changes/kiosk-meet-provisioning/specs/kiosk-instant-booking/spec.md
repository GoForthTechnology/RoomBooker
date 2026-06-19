# Kiosk Instant Booking Specification (Delta): Room Booker

## ADDED Requirements

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
