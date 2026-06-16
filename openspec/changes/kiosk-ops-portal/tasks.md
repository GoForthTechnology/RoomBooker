## 1. Cloud Function — adminRevokeKioskGrant

- [x] 1.1 Add `adminRevokeKioskGrant` to `functions/index.js`: verify
      caller is org admin or owner (check `active-admins/{uid}` and
      org `ownerID`), then delete all docs in
      `orgs/{orgID}/rooms/{roomID}/kiosk-grants/` using Admin SDK,
      return `{ success: true }`.

## 2. Core — KioskGrantRecord entity and ProvisioningService methods

- [x] 2.1 Add `KioskGrantRecord` class to
      `packages/roombooker_core/lib/data/entities/kiosk_grant.dart`
      with fields: `uid` (String), `deviceID` (String?),
      `createdAt` (DateTime?), and a `fromSnapshot` factory.
- [x] 2.2 Add `listKioskGrants(orgID, roomID)` to `ProvisioningService`
      returning `Stream<List<KioskGrantRecord>>` by listening to
      `orgs/{orgID}/rooms/{roomID}/kiosk-grants`.
- [x] 2.3 Add `adminRevokeKioskGrant(orgID, roomID)` to
      `ProvisioningService` that calls the new Cloud Function.
- [x] 2.4 Export `KioskGrantRecord` from `roombooker_core.dart`.

## 3. Portal UI — Room list Kiosk status section

- [x] 3.1 In `room_list_widget.dart`, replace the static "Provision
      Kiosk" `IconButton` with a `StreamBuilder<List<KioskGrantRecord>>`
      on `provisioningService.listKioskGrants(org.id!, room.id!)`.
- [x] 3.2 When stream is empty: render the existing "Link Kiosk"
      icon button (no behaviour change).
- [x] 3.3 When stream has exactly one grant: render a small info row
      showing device ID (first 8 chars + "…") and provisioned date
      (`DateFormat('MMM d, y').format(grant.createdAt)`), plus a
      red "Revoke" icon button (`Icons.link_off`).
- [x] 3.4 When stream has more than one grant: render "Multiple devices"
      warning text and a single "Revoke All" icon button.
- [x] 3.5 "Revoke" / "Revoke All" button shows a confirmation
      `AlertDialog` ("This will disconnect the Kiosk from this room.
      The device will lose access on its next interaction.") with
      Cancel and Confirm actions. On confirm, call
      `provisioningService.adminRevokeKioskGrant(org.id!, room.id!)`
      and show a SnackBar on error.

## 4. Tests

- [x] 4.1 Unit test `adminRevokeKioskGrant` in
      `provisioning_service_test.dart`: mock the callable, verify it
      is called with correct orgID and roomID.
- [x] 4.2 Unit test `listKioskGrants` in `provisioning_service_test.dart`:
      seed FakeFirebaseFirestore with a `kiosk-grants` doc, verify the
      stream emits a `KioskGrantRecord` with the correct fields.

## 5. Validation

- [x] 5.1 Run `flutter test` for `roombooker_core` and `roombooker_portal`
      — all pass.
- [x] 5.2 Run `flutter analyze` — no issues.
- [ ] 5.3 Manually verify in Portal: room with no grant shows "Link
      Kiosk" button; provisioned room shows device ID + date + Revoke;
      revoking updates UI and the Kiosk loses write access on next
      Quick Book attempt.
