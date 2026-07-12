## ADDED Requirements

### Requirement: pending-invites subcollection under each org
Each org document SHALL have a `pending-invites` subcollection at `orgs/{orgID}/pending-invites/{email}`, where the document ID is the invited user's email address (lowercase). Each document SHALL contain an `email` field (string, lowercase, duplicates the document ID) and an `invitedAt` timestamp field.

#### Scenario: Document is created on invite
- **WHEN** an admin invites `user@example.com` to org `orgABC`
- **THEN** `orgs/orgABC/pending-invites/user@example.com` exists with `{ email: "user@example.com", invitedAt: <timestamp> }`

#### Scenario: Document ID is normalised to lowercase
- **WHEN** an admin creates an invite with email `User@Example.COM`
- **THEN** the document is written at `orgs/{orgID}/pending-invites/user@example.com` with `email: "user@example.com"`

#### Scenario: Document is removed on cancellation or claim
- **WHEN** an admin cancels the invite, or the invited user claims it
- **THEN** `orgs/{orgID}/pending-invites/{email}` is deleted

### Requirement: Firestore security rules for pending-invites subcollection
The `orgs/{orgID}/pending-invites/{email}` subcollection SHALL enforce the following access rules:
- An org owner or active admin SHALL be permitted to create or delete a pending invite document (via `isAdmin()`).
- The invited user (matched by `request.auth.token.email == email`) SHALL be permitted to delete their own pending invite document (to support claim cleanup).
- The invited user or any admin SHALL be permitted to read a pending invite document.
- Unauthenticated users and non-admin, non-invited users SHALL NOT read or write pending invite documents.

#### Scenario: Admin creates an invite
- **WHEN** an authenticated admin of org `orgABC` creates `orgs/orgABC/pending-invites/user@example.com`
- **THEN** the write is permitted

#### Scenario: Non-admin cannot create an invite
- **WHEN** an authenticated user who is not an admin of `orgABC` attempts to create `orgs/orgABC/pending-invites/user@example.com`
- **THEN** the write is denied

#### Scenario: Invited user deletes their own invite (claim cleanup)
- **WHEN** the authenticated user whose email is `user@example.com` deletes `orgs/orgABC/pending-invites/user@example.com`
- **THEN** the delete is permitted

#### Scenario: Unrelated user cannot delete an invite
- **WHEN** an authenticated user whose email is `other@example.com` (and who is not an admin) attempts to delete `orgs/orgABC/pending-invites/user@example.com`
- **THEN** the delete is denied

### Requirement: CollectionGroup read rule for claim lookup
A Firestore collectionGroup rule at `/{path=**}/pending-invites/{docID}` SHALL permit authenticated users to read any pending-invite document whose `email` field matches `request.auth.token.email`. This enables `claimPendingInvites()` to query across all orgs without knowing which orgs the user has been invited to.

#### Scenario: User queries pending invites across orgs
- **WHEN** a signed-in user performs `collectionGroup('pending-invites').where('email', '==', user.email)`
- **THEN** all `pending-invites` documents matching that email are returned regardless of which org they belong to

#### Scenario: User cannot read another user's pending invite via collectionGroup
- **WHEN** a signed-in user queries `collectionGroup('pending-invites').where('email', '==', 'other@example.com')`
- **THEN** no documents are returned (denied by the `resource.data.email == request.auth.token.email` rule condition)

### Requirement: active-admins self-claim rule
The `orgs/{orgID}/active-admins/{userID}` write rule SHALL permit a user to write their own entry when a valid pending invite exists for their email in that org. This is the mechanism by which `claimPendingInvites()` promotes an invite to active admin status without requiring prior admin rights.

The self-claim condition SHALL be: `request.auth.uid == userID AND exists(orgs/{orgID}/pending-invites/{request.auth.token.email})`. The `create`-only exception (not `write`) ensures an invited-but-not-yet-admin user cannot update or delete an existing `active-admins` entry.

#### Scenario: Invited user claims their invite
- **WHEN** a signed-in user with email `user@example.com` creates `orgs/orgABC/active-admins/{theirUID}` and `orgs/orgABC/pending-invites/user@example.com` exists
- **THEN** the write is permitted

#### Scenario: User cannot self-promote without a pending invite
- **WHEN** a signed-in user attempts to create `orgs/orgABC/active-admins/{theirUID}` and no pending invite exists for their email
- **THEN** the write is denied (unless they are already an admin via the existing `isAdmin()` rule)

#### Scenario: User cannot claim a different user's active-admins slot
- **WHEN** a signed-in user with email `user@example.com` attempts to create `orgs/orgABC/active-admins/{someOtherUID}` even if a pending invite for their email exists
- **THEN** the write is denied because `request.auth.uid != someOtherUID`
