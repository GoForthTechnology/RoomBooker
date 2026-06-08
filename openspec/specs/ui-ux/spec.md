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

### Requirement: Log-to-Calendar Deep Linking
When a user navigates to a booking from an audit log entry, the calendar SHALL automatically center on the relevant time slot and open the booking details panel.

#### Scenario: Navigate from Log to Calendar
- **WHEN** a user clicks "View" on a log entry for a specific booking
- **THEN** the calendar view SHALL open, the target booking SHALL be centered in the view, and the booking details panel SHALL be open.

### Requirement: Navigation Stack Persistence
Deep-linking from the settings screen to the calendar view SHALL preserve the navigation stack such that the user can return to the settings screen using the system back button or UI back affordance.

#### Scenario: Return to Settings from Calendar
- **WHEN** a user has navigated from the settings log to the calendar view and clicks the back button
- **THEN** the application SHALL return the user to the settings screen.

### Requirement: Active Booking Highlighting
The system SHALL provide a clear visual indicator for the booking currently being viewed or edited in the editor panel.

#### Scenario: Active Booking Border
- **WHEN** an event's details are open in the editor panel
- **THEN** the corresponding event on the calendar SHALL be displayed with a high-contrast border or outline.

### Requirement: State Transition Stability
The calendar view model SHALL remain stable and MUST NOT crash during state transitions, including initialization, window resizing, or view type changes.

#### Scenario: Resize window during initialization
- **WHEN** the browser window is resized while the calendar is still initializing
- **THEN** the view model SHALL handle potentially null controller properties gracefully without throwing exceptions.

### Requirement: Interactive Stability
The application MUST remain stable and MUST NOT crash when a user initiates an action (e.g., clicking a button) while the underlying view state or controller properties are still initializing.

#### Scenario: Click Add New Booking during initialization
- **WHEN** the user clicks the "Add New Booking" button immediately after the screen loads
- **THEN** the system SHALL handle potentially null calendar properties (like `displayDate`) gracefully by using sensible defaults instead of crashing.

### Requirement: Initialization Safety
The application SHALL NOT crash during core startup or authentication flows if asynchronous data (e.g., Firebase Auth user, Firestore data) is momentarily unavailable or null.

#### Scenario: Race condition during auth state change
- **WHEN** an authentication state change occurs (e.g., user signs in)
- **THEN** the system SHALL verify all required user and credential objects are non-null before performing null assertions or navigation.

### Requirement: Modal Rescheduling State
The application SHALL distinguish between "Creation" and "Rescheduling" states. While in the "Rescheduling" state, secondary calendar interactions (like taps) MUST be re-routed to modify the active event rather than initiating new workflows.

#### Scenario: Verify re-routed tap
- **WHEN** an existing booking is being edited (Rescheduling state)
- **AND** the user taps an available time slot in a time-aware view
- **THEN** the active booking SHALL "teleport" to the new time slot instead of opening a new request form.

### Requirement: Conditional FAB Visibility
The application SHALL hide the primary action button for creating new bookings (FAB) whenever the request editor panel is active on the calendar screen.

#### Scenario: Open request editor
- **WHEN** the user opens the request editor panel to view or edit a booking
- **THEN** the Floating Action Button (FAB) for adding new bookings SHALL NOT be visible

#### Scenario: Close request editor
- **WHEN** the user closes the request editor panel
- **AND** the calendar is in a view that supports the FAB
- **THEN** the Floating Action Button (FAB) SHALL become visible again

### Requirement: Editor Back Navigation Handling
The system SHALL intercept standard system back gestures (such as swipe-back on iOS or the hardware back button on Android) when the inline request editor panel is active, and it SHALL use these gestures to close the editor panel instead of navigating away from the calendar view.

#### Scenario: User swipes back while editor is open
- **WHEN** the inline request editor panel is visible on the ViewBookingsScreen
- **AND** the user performs a system back navigation (e.g., swiping back)
- **THEN** the request editor panel SHALL close
- **AND** the underlying calendar view SHALL remain active and visible on the screen.

#### Scenario: User swipes back while editor is closed
- **WHEN** the inline request editor panel is not visible on the ViewBookingsScreen
- **AND** the user performs a system back navigation
- **THEN** the system SHALL perform the default back navigation (e.g., popping the screen).

## Kiosk UI Requirements

### Requirement: Wall-Mounted Readability
The Kiosk UI MUST be readable from a distance of 10 feet. It SHALL use a high-contrast theme (Primary: Black/White) with large-scale typography (minimum 48pt for primary status).

### Requirement: Responsive Layout
The Kiosk application SHALL be responsive to various display sizes and aspect ratios, ensuring that critical room status information never wraps or becomes obscured.

#### Scenario: Verify Portrait Orientation
- **WHEN** the Kiosk app is viewed on a narrow mobile device (Portrait)
- **THEN** the primary status text (e.g., "AVAILABLE") SHALL scale down proportionally to fit the screen width without wrapping.

#### Scenario: Read Room Status from Hallway
- **WHEN** a user is standing 10 feet from the wall-mounted tablet
- **THEN** they SHALL be able to clearly identify if the room is "Available" or "Busy" via the background color and text size.

### Requirement: Ambient Status Background
The Kiosk application SHALL use the entire screen background as a primary status indicator (Green for Available, Red for Busy, Yellow for Transition).

#### Scenario: Verify Busy State
- **WHEN** a meeting is currently in progress
- **THEN** the entire tablet background SHALL be a high-saturation red to signal occupancy.

### Requirement: Service Handshake Visuals
The Kiosk UI SHALL provide real-time feedback during the "One-Touch Join" sequence.

#### Scenario: Track Join Progress
- **WHEN** the "Join" button is tapped
- **THEN** the Dashboard SHALL display a "Launching Meeting..." overlay until the video feed is successfully rendered on the Stage.
