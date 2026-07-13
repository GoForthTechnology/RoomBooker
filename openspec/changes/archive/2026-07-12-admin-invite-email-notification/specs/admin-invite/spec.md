# Admin Invite Specification Delta

## MODIFIED Requirements

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
