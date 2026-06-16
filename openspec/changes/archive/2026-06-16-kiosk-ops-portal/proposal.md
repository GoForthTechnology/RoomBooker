## Why

Admins have no visibility into which rooms have a Kiosk attached or
when it was provisioned, and can only de-provision from the physical
device itself. This makes it impossible to remotely disconnect a lost,
stolen, or malfunctioning Kiosk without physical access.

## What Changes

- The Portal's room management UI SHALL display Kiosk attachment status
  per room: whether a Kiosk is currently linked, its device ID, and
  the date it was provisioned.
- Admins SHALL be able to revoke a Kiosk's grant directly from the
  Portal (remote de-provisioning), without needing access to the device.
- The "Provision Kiosk" (Link) button SHALL be hidden for rooms that
  already have an active Kiosk grant, replaced by the attachment status
  and a "Revoke" action.

## Capabilities

### New Capabilities
- `kiosk-ops`: Portal admin UI for viewing and remotely revoking
  Kiosk grants per room.

### Modified Capabilities
- `kiosk-provisioning`: The Portal provisioning flow now conditionally
  shows either the "Link Kiosk" button or the active-grant status view
  depending on whether a grant exists.

## Impact

- **Portal UI**: `room_list_widget.dart` (or equivalent room settings
  screen) gains a per-room Kiosk status section.
- **roombooker_core**: `ProvisioningService.revokeKioskGrant` already
  exists and supports admin-initiated revocation (takes `orgID` +
  `roomID`); no new backend logic needed.
- **Firestore**: Read access to `kiosk-grants` sub-collection needs a
  rule allowing admins to list/read grants for their org's rooms.
- **No Cloud Function changes** required.
