# Kiosk Provisioning Specification: Room Booker

## Purpose
This document specifies how Kiosk devices are linked to a room and
organization via an activation code, how that identity is persisted and
verified, and the security/UX guarantees around (de)provisioning.

## [PROV-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Activation Handshake
The system MUST use a 6-digit numeric activation code to securely link a new hardware device to a specific room and organization, and to establish the Kiosk's Room-Scoped Kiosk Grant.

#### Scenario: Generate Activation Code
- **WHEN** an admin selects "Link Kiosk" for a room in the Portal app
- **THEN** the system SHALL generate a unique 6-digit code and store it in Firestore with a 10-minute expiration.

#### Scenario: Claim Device via Code
- **WHEN** a user enters a valid activation code on a fresh Kiosk terminal
- **THEN** the Kiosk SHALL ensure it has an active Firebase Anonymous Auth session, call `claimKioskGrant` with the code and its `deviceID`, and on success persist the returned `roomID` and `orgID` to secure local storage.

### Requirement: Device Identity Persistence
The Kiosk application MUST persist its assigned room identity across reboots and application restarts.

#### Scenario: Auto-Resume after Reboot
- **WHEN** the Kiosk hardware reboots
- **THEN** the application SHALL read the stored `roomID` and automatically resume the Dashboard for that room.

### Requirement: Provisioning Transparency
The Kiosk application MUST provide a mechanism for administrators to verify the current organization and room linkage directly on the device.

#### Scenario: Verify Device Identity
- **WHEN** an admin accesses the device info interface on the Kiosk
- **THEN** the system SHALL resolve the Organization Name and Room Name via a live Firestore stream using the provisioned IDs and display them along with their respective unique IDs.

### Requirement: Provisioning Security
Activation codes MUST be single-use and restricted to administrative users.

#### Scenario: Prevent Code Re-use
- **WHEN** a code has been successfully used to provision a Kiosk
- **THEN** the system SHALL immediately invalidate the code in Firestore.

### Requirement: Protected De-provisioning
To prevent accidental or unauthorized device resetting, the de-provisioning control MUST be located within a multi-step navigation flow or behind an informational layer, and de-provisioning MUST revoke the device's Room-Scoped Kiosk Grant.

#### Scenario: De-provisioning Location
- **WHEN** the Kiosk is in an active state
- **THEN** the "De-provision" button SHALL NOT be visible on the primary dashboard and SHALL instead be located within the "Device Info" dialog.

#### Scenario: De-provisioning Revokes Grant
- **WHEN** an admin confirms de-provisioning on the Kiosk
- **THEN** the system SHALL call `revokeKioskGrant` for the current `orgID`/`roomID` before clearing the locally persisted `roomID` and `orgID`.
