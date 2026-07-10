## 1. Firestore Rules

- [ ] 1.1 Add `pending-invites/{email}` match block inside `match /orgs/{orgID}` in `firestore.rules`: `allow read` if `isAdmin() || request.auth.token.email == email`; `allow create` if `isAdmin()`; `allow delete` if `isAdmin() || request.auth.token.email == email`
- [ ] 1.2 Add top-level collectionGroup wildcard rule `match /{path=**}/pending-invites/{email}`: `allow read` if `isAuthenticated() && resource.data.email == request.auth.token.email`
- [ ] 1.3 Update `active-admins/{userID}` write rule to add self-claim exception: `allow write: if isAdmin() || (request.auth.uid == userID && exists(/databases/$(database)/documents/orgs/$(orgID)/pending-invites/$(request.auth.token.email)))`
- [ ] 1.4 Deploy updated rules via `firebase deploy --only firestore:rules`

## 2. Core — OrgRepo

- [ ] 2.1 Add `addAdminInvite(String orgID, String email)` to `OrgRepo`: normalise email to lowercase, write `orgs/{orgID}/pending-invites/{email}` with `{ email, invitedAt }`
- [ ] 2.2 Add `cancelAdminInvite(String orgID, String email)` to `OrgRepo`: delete `orgs/{orgID}/pending-invites/{email}`
- [ ] 2.3 Add `pendingInvites(String orgID)` stream to `OrgRepo`: snapshot listener on `orgs/{orgID}/pending-invites`, returns list of email strings
- [ ] 2.4 Add `claimPendingInvites()` to `OrgRepo`: collectionGroup query `pending-invites` where `email == currentUser.email`; for each result, run a transaction that writes `active-admins/{uid}` (with the email and timestamp) and adds the orgID to the user profile, then deletes the invite doc; entire method is a no-op if no results found
- [ ] 2.5 Add analytics events: `AdminInviteCreated`, `AdminInviteCancelled`, `AdminInviteClaimed`

## 3. Core — Tests

- [ ] 3.1 Unit tests for `addAdminInvite`: creates doc, normalises email, idempotent on duplicate
- [ ] 3.2 Unit tests for `cancelAdminInvite`: removes orgID from array, deletes doc when array is empty
- [ ] 3.3 Unit tests for `claimPendingInvites`: claims all orgIDs in transaction, no-op when no invite exists, already-active-admin is handled without error
- [ ] 3.4 Unit tests for `pendingInvites` stream: returns emails for matching orgs

## 4. Portal — Auth Hooks

- [ ] 4.1 In `auth.dart` `AuthStateChangeAction<SignedIn>`: after creating/checking the user profile, call `orgRepo.claimPendingInvites()` (fire-and-forget, do not await)
- [ ] 4.2 In `auth.dart` `AuthStateChangeAction<UserCreated>`: add the same `claimPendingInvites()` fire-and-forget call before navigation
- [ ] 4.3 Access `OrgRepo` in both actions via `Provider.of<OrgRepo>(context, listen: false)`

## 5. Portal — LandingViewModel

- [ ] 5.1 In `LandingViewModel.init()`, call `_orgRepo.claimPendingInvites()` as fire-and-forget (unawaited) before `_handleInitialNavigation()`
- [ ] 5.2 Update `LandingViewModel` constructor to accept `OrgRepo` (it already does — verify no change needed)

## 6. Portal — AdminWidget UI

- [ ] 6.1 Add "Pending Invites" subsection to `AdminWidget` — stream from `repo.pendingInvites(org.id!)`, show email list with cancel icon per entry, show empty state text when none
- [ ] 6.2 Add "Invite by Email" input row below the Pending Invites list: `TextField` for email + "Invite" button; validate non-empty and contains `@` before calling `repo.addAdminInvite`; clear field on success
- [ ] 6.3 Show a `SnackBar` confirmation on successful invite creation

## 7. Portal — Tests

- [ ] 7.1 Widget test for `AdminWidget`: pending invites list renders emails and cancel button; empty state shown when none
- [ ] 7.2 Widget test for invite input: submit with valid email calls `addAdminInvite`; submit with invalid email shows validation error; field cleared on success
- [ ] 7.3 Update existing `admin_widget_test.dart` if the widget signature or dependencies change
