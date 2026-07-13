# Admin Invite Email Specification

## ADDED Requirements

### Requirement: Invitee is notified by email when a pending invite is created
When a pending invite document is created at `orgs/{orgID}/pending-invites/{email}`, the system SHALL send a notification email to the invited address. The email SHALL include the name of the inviting org and a direct link to `<PORTAL_BASE_URL>/join/{orgID}` so the invitee can act immediately after signing in.

#### Scenario: Invite email is sent on document creation
- **WHEN** a pending invite document is written to `orgs/{orgID}/pending-invites/{email}`
- **THEN** a Cloud Function trigger fires and sends an email to the address in the document ID
- **AND** the email subject is "You've been invited to join <org name>"
- **AND** the email body names the org and includes a link to `<PORTAL_BASE_URL>/join/{orgID}`

#### Scenario: Org name is included in the email
- **WHEN** the trigger fires for org `orgABC` whose name is "St. Michael's"
- **THEN** the email body references "St. Michael's" by name

#### Scenario: Email delivery fails
- **WHEN** the `sendEmail` call throws an error (e.g., Firestore write fails)
- **THEN** the error is caught, logged, and the function completes without propagating the error
- **AND** the pending invite document remains in Firestore (email failure does not roll back the invite)

#### Scenario: Re-invite after cancellation sends a new email
- **WHEN** an owner cancels a pending invite and then re-invites the same email address
- **THEN** a new pending invite document is created
- **AND** a new notification email is sent to the invitee
