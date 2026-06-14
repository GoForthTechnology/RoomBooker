## Context

The Kiosk app (`packages/roombooker_kiosk`) currently authenticates as
nothing: it calls Firestore directly with no Firebase Auth session. The
6-digit activation handshake (`provisioning_codes/{code}`) is read and
deleted entirely client-side, with rules `allow get/create/delete: if true`
on that collection. Once activated, the Kiosk persists `roomID`/`orgID` to
`flutter_secure_storage` and reads/writes Firestore as an anonymous,
unauthenticated client.

Firestore rules currently gate `request-details` (= `PrivateRequestDetails`)
and writes to `confirmed-requests` behind `isAdmin()`, which is org-wide
(checked via `active-admins/{userID}`). There is no concept of "this caller
is a Kiosk for room X."

A `KioskIdentity` entity and `ProvisioningService.registerKiosk()` exist in
`roombooker_core` but are never called — dead scaffolding from an earlier
pass, writing to an `orgs/{orgID}/kiosks/{deviceID}` collection that is also
governed by an open `allow read, write: if true` rule.

This change establishes a trusted, room-scoped identity for the Kiosk,
mirroring the existing `isAdmin()` / `active-admins/{userID}` pattern but
scoped to a single room rather than the whole org.

## Goals / Non-Goals

**Goals:**
- Give each Kiosk device a stable `request.auth.uid` via Firebase
  Anonymous Auth.
- Establish a server-validated link between that `uid` and a specific
  `(orgID, roomID)`, recorded as `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}`.
- Add an `isAuthorizedKiosk(orgID, roomID)` rule helper and use it to grant
  the Kiosk read access to `request-details` and create access to
  `confirmed-requests`, scoped to its own room.
- Ensure de-provisioning revokes the grant.
- Remove the dead `KioskIdentity`/`registerKiosk`/open `kiosks/{deviceID}`
  rule.
- Leave enough metadata on the grant doc (`deviceID`, `createdAt`) for a
  future Portal "kiosk attached?" view (not built in this change).

**Non-Goals:**
- No changes to `PrivateRequestDetails`'s storage location or schema
  (separate from the `meetingUrl` privacy-guard change).
- No "Quick Book" / instant-booking write logic (follow-up change; this
  change only makes the *rule* exist for `confirmed-requests` creation by
  an authorized kiosk).
- No Portal UI changes (the future "kiosk attached" admin view is tracked
  in `PROGRAM_PLAN.md` as a follow-up).
- No changes to the activation **code generation** side (Portal's "Link
  Kiosk" flow / `createActivationCode`) beyond what's needed for the Kiosk
  to call the new claim function.

## Decisions

### 1. Anonymous Auth + Firestore "grant" doc, not custom-claims tokens

We considered minting a Firebase custom token with `{orgID, roomID, role}`
claims via `admin.auth().createCustomToken()`. Rejected because developer
claims on a custom token only apply to the *first* ID token from that
sign-in — persisting them across token refresh requires also calling
`setCustomUserClaims()` on a real user record, plus the client must force
an ID-token refresh after sign-in to pick the claims up. That's more moving
parts and a subtler failure mode (stale claims) than needed.

Instead: the Kiosk calls `signInAnonymously()` once (uid persists across
restarts via Firebase Auth's local persistence). Authorization is recorded
as a Firestore document `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}`,
and rules check `exists()` on that doc — exactly the pattern already used
for `isAdmin()` via `active-admins/{userID}`. No custom claims, no token
refresh timing issues, and the existing rules-test harness
(`functions/test/firestore.rules.test.js`) already knows how to test
`exists()`-based rules.

### 2. Grant creation/deletion happens via Cloud Functions, not client rules

The activation code is the "secret" that authorizes creating a grant. We
can't safely let the client write `kiosk-grants/{uid}` directly and also
validate+consume the code in the same atomic step using rules alone
without significant complexity (multi-doc `existsAfter()` rules). Instead:

- `claimKioskGrant({code})` (callable, requires `context.auth` — i.e. the
  Kiosk must already be signed in anonymously): validates the code exists
  and is unexpired, reads `roomID`/`orgID`/`roomName`/`orgName`, writes
  `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{context.auth.uid}` with
  `{deviceID, createdAt: serverTimestamp()}`, deletes the activation code,
  and returns `{orgID, roomID, roomName, orgName}` to the Kiosk.
- `revokeKioskGrant({orgID, roomID})` (callable, requires `context.auth`):
  deletes `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{context.auth.uid}`.

Both run with Admin SDK privileges (bypass rules), so `kiosk-grants` itself
needs no client write rule at all (`allow write: if false`).

`deviceID` here is a client-generated identifier (already used for display
in the existing "Device Info" dialog per the kiosk-provisioning spec) sent
as part of the `claimKioskGrant` payload, purely for admin-facing display —
it is not used for any security decision (the `uid` is).

### 3. `request-details` stays a flat per-org collection

Rather than restructuring `PrivateRequestDetails` under
`rooms/{roomID}/...` (a much larger migration), the read rule for
`request-details/{requestID}` does a `get()` on the sibling
`confirmed-requests/{requestID}` to find its `roomID`, then checks
`isAuthorizedKiosk(orgID, thatRoomID)`. This is one extra `get()` per rule
evaluation — acceptable given Kiosk read volume (one room's active meeting,
polled occasionally).

### 4. Replace, don't wrap, the client-side code consumption

`ProvisioningService.consumeActivationCode()` currently does the
read-and-delete of `provisioning_codes/{code}` directly from the client.
`claimKioskGrant` takes over consuming the code (server-side), so the
Activation screen's flow becomes: `signInAnonymously()` (if not already
signed in) → call `claimKioskGrant({code})` → persist returned
`roomID`/`orgID` to secure storage. The old client-side
`consumeActivationCode` path is removed to avoid two ways to consume a
code.

The `provisioning_codes/{code}` rules (`allow get/create/delete`) stay as
they are — `claimKioskGrant` runs via Admin SDK and bypasses rules, but
`createActivationCode` (Portal side) still writes the doc as an
authenticated admin client, so its existing rules remain correct.

### 5. Dead-code removal bundled into this change

`KioskIdentity`, `KioskIdentity.g.dart`,
`ProvisioningService.registerKiosk()`, and the
`orgs/{orgID}/kiosks/{deviceID}` rule (`allow read, write: if true`) are
removed. This is directly adjacent to the rules file being edited, has no
callers, and closes an open-write hole in production rules.

## Risks / Trade-offs

- **[Risk]** Anonymous Auth sign-in could be lost (e.g. app data cleared)
  without de-provisioning, leaving a stale `kiosk-grants/{uid}` entry. →
  **Mitigation**: stale grants are harmless (no device holds that uid's
  session anymore) and are visible to admins via the Portal's future
  "kiosk attached" view; an admin can manually trigger de-provisioning /
  the grant can be cleaned up by re-provisioning the room, which calls
  `revokeKioskGrant` for the *new* anon uid's room only — a separate
  manual cleanup function for orphaned grants is left as a future
  enhancement, not blocking this change.
- **[Risk]** Extra `get()` in the `request-details` rule adds a read per
  rule evaluation. → **Mitigation**: Kiosk read volume is low (single
  room, infrequent polling); acceptable cost.
- **[Trade-off]** No org-wide Kiosk permissions — each room requires its
  own grant. This is intentional (principle of least privilege) and
  matches REQ-13/REQ-20's "scoped to its assigned room" language.
- **[Risk]** Removing `kiosks/{deviceID}` open rule is technically a
  breaking rules change for any out-of-band tooling that might depend on
  it. → **Mitigation**: confirmed unused via grep across the codebase; no
  app code references it.

## Migration Plan

1. Deploy `firestore.rules` changes (additive: new `kiosk-grants`
   collection + rules, new helper, extended `request-details` /
   `confirmed-requests` rules) alongside removal of the
   `kiosks/{deviceID}` rule.
2. Deploy `claimKioskGrant` / `revokeKioskGrant` Cloud Functions.
3. Ship updated Kiosk app (anonymous sign-in, new activation flow calling
   `claimKioskGrant`, de-provisioning calling `revokeKioskGrant`).
4. No data migration needed for already-provisioned devices: they
   continue working (still reading public `confirmed-requests`, and they
   don't yet rely on `request-details` access — that's only consumed once
   a follow-up change adds the privacy-guard `meetingUrl` move and a UI
   that reads it). Existing devices will not have a `kiosk-grants` entry
   until they're re-activated; this is acceptable since no shipped feature
   depends on it yet. If desired, devices can be re-provisioned to backfill
   a grant — not required for this change to be safe to deploy.

Rollback: revert rules and Cloud Functions; Kiosk app rollback simply stops
calling the new functions (old client-side `consumeActivationCode` path
would need to be restored if rolling back the app independently of the
backend — call this out in the PR if a partial rollback is ever needed).

## Open Questions

- None blocking. The Portal "kiosk attached" admin view and a
  cleanup/expiry mechanism for orphaned `kiosk-grants` are explicitly
  deferred (tracked in `PROGRAM_PLAN.md`).
