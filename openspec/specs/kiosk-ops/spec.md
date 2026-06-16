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
attachment status for each room via a single icon button in the room
list trailing area, following [UI-CONV-001] (one interactive element
per trailing slot).

- When **no grant** exists: display the "Link Kiosk" icon button
  (`Icons.screenshot_monitor`).
- When **one or more grants** exist: display a "Kiosk Linked" icon
  button (`Icons.phonelink`, green). Tapping opens a detail dialog
  showing the device ID, provisioned date, and a Revoke action.

#### Scenario: Room has an active Kiosk grant
- **WHEN** an admin views the room list and a room has at least one
  active `kiosk-grants` document
- **THEN** the Portal SHALL display a green `Icons.phonelink` button
  for that room. Tapping it opens a dialog showing the device ID,
  provisioned date, and a "Revoke" action button.

#### Scenario: Room has no active Kiosk grant
- **WHEN** an admin views the room list and a room has no
  `kiosk-grants` documents
- **THEN** the Portal SHALL display the "Link Kiosk" button
  (`Icons.screenshot_monitor`) for that room.

#### Scenario: Multiple grants exist for a room
- **WHEN** a room has more than one `kiosk-grants` document
- **THEN** the Portal SHALL display the green `Icons.phonelink` button.
  The detail dialog SHALL indicate that multiple devices are linked and
  the revoke action SHALL remove all grants ("Revoke All").

### Requirement: Remote Kiosk Revocation
An org admin SHALL be able to revoke a room's Kiosk grant from the
Portal without requiring physical access to the Kiosk device.

#### Scenario: Admin revokes a Kiosk grant
- **WHEN** an admin taps "Revoke" (or "Revoke All") in the Kiosk
  detail dialog
- **THEN** the system SHALL call `adminRevokeKioskGrant` with the
  room's `orgID` and `roomID`, deleting all `kiosk-grants` documents
  for that room, and the Portal SHALL update to show the "Link Kiosk"
  button.

#### Scenario: Revocation is confirmed before executing
- **WHEN** an admin taps "Revoke" in the detail dialog
- **THEN** the dialog itself serves as the confirmation surface:
  it displays the device ID and provisioned date before offering the
  Revoke action, satisfying [UI-CONV-003].

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
