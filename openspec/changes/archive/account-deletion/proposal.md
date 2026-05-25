# Proposal: User Account Deletion

## 1. Objective
Provide a way for users to delete their account and all associated data from the Room Booker application, satisfying Google Play Store requirements for data transparency and control.

## 2. Context
Google Play requires that if an app allows account creation, it must also provide a way to delete the account both within the app and via a web-based request. Currently, Room Booker uses Firebase Authentication and Firestore but lacks a deletion flow.

## 3. Proposed Changes
- **Flutter App**:
    - Add a "Delete Account" option in the `Settings` dialog or a new `Account` dialog.
    - Implement a `deleteAccount` method in `AuthService` and `UserRepo`.
    - The deletion logic will:
        1. Identify organizations owned by the user.
        2. Identify and delete all booking requests made by the user (using their email as the identifier in a Collection Group query).
        3. Remove the user's `UserProfile` document.
        4. Delete the user's Firebase Authentication account.
- **Web**:
    - Create a `web/delete-account.html` page providing instructions on how to request account deletion (or a link to the app if they still have it).
    - Deploy this page to Firebase Hosting.

## 4. Technical Details
- **Firestore Collection Group Query**: Use `_db.collectionGroup('request-details').where('email', isEqualTo: userEmail)` to find and delete all associated bookings across all organizations.
- **Organization Ownership**: Organizations owned by the user (`ownerID == uid`) will be orphaned. We should ideally delete them if they have no other admins, or simply remove the user's profile and let the org remain (though it will be unmanaged). *Decision: For this prototype, we will delete the UserProfile and leave the Org, but warn the user.*

## 5. Success Criteria
- A user can trigger account deletion from within the app.
- All Firestore data directly associated with the user's email/UID is removed.
- The user is logged out and their Auth account is disabled/deleted.
- A public URL exists for account deletion instructions.
