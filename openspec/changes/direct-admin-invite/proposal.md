## Why

Org owners regularly receive out-of-band requests (Slack, email) to add someone as an admin, but the current flow requires the target user to initiate — opening the join link and submitting a request that the owner must then approve. This two-sided, multi-step dance creates friction every time a known person needs access.

## What Changes

- Owners can type an email address in Admin Settings to create a pre-approved invite
- A new `orgs/{orgID}/pending-invites/{email}` Firestore subcollection stores dormant invites
- When the invited user signs in (Google or email/password), the invite is auto-claimed: they are written directly to `active-admins/{uid}` with no owner approval step
- Cold-start with an existing session also triggers the claim (via `LandingViewModel`)
- Owners can cancel a pending invite before it is claimed
- The existing request/approve flow is unchanged for users who self-join via the join link

## Capabilities

### New Capabilities

- `admin-invite`: Email-based pre-approved admin invite — owner initiates, user auto-claims on next sign-in

### Modified Capabilities

- `data-model`: New `pending-invites/{email}` subcollection on org documents and corresponding Firestore security rules

## Impact

- **`roombooker_core`**: `OrgRepo` — new `addAdminInvite`, `cancelAdminInvite`, `claimPendingInvites`, and `pendingInvites` stream methods
- **`roombooker_portal`**: `AdminWidget` — new "Invite by Email" input and pending invites list section; `auth.dart` — claim call in `AuthStateChangeAction<SignedIn>` and `<UserCreated>`; `LandingViewModel` — claim call in `init()`
- **Firestore rules**: three distinct changes — (1) `orgs/{orgID}/pending-invites/{email}` subcollection rule (admin-only create, email-match delete); (2) collectionGroup wildcard rule for claim lookup; (3) `active-admins/{userID}` self-claim create exception gated on a valid pending invite
- No new packages required
