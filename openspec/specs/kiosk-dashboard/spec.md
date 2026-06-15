# Kiosk Dashboard Specification: Room Booker

## Purpose
This document defines the requirements for the Kiosk Dashboard's room
status display and daily agenda, the primary "In-Room Tactical Hub"
interface shown on the Kiosk's primary display.

## [KIOSK-DASHBOARD-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Tactical Information Density
The Kiosk Dashboard SHALL present room status and schedule information
using a layout optimized for viewing from 1-3 feet (arm's length), with
large fonts, high contrast, and minimal non-essential chrome.

#### Scenario: Hero status legible at a distance
- **WHEN** the Kiosk Dashboard is displayed
- **THEN** the room name and AVAILABLE/OCCUPIED status SHALL be rendered
  with large, high-contrast text suitable for reading from 1-3 feet away

### Requirement: Current Room Status
The Kiosk Dashboard SHALL display the assigned room's current status as
either AVAILABLE or OCCUPIED, derived from whether a confirmed booking for
the room is in progress at the current time.

#### Scenario: Room is occupied
- **WHEN** a confirmed booking's start time is at or before now and its end
  time is after now
- **THEN** the Dashboard SHALL display the status as OCCUPIED and show that
  booking's title (or "Private Meeting" if no public name) and Join button

#### Scenario: Room is available
- **WHEN** no confirmed booking for the room is in progress at the current
  time
- **THEN** the Dashboard SHALL display the status as AVAILABLE

### Requirement: Scrollable Daily Agenda
The Kiosk Dashboard SHALL display a scrollable agenda listing every
confirmed booking for the assigned room for the current local day, ordered
chronologically by start time, showing each booking's time range and title
(or "Private Meeting" if no public name is set).

#### Scenario: Multiple bookings today
- **WHEN** the assigned room has two or more confirmed bookings starting and
  ending within the current local day
- **THEN** the Dashboard's agenda SHALL list all of them in order of start
  time, each showing its start/end time and title

#### Scenario: No bookings today
- **WHEN** the assigned room has no confirmed bookings for the current local
  day
- **THEN** the Dashboard's agenda SHALL indicate that no meetings are
  scheduled

#### Scenario: Agenda is scrollable
- **WHEN** the number of confirmed bookings for the current local day
  exceeds the visible area of the agenda list
- **THEN** the user SHALL be able to scroll the agenda to view all bookings

### Requirement: Current Booking Highlighted in Agenda
When a booking is currently in progress, the Scrollable Daily Agenda SHALL
visually distinguish that booking's entry from the other entries.

#### Scenario: In-progress booking highlighted
- **WHEN** a confirmed booking's start time is at or before now and its end
  time is after now
- **THEN** that booking's entry in the agenda list SHALL be rendered with a
  distinct visual style (e.g. highlight or border) from non-current entries
