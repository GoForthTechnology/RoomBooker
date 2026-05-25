# Design: Account Deletion Flow

## 1. UI Components
- **Account Action**: A "Delete Account" button will be added to the `SettingsAction` dialog in `lib/ui/screens/landing/landing.dart`.
- **Confirmation Dialog**: A modal will appear explaining that all data (bookings, profile) will be permanently removed. It will require a "DELETE" text confirmation to avoid accidental clicks.

## 2. Service & Repo Updates
### `AuthService`
- Add `Future<void> deleteAccount()`:
    - Calls `UserRepo.deleteUserData(uid, email)`.
    - Calls `FirebaseAuth.instance.currentUser?.delete()`.
    - Signs out the user.

### `UserRepo`
- Add `Future<void> deleteUserData(String uid, String email)`:
    - `batch.delete(_db.collection('users').doc(uid))`.
    - Query `collectionGroup('request-details').where('email', isEqualTo: email)`.
    - For each found document, delete it AND its parent `Request` document in the corresponding `orgs/{orgID}/{status-collection}/{requestID}`.

## 3. Web Instruction Page
- **Path**: `web/delete-account.html`
- **Content**:
    - Explanation of the data deletion policy.
    - Instructions for in-app deletion.
    - An email contact (`support@goforth.tech`) for manual deletion requests if the user no longer has access to the app.

## 4. Security Rules
- Ensure the user has permission to delete their own `UserProfile`.
- Ensure the user has permission to delete `request-details` and `Requests` where the email matches their authenticated email.

## 5. Deployment
- The page will be deployed via `firebase deploy --only hosting` as part of the standard web build.
