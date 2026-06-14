## 1. Cloud Functions: Grant Lifecycle

- [x] 1.1 Add `claimKioskGrant` callable function in `functions/index.js`:
      requires `context.auth`, validates `provisioning_codes/{code}`
      (exists, unexpired), writes
      `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}` with
      `{deviceID, createdAt: serverTimestamp()}`, deletes the activation
      code, returns `{orgID, roomID, orgName, roomName}`.
- [x] 1.2 Add `revokeKioskGrant` callable function in `functions/index.js`:
      requires `context.auth`, deletes
      `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}` (idempotent if
      missing).
- [x] 1.3 Add unit tests for `claimKioskGrant` and `revokeKioskGrant` in
      `functions/test/kiosk_grants.test.js` (valid code, expired code,
      missing code, unauthenticated caller, idempotent revoke).

## 2. Firestore Rules

- [x] 2.1 Add `isAuthorizedKiosk(orgID, roomID)` helper checking
      `exists(/databases/$(database)/documents/orgs/$(orgID)/rooms/$(roomID)/kiosk-grants/$(request.auth.uid))`.
- [x] 2.2 Add rules for `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}`:
      `allow read: if isAdmin()`, `allow write: if false`.
- [x] 2.3 Extend `request-details/{requestID}` read rule to allow
      `isAuthorizedKiosk(orgID, roomID)` where `roomID` is read via `get()`
      on the sibling `confirmed-requests/{requestID}`.
- [x] 2.4 Extend `confirmed-requests/{requestID}` create rule to allow
      `isAuthorizedKiosk(orgID, incomingData().roomID)`.
- [x] 2.5 Remove the `orgs/{orgID}/kiosks/{deviceID}` match block
      (`allow read, write: if true`).
- [x] 2.6 Add/extend `functions/test/firestore.rules.test.js` covering:
      kiosk with valid grant can read its room's `request-details` and
      create `confirmed-requests` for its room; kiosk is denied for other
      rooms; unauthenticated/no-grant clients denied; admins unaffected;
      `kiosk-grants` not writable by clients.

## 3. roombooker_core: Provisioning Service & Cleanup

- [x] 3.1 Add `ProvisioningService.claimKioskGrant({code, deviceID})` and
      `ProvisioningService.revokeKioskGrant({orgID, roomID})` wrapping
      `cloud_functions` callable invocations; add `cloud_functions`
      dependency to `roombooker_core/pubspec.yaml`.
- [x] 3.2 Remove `ProvisioningService.consumeActivationCode()` and
      `ProvisioningService.registerKiosk()`.
- [x] 3.3 Delete `KioskIdentity` entity (`kiosk_identity.dart`,
      `kiosk_identity.g.dart`) and any exports/references.
- [x] 3.4 Update/remove unit tests referencing the removed
      `consumeActivationCode`, `registerKiosk`, and `KioskIdentity`.

## 4. Kiosk App: Anonymous Auth & Device ID

- [x] 4.1 Add `cloud_functions` dependency to
      `packages/roombooker_kiosk/pubspec.yaml`.
- [x] 4.2 On app start (`main.dart`), if no Firebase Auth user exists,
      call `FirebaseAuth.instance.signInAnonymously()` before showing
      `ProvisioningGuard`.
- [x] 4.3 Generate a persistent `deviceID` (e.g. via `uuid` package) on
      first launch if not already present in secure storage; add `uuid`
      dependency.

## 5. Kiosk App: Activation & De-provisioning Flows

- [x] 5.1 Update `_ProvisioningScreenState._submit()` to call
      `ProvisioningService.claimKioskGrant({code, deviceID})` instead of
      `consumeActivationCode`, and persist the returned `roomID`/`orgID`
      on success.
- [x] 5.2 Update the "DE-PROVISION TERMINAL" handler in `main.dart` to call
      `ProvisioningService.revokeKioskGrant({orgID, roomID})` before
      clearing secure storage and navigating back to `ProvisioningGuard`.
- [x] 5.3 Handle `claimKioskGrant`/`revokeKioskGrant` failures with
      user-visible error messages (mirroring existing error handling in
      `_submit()`).

## 6. Validation

- [x] 6.1 Run `(cd functions && npm test)`.
- [x] 6.2 Run `(cd packages/roombooker_core && flutter test)`.
- [x] 6.3 Run `(cd packages/roombooker_kiosk && flutter test)`.
- [x] 6.4 Run `flutter analyze` across affected packages.
- [x] 6.5 Run `/flutter-smoke-test` (or manual smoke check) for the Kiosk
      app to confirm anonymous sign-in + provisioning screen still boot
      correctly.
