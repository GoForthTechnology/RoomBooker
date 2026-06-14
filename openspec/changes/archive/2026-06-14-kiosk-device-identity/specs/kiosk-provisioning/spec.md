## MODIFIED Requirements

### Requirement: Activation Handshake
The system MUST use a 6-digit numeric activation code to securely link a new hardware device to a specific room and organization, and to establish the Kiosk's Room-Scoped Kiosk Grant.

#### Scenario: Generate Activation Code
- **WHEN** an admin selects "Link Kiosk" for a room in the Portal app
- **THEN** the system SHALL generate a unique 6-digit code and store it in Firestore with a 10-minute expiration.

#### Scenario: Claim Device via Code
- **WHEN** a user enters a valid activation code on a fresh Kiosk terminal
- **THEN** the Kiosk SHALL ensure it has an active Firebase Anonymous Auth session, call `claimKioskGrant` with the code and its `deviceID`, and on success persist the returned `roomID` and `orgID` to secure local storage.

### Requirement: Protected De-provisioning
To prevent accidental or unauthorized device resetting, the de-provisioning control MUST be located within a multi-step navigation flow or behind an informational layer, and de-provisioning MUST revoke the device's Room-Scoped Kiosk Grant.

#### Scenario: De-provisioning Location
- **WHEN** the Kiosk is in an active state
- **THEN** the "De-provision" button SHALL NOT be visible on the primary dashboard and SHALL instead be located within the "Device Info" dialog.

#### Scenario: De-provisioning Revokes Grant
- **WHEN** an admin confirms de-provisioning on the Kiosk
- **THEN** the system SHALL call `revokeKioskGrant` for the current `orgID`/`roomID` before clearing the locally persisted `roomID` and `orgID`.
