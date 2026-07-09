## ADDED Requirements

### Requirement: pending-invites top-level collection
A top-level Firestore collection `pending-invites` SHALL exist, keyed by the invited user's email address (lowercase). Each document SHALL contain an `orgIDs` array listing orgs for which that email has a pending invite, and a `createdAt` timestamp.

#### Scenario: Document structure is valid
- **WHEN** an admin invite is created for `user@example.com` in org `orgABC`
- **THEN** `pending-invites/user@example.com` exists with `{ orgIDs: ["orgABC"], createdAt: <timestamp> }`

#### Scenario: Multi-org invite accumulates orgIDs
- **WHEN** the same email is invited to a second org `orgDEF`
- **THEN** `pending-invites/user@example.com` has `{ orgIDs: ["orgABC", "orgDEF"] }`

#### Scenario: Document is deleted when all org invites are cancelled or claimed
- **WHEN** the last orgID is removed from the `orgIDs` array
- **THEN** the `pending-invites/{email}` document is deleted

### Requirement: Firestore security rules for pending-invites
The `pending-invites/{email}` collection SHALL enforce the following access rules:
- A user MAY read their own pending invite document (matched by `request.auth.token.email == email`).
- Any authenticated user MAY write to the collection (authorization is enforced at the application layer).
- Unauthenticated users SHALL NOT read or write pending invite documents.

#### Scenario: User reads their own pending invite
- **WHEN** a signed-in user reads `pending-invites/{their-email}`
- **THEN** the read is permitted by Firestore rules

#### Scenario: User cannot read another user's pending invite
- **WHEN** a signed-in user attempts to read `pending-invites/{other-email}`
- **THEN** the read is denied by Firestore rules

#### Scenario: Unauthenticated read is denied
- **WHEN** an unauthenticated client attempts to read any `pending-invites` document
- **THEN** the read is denied by Firestore rules
