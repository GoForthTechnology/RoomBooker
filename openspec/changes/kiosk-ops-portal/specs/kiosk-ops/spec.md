# Kiosk Ops Portal Specification: Room Booker

## Purpose
This document specifies the Portal admin interface for viewing and
remotely managing Kiosk device grants per room.

## [KIOSK-OPS-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Kiosk Attachment Visibility
The Portal's room management interface SHALL display the Kiosk
attachment status for each room: whether a Kiosk grant is active, the
device ID, and the date the Kiosk was provisioned.

#### Scenario: Room has an active Kiosk grant
- **WHEN** an admin views the room list and a room has at least one
  active `kiosk-grants` document
- **THEN** the Portal SHALL display the device ID (truncated) and the
  provisioned date for that room, in place of the "Link Kiosk" button.

#### Scenario: Room has no active Kiosk grant
- **WHEN** an admin views the room list and a room has no
  `kiosk-grants` documents
- **THEN** the Portal SHALL display the "Link Kiosk" button for that
  room, as it does today.

#### Scenario: Multiple grants exist for a room
- **WHEN** a room has more than one `kiosk-grants` document
- **THEN** the Portal SHALL display a warning indicating multiple
  devices are linked and the revoke action SHALL remove all grants.

### Requirement: Remote Kiosk Revocation
An org admin SHALL be able to revoke a room's Kiosk grant from the
Portal without requiring physical access to the Kiosk device.

#### Scenario: Admin revokes a Kiosk grant
- **WHEN** an admin taps "Revoke" for a room that has an active Kiosk
  grant
- **THEN** the system SHALL call `adminRevokeKioskGrant` with the
  room's `orgID` and `roomID`, deleting all `kiosk-grants` documents
  for that room, and the Portal SHALL update to show the "Link Kiosk"
  button.

#### Scenario: Revocation is confirmed before executing
- **WHEN** an admin taps "Revoke"
- **THEN** the Portal SHALL show a confirmation dialog before
  proceeding, making clear the Kiosk device will lose room access on
  its next interaction.

### Requirement: Admin Revoke Cloud Function
The system SHALL provide a callable Cloud Function
`adminRevokeKioskGrant(orgID, roomID)` that allows an org admin to
delete all Kiosk grants for a given room.

#### Scenario: Authorized admin calls the function
- **WHEN** an authenticated user who is an org admin or owner calls
  `adminRevokeKioskGrant` with a valid `orgID` and `roomID`
- **THEN** the system SHALL delete all documents in
  `orgs/{orgID}/rooms/{roomID}/kiosk-grants/` using the Admin SDK and
  return `{ success: true }`.

#### Scenario: Non-admin calls the function
- **WHEN** a user who is not an admin or owner of `orgID` calls
  `adminRevokeKioskGrant`
- **THEN** the system SHALL reject the call with a
  `permission-denied` error.
