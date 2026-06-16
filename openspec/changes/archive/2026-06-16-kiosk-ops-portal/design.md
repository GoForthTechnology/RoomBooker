## Context

Phase 4c (`kiosk-device-identity`) established the `kiosk-grants/{uid}`
sub-collection under `orgs/{orgID}/rooms/{roomID}/`. Each doc written by
`claimKioskGrant` contains `{ deviceID, createdAt }`. Admins can already
read these docs via the `allow read: if isAdmin()` Firestore rule.

The only missing pieces are:
1. A Portal UI to surface that data per room.
2. A Cloud Function for admin-initiated revocation (the existing
   `revokeKioskGrant` deletes `kiosk-grants/{caller.uid}` — it is
   designed for the Kiosk to revoke its own grant, not for an admin to
   revoke a Kiosk's grant).

## Goals / Non-Goals

**Goals:**
- Admins can see, per room, whether a Kiosk is linked (device ID +
  provisioned date) directly in the Portal room list.
- Admins can revoke a Kiosk's grant remotely from the Portal.
- The Portal hides the "Link Kiosk" button when a grant already exists
  (prevent duplicate provisioning confusion).

**Non-Goals:**
- Online/offline heartbeat status (Phase 5 Ops Monitoring proper).
- Supporting multiple simultaneous Kiosks per room.
- Any Kiosk-side changes.

## Decisions

### 1. New `adminRevokeKioskGrant` Cloud Function for revocation

The existing `revokeKioskGrant` always deletes `kiosk-grants/{caller.uid}`,
so an admin calling it from the Portal would delete their own (non-existent)
grant doc. A new function `adminRevokeKioskGrant(orgID, roomID)` is needed
that:
- Verifies the caller is an org admin or owner.
- Uses the Admin SDK to delete all docs in
  `orgs/{orgID}/rooms/{roomID}/kiosk-grants/`.

**Alternative considered**: Relax the Firestore `allow write: if false`
rule on `kiosk-grants` to `allow delete: if isAdmin()`, letting the Portal
delete directly. Rejected — it would conflict with the spec's
"server-managed" invariant and require knowing the grant's doc ID (kiosk
UID) before deleting, which adds a read-then-delete round trip with no
benefit over a function.

### 2. New `KioskGrantRecord` entity in `roombooker_core`

The Portal needs to display `deviceID` and `createdAt` from the grant doc.
The existing `KioskGrant` entity holds org/room identity (returned by
`claimKioskGrant`) — a different shape. A new lightweight
`KioskGrantRecord` (uid, deviceID, createdAt) is added to core and used
by a new `ProvisioningService.listKioskGrants(orgID, roomID)` stream.

### 3. UI: inline status in `_RoomListItem`

The per-room Kiosk section lives inside `_RoomListItem` in
`room_list_widget.dart`. It drives off a `StreamBuilder` on
`listKioskGrants`. Two states:
- **Empty stream**: show existing "Provision Kiosk" icon button.
- **Grant present**: show chip/row with device ID (truncated), provisioned
  date, and a "Revoke" icon button that calls `adminRevokeKioskGrant`.

No new screen or route is required — the room list already serves as the
admin provisioning surface.

## Risks / Trade-offs

- **[Risk] Multiple grants per room**: the data model allows multiple
  `kiosk-grants` docs (one per UID). In practice there is at most one,
  but if somehow two exist, the Portal shows only the first and the
  revoke function deletes all.
  → Mitigation: revoke deletes all docs in the sub-collection; UI shows
  "Multiple devices — revoke all?" if `grants.length > 1`.

- **[Risk] Revoked Kiosk stays on dashboard**: After admin revocation the
  Kiosk app is still running and authenticated. It will get
  `permission-denied` on its next Firestore write (Quick Book) or stream
  read. There is no push signal to force it back to the provisioning screen.
  → Acceptable for now. The Kiosk will need a restart or next-wake event to
  detect the revocation. A future "force-deregister" push notification could
  close this gap (Phase 5 Ops Monitoring).

## Migration Plan

No data migration needed — `kiosk-grants` docs already exist from Phase 4c.
Deployment order:
1. Deploy new Cloud Function (`adminRevokeKioskGrant`) via backend CD.
2. Portal UI update ships via Portal Hosting CD (version tag).
