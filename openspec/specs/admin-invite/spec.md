# Admin Invite Specification: Room Booker

## Requirements

### Requirement: Owner can invite a user by email
An org owner or active admin SHALL be able to enter an email address in the Admin Settings screen to pre-approve that address as an admin. The invite SHALL be stored as a pending invite and SHALL take effect the next time the user with that email signs in or cold-starts the app. Upon creation of the pending invite, the system SHALL send a notification email to the invited address (see `admin-invite-email` spec).

#### Scenario: Owner submits a valid email invite
- **WHEN** an owner enters a valid email address and confirms the invite in Admin Settings
- **THEN** a pending invite document is created for that email containing the org ID
- **AND** the email appears in the Pending Invites list in Admin Settings
- **AND** a notification email is sent to the invited address

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

### Requirement: Invite is claimed via confirmation dialog on org page load
When a signed-in user navigates to an org page that has a pending invite for their email, a confirmation dialog SHALL be shown. The user must explicitly accept before the invite is claimed.

#### Scenario: Invited user navigates to the org page
- **WHEN** a signed-in user with a pending invite for org `orgABC` navigates to that org's booking page
- **THEN** a dialog is shown explaining they have been invited to become an administrator
- **AND** the dialog offers Accept and Decline buttons

#### Scenario: User accepts the invitation
- **WHEN** the user taps Accept in the invite dialog
- **THEN** `claimInviteForOrg` is called for that org
- **AND** if the invite still exists, the user is written to `active-admins/{uid}`, the pending invite is deleted, and the org is added to their user profile
- **AND** admin controls appear immediately without a page reload
- **AND** a snackbar confirms "You are now an admin of `<org name>`"

#### Scenario: User declines the invitation
- **WHEN** the user taps Decline in the invite dialog
- **THEN** the dialog closes and no claim is made
- **AND** the pending invite document remains in Firestore
- **AND** the dialog will appear again the next time the user loads that org's page

#### Scenario: Invite cancelled between dialog display and accept
- **WHEN** the owner cancels the invite after the dialog is already showing and the user clicks Accept
- **THEN** `claimInviteForOrg` finds the invite document gone and returns false
- **AND** a snackbar "Invitation is no longer available" is shown
- **AND** no admin entry is written and no analytics event is fired

#### Scenario: No pending invite exists when org page loads
- **WHEN** a user navigates to an org page and has no pending invite for that org
- **THEN** no dialog is shown and the page loads normally

#### Scenario: Invite created before user has a Firebase account
- **WHEN** an admin creates an invite for an email address that has no Firebase account yet
- **THEN** the pending invite document is stored and remains dormant
- **AND** the invite dialog appears when the user eventually creates an account and navigates to that org's page

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
