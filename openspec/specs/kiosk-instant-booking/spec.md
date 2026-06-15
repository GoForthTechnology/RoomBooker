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
