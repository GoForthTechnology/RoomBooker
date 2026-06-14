## Why

The Kiosk currently operates as a fully unauthenticated Firestore client:
the `kiosks/{deviceID}` rule allows open read/write, and reads/writes to
`PrivateRequestDetails` and `confirmed-requests` require org-wide
`isAdmin()`. This blocks Phase 4's "Tactical Hub" requirements, which need
the Kiosk to (a) read meeting details for its own room only (REQ-13) and
(b) write auto-confirmed "Quick Book" requests for its own room only
(REQ-17, to land in a follow-up change). Without a trusted, room-scoped
identity, neither can be implemented securely.

## What Changes

- Kiosk signs in with Firebase Anonymous Auth on first launch, giving it a
  stable `request.auth.uid`.
- During activation, a new callable Cloud Function `claimKioskGrant`
  validates the existing 6-digit activation code and writes a grant
  document at `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}` (containing
  `deviceID` and `createdAt`), then deletes the activation code.
- A new callable Cloud Function `revokeKioskGrant` deletes that grant
  document; the Kiosk calls it as part of the existing de-provisioning
  flow.
- New Firestore rule helper `isAuthorizedKiosk(orgID, roomID)` checks for
  the existence of the caller's grant document.
- `request-details/{requestID}` read access is extended: an authorized
  kiosk may read the record for its own room (resolved via the sibling
  `confirmed-requests/{requestID}.roomID`).
- `confirmed-requests/{requestID}` create access is extended: an
  authorized kiosk may create a request whose `roomID` matches its grant.
- `kiosk-grants/{uid}` is readable by org admins (Portal visibility),
  writable only via the Admin SDK (Cloud Functions).
- **BREAKING (internal/unused)**: remove the dead `KioskIdentity` entity,
  `ProvisioningService.registerKiosk()`, and the open
  `orgs/{orgID}/kiosks/{deviceID}` Firestore rule
  (`allow read, write: if true`) — none of this is currently called, and
  the open rule is superseded by `kiosk-grants`.

## Capabilities

### New Capabilities
- `kiosk-access-control`: Defines the Kiosk's room-scoped Firebase Auth
  identity (anonymous auth + `kiosk-grants` document), the
  `claimKioskGrant`/`revokeKioskGrant` Cloud Functions, and the Firestore
  rules that grant a Kiosk scoped access to `PrivateRequestDetails` and
  `confirmed-requests` for its own room.

### Modified Capabilities
- `kiosk-provisioning`: Activation now also establishes the Kiosk's
  Firebase Auth identity and grant document (via `claimKioskGrant`), and
  de-provisioning now also revokes that grant (via `revokeKioskGrant`).

## Impact

- `functions/`: new callable functions `claimKioskGrant`,
  `revokeKioskGrant`; new/updated `firestore.rules` and rules tests.
- `packages/roombooker_kiosk/`: anonymous sign-in on launch; activation
  flow calls `claimKioskGrant`; de-provisioning flow calls
  `revokeKioskGrant`.
- `packages/roombooker_core/`: remove `KioskIdentity` entity and
  `ProvisioningService.registerKiosk()`.
- No changes to how `PrivateRequestDetails` documents are structured or
  stored.
- Follow-up (not in this change, tracked in `PROGRAM_PLAN.md`): Portal
  admin UI to show, per room, whether a Kiosk is attached using the new
  `kiosk-grants` metadata.
