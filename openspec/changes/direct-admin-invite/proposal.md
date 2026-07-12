## Why

Org owners regularly receive out-of-band requests (Slack, email) to add someone as an admin, but the current flow requires the target user to initiate — opening the join link and submitting a request that the owner must then approve. This two-sided, multi-step dance creates friction every time a known person needs access.

## What Changes

- Owners can type an email address in Admin Settings to create a pre-approved invite
- A new `orgs/{orgID}/pending-invites/{email}` Firestore subcollection stores dormant invites
- When the invited user navigates to an org page with a pending invite, a confirmation dialog is shown; accepting claims the invite: the user is written directly to `active-admins/{uid}`, admin controls appear immediately (no page reload), and a snackbar confirms the promotion
- Owners can cancel a pending invite before it is claimed
- The existing request/approve flow is unchanged for users who self-join via the join link

## Capabilities

### New Capabilities

- `admin-invite`: Email-based pre-approved admin invite — owner initiates, user auto-claims on next sign-in

### Modified Capabilities

- `data-model`: New `pending-invites/{email}` subcollection on org documents and corresponding Firestore security rules

## Impact

- **`roombooker_core`**: `OrgRepo` — new `addAdminInvite`, `cancelAdminInvite`, `hasPendingInviteForOrg`, `claimInviteForOrg` (returns bool), `claimPendingInvites` (unused by portal, retained for potential future use), and `pendingInvites` stream methods; `UserProfile.fromJson` — null-safe `orgIDs` parsing; `UserRepo.addOrg` — return type changed from `void` to `Future<void>` for proper error propagation
- **`roombooker_portal`**: `AdminWidget` — new "Invite by Email" input and pending invites list section; `OrgState` — mutable `currentUserIsAdmin` with `updateAdminStatus()` + `notifyListeners()`; `OrgStateProvider` — post-load dialog that checks for a pending invite and claims it on user acceptance, with live admin status update and snackbar confirmation
- **Firestore rules**: three distinct changes — (1) `orgs/{orgID}/pending-invites/{email}` subcollection rule (admin-only create, email-match delete); (2) collectionGroup wildcard rule for claim lookup; (3) `active-admins/{userID}` self-claim create exception gated on a valid pending invite
- **Firestore indexes**: single-field `fieldOverrides` entry for `pending-invites.email` with `COLLECTION_GROUP` scope (composite index is rejected by Firebase for single-field queries)
- No new packages required
