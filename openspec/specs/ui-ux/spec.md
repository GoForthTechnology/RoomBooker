# UI/UX Specification: Room Booker

## Purpose
This document defines the user interface design principles and the primary screens for the Room Booker application.

## [UI-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Calendar-Centric Navigation
The home screen SHALL feature a visual calendar that displays room schedules.

#### Scenario: View Room Schedule
- **WHEN** the user opens the application
- **THEN** they see a calendar with colored blocks representing booked slots.

### Requirement: Responsive Layout
The UI MUST adapt to different screen sizes, providing an optimal experience for both Mobile and Web users.

#### Scenario: Resize Browser Window
- **WHEN** a web user resizes their browser window
- **THEN** the layout adjusts (e.g., sidebar collapses, grid columns change) without breaking functionality.

### Requirement: Streamlined Booking Process
The process of initiating a booking request SHALL be simple and intuitive.

#### Scenario: Quick Booking
- **WHEN** a user long-presses an empty slot on the calendar
- **THEN** a booking request form opens with the selected time pre-filled.

### Requirement: Clear Booking Status
The status of every booking (Pending, Confirmed, Denied) SHALL be clearly visible to the user.

#### Scenario: Check Booking Status
- **WHEN** a user views their "My Bookings" list
- **THEN** each item has a distinct visual indicator (e.g., color, icon) representing its status.

### Requirement: Material Design Aesthetics
The application SHALL follow Material Design guidelines, incorporating custom shadows and interactive effects.

#### Scenario: Interact with Buttons
- **WHEN** a user hovers over or taps a primary button
- **THEN** it shows a subtle "glow" or elevation change to provide feedback.

### Requirement: Log Attribution Visibility
The request log widget MUST clearly distinguish between actions taken by the original requester and actions taken by an administrator.

#### Scenario: Display Admin Action
- **WHEN** viewing the request log for a booking that has been approved
- **THEN** the approval entry MUST display the admin's email or name as the actor, not the requester's details.
