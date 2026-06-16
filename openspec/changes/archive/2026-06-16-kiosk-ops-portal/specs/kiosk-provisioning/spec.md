## MODIFIED Requirements

### Requirement: Provisioning Transparency

The Portal's "Link Kiosk" provisioning button SHALL only be shown when
the room has no active Kiosk grant. When a grant is present, the Portal
SHALL display the Kiosk attachment status (device ID, provisioned date)
in place of the "Link Kiosk" button.

#### Scenario: Generate Activation Code (unchanged)
- **WHEN** an admin selects "Link Kiosk" for a room in the Portal app
- **THEN** the system SHALL generate a unique 6-digit code and store it
  in Firestore with a 10-minute expiration.

#### Scenario: Link Kiosk button hidden when grant exists
- **WHEN** an admin views the room list and the room already has an
  active `kiosk-grants` document
- **THEN** the Portal SHALL NOT show the "Link Kiosk" button for that
  room; instead it SHALL show the Kiosk attachment status as defined
  by the `kiosk-ops` capability.
