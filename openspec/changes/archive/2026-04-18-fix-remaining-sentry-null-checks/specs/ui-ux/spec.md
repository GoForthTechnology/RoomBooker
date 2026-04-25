## ADDED Requirements

### Requirement: Interactive Stability
The application MUST remain stable and MUST NOT crash when a user initiates an action (e.g., clicking a button) while the underlying view state or controller properties are still initializing.

#### Scenario: Click Add New Booking during initialization
- **WHEN** the user clicks the "Add New Booking" button immediately after the screen loads
- **THEN** the system SHALL handle potentially null calendar properties (like `displayDate`) gracefully by using sensible defaults instead of crashing.
