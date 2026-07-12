## 1. Firestore Rules

- [x] 1.1 Add `pending-invites/{email}` match block inside `match /orgs/{orgID}` in `firestore.rules`: `allow read` if `isAdmin() || request.auth.token.email == email`; `allow create` if `isAdmin()`; `allow delete` if `isAdmin() || request.auth.token.email == email`
- [x] 1.2 Add top-level collectionGroup wildcard rule `match /{path=**}/pending-invites/{email}`: `allow read` if `isAuthenticated() && resource.data.email == request.auth.token.email`
- [x] 1.3 Update `active-admins/{userID}` rule: split existing `allow write: if isAdmin()` into `allow create: if isAdmin() || (request.auth.uid == userID && exists(...pending-invites/$(request.auth.token.email)))` and `allow update, delete: if isAdmin()`
- [x] 1.4 Add `firestore.indexes.json` `fieldOverrides` entry for `pending-invites` collection, field `email`, with both `COLLECTION` and `COLLECTION_GROUP` ascending scope (single-field queries require `fieldOverrides`, not a composite index entry)
- [x] 1.5 Deploy updated rules and indexes: `firebase deploy --only firestore:rules,firestore:indexes`

## 2. Core — OrgRepo

- [x] 2.1 Add `addAdminInvite(String orgID, String email)` to `OrgRepo`: normalise email to lowercase, write `orgs/{orgID}/pending-invites/{email}` with `{ email, invitedAt }`
- [x] 2.2 Add `cancelAdminInvite(String orgID, String email)` to `OrgRepo`: delete `orgs/{orgID}/pending-invites/{email}`
- [x] 2.3 Add `pendingInvites(String orgID)` stream to `OrgRepo`: snapshot listener on `orgs/{orgID}/pending-invites`, returns list of email strings
- [x] 2.4 Add `claimPendingInvites()` to `OrgRepo`: collectionGroup query by email; for each result, transaction-writes `active-admins/{uid}` and deletes the invite doc; catch and log all errors internally
- [x] 2.5 Add `hasPendingInviteForOrg(String orgID)` to `OrgRepo`: reads `orgs/{orgID}/pending-invites/{email}` directly, returns bool
- [x] 2.6 Add `claimInviteForOrg(String orgID)` to `OrgRepo`: transaction reads invite, returns `false` if gone (race safety), writes `active-admins/{uid}` and deletes invite if present, returns `true`; fires `AdminInviteClaimed` analytics only when `true`
- [x] 2.7 Add analytics events: `AdminInviteCreated`, `AdminInviteCancelled`, `AdminInviteClaimed`
- [x] 2.8 Change `UserRepo.addOrg` return type from `void` to `Future<void>` for proper error propagation; wrap all `addOrg` calls inside transaction callbacks in try/catch to prevent propagation from aborting the surrounding transaction

## 3. Core — Data Model

- [x] 3.1 Fix `UserProfile.fromJson` to handle null/missing `orgIDs` field: use `(json['orgIDs'] as List<dynamic>?)?.map(...).toList() ?? []` instead of a hard cast that throws on null

## 4. Core — Tests

- [x] 4.1 Unit tests for `addAdminInvite`: creates doc with correct fields; normalises email to lowercase
- [x] 4.2 Unit tests for `cancelAdminInvite`: deletes the subcollection doc
- [x] 4.3 Unit tests for `claimPendingInvites`: claims each org; no-op when no invite; errors caught and do not propagate; normalises email
- [x] 4.4 Unit tests for `pendingInvites` stream

## 5. Portal — OrgState + OrgStateProvider

- [x] 5.1 Make `OrgState.currentUserIsAdmin` mutable: add `updateAdminStatus(bool)` that sets the field and calls `notifyListeners()`
- [x] 5.2 In `OrgStateProvider`, add `_maybeShowInviteDialog(OrgState orgState)`: calls `hasPendingInviteForOrg`, shows confirmation dialog if invite found, calls `claimInviteForOrg` on accept, calls `orgState.updateAdminStatus(true)` (not `_resolvedState?`) on success, shows snackbar
- [x] 5.3 Schedule `_maybeShowInviteDialog` via `WidgetsBinding.instance.addPostFrameCallback` after `FutureBuilder` resolves; gate with `_inviteCheckStarted` flag reset by `_loadState()`
- [x] 5.4 Remove `_subscribeToAdminStatus` / `activeAdmins` stream subscription from `OrgStateProvider` (was causing false-negative admin status for org owners)

## 6. Portal — AdminWidget UI

- [x] 6.1 Add "Pending Invites" subsection to `AdminWidget` — stream from `repo.pendingInvites(org.id!)`, show email list with cancel icon per entry, show empty state text when none
- [x] 6.2 Convert `AdminWidget` from `StatelessWidget` to `StatefulWidget` to manage `TextEditingController` lifecycle for the email input field
- [x] 6.3 Add "Invite by Email" input row: `TextField` for email + "Invite" button; validate non-empty and contains `@`; clear field on success
- [x] 6.4 Show a `SnackBar` confirmation on successful invite creation

## 7. Portal — Tests

- [ ] 7.1 Widget test for `AdminWidget`: pending invites list renders emails and cancel button; empty state shown when none
- [ ] 7.2 Widget test for invite input: submit with valid email calls `addAdminInvite`; submit with invalid email shows validation error; field cleared on success
- [ ] 7.3 Update existing `admin_widget_test.dart` if the widget signature or dependencies change
