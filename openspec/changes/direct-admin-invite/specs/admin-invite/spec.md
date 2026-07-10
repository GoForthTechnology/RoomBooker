## ADDED Requirements

### Requirement: Owner can invite a user by email
An org owner or active admin SHALL be able to enter an email address in the Admin Settings screen to pre-approve that address as an admin. The invite SHALL be stored as a pending invite and SHALL take effect the next time the user with that email signs in or cold-starts the app.

#### Scenario: Owner submits a valid email invite
- **WHEN** an owner enters a valid email address and confirms the invite in Admin Settings
- **THEN** a pending invite document is created for that email containing the org ID
- **AND** the email appears in the Pending Invites list in Admin Settings

#### Scenario: Owner submits a duplicate invite for the same email
- **WHEN** an owner enters an email that already has a pending invite for the same org
- **THEN** the system SHALL silently succeed (idempotent), not duplicate the entry

#### Scenario: Owner submits an empty or invalid email
- **WHEN** an owner submits an empty string or a string without `@`
- **THEN** the system SHALL reject the input with a validation error before writing to Firestore

### Requirement: Pending invites are visible and cancellable
The Admin Settings screen SHALL display a list of pending (unclaimed) invites for the org. An owner or active admin SHALL be able to cancel any pending invite before it is claimed.

#### Scenario: Owner views pending invites
- **WHEN** an owner opens the Administrators section of Admin Settings
- **THEN** all unclaimed pending invites for that org are listed with the invited email address

#### Scenario: Owner cancels a pending invite
- **WHEN** an owner taps the cancel action on a pending invite
- **THEN** the pending invite document at `orgs/{orgID}/pending-invites/{email}` is deleted
- **AND** the email no longer appears in the Pending Invites list

#### Scenario: No pending invites exist
- **WHEN** there are no unclaimed invites for the org
- **THEN** the Pending Invites section SHALL display an empty state message

### Requirement: Invite is auto-claimed on sign-in
When a user completes sign-in (Google or email/password), the system SHALL check for a pending invite matching their email. If one is found, the invite SHALL be claimed automatically: the user is written to `active-admins/{uid}` for each invited org, the org is added to their user profile, and the pending invite document is deleted.

#### Scenario: Invited user signs in with Google
- **WHEN** a user with a pending invite signs in via Google Sign-In
- **THEN** the invite is claimed during the sign-in action
- **AND** the user appears as an active admin in the invited org without any additional steps

#### Scenario: Invited user signs in with email/password
- **WHEN** a user with a pending invite signs in via email and password
- **THEN** the invite is claimed during the sign-in action
- **AND** the user appears as an active admin in the invited org

#### Scenario: First-time registration by invited user
- **WHEN** a user with a pending invite creates a new account (Google or email/password)
- **THEN** the invite is claimed during account creation
- **AND** the user appears as an active admin in the invited org

#### Scenario: Invite created before user has a Firebase account
- **WHEN** an admin creates an invite for an email address that has no Firebase account yet
- **THEN** the pending invite document is stored and remains dormant
- **AND** the invite is claimed when the user eventually creates an account and completes sign-in

#### Scenario: No pending invite exists at sign-in
- **WHEN** a user signs in and there is no pending invite for their email
- **THEN** sign-in proceeds normally with no side effects

### Requirement: Invite is auto-claimed on cold start with existing session
When a user opens the app with an existing authenticated session (no login screen shown), the system SHALL check for a pending invite on the landing screen and claim it if found.

#### Scenario: User cold-starts app with a pending invite
- **WHEN** a user who is already logged in opens the app cold
- **THEN** the landing screen checks for a pending invite for their email
- **AND** if found, the invite is claimed before or alongside the initial navigation

#### Scenario: Claim does not block navigation
- **WHEN** a pending invite is claimed on cold start
- **THEN** the claim SHALL be initiated fire-and-forget so it does not delay the redirect to the last-opened org

### Requirement: Invite claim is transactional and idempotent
The claim operation SHALL use a Firestore transaction to atomically read the pending invite and write to `active-admins`. Repeating the claim for an already-active admin SHALL be a no-op.

#### Scenario: Claim for a single org completes atomically
- **WHEN** `claimPendingInvites` is called and a pending invite exists for one org
- **THEN** the write to `active-admins/{uid}` and the deletion of the pending invite doc for that org occur in a single Firestore transaction

#### Scenario: Claim for multiple orgs processes each independently
- **WHEN** `claimPendingInvites` is called and pending invites exist for two orgs
- **THEN** each org's claim runs as a separate transaction
- **AND** a failure on the second org's transaction leaves the first org's claim intact and the second org's invite preserved for retry

#### Scenario: User is already an active admin
- **WHEN** `claimPendingInvites` is called but the user is already in `active-admins`
- **THEN** no error is thrown and no data is corrupted
