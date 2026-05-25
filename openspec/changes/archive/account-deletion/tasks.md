# Tasks: Account Deletion

## Phase 1: Core Logic
- [x] 1.1 Implement `deleteUserData` in `UserRepo`.
- [x] 1.2 Implement `deleteAccount` in `AuthService`.
- [x] 1.3 Add a unit test for `deleteUserData` ensuring all collections are cleaned.

## Phase 2: UI Implementation
- [x] 2.1 Create a "Delete Account" confirmation dialog.
- [x] 2.2 Integrate the dialog into the `SettingsAction` on the `LandingScreen`.
- [x] 2.3 Handle re-authentication if required by Firebase (users often need a fresh login to delete their account).

## Phase 3: Web & Documentation
- [x] 3.1 Create `web/delete-account.html`.
- [x] 3.2 Add a link to the deletion instructions in the `privacy.html` footer.
- [x] 3.3 Deploy the web updates to Firebase Hosting.

## Phase 4: Verification
- [x] 4.1 Verify that deleting an account removes the `users` document.
- [x] 4.2 Verify that all bookings associated with the email are removed.
- [x] 4.3 Verify that the Auth user is deleted.
