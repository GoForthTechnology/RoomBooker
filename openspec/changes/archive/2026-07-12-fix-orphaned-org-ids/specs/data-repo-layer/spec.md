## MODIFIED Requirements

### Requirement: Admin Request Workflow
`OrgRepo` SHALL support a request/approve/deny/remove workflow for organization
admin access, storing pending requests in
`orgs/{orgID}/admin-requests/{userID}` and approved admins in
`orgs/{orgID}/active-admins/{userID}`. Every operation that ends a user's
relationship with an org SHALL also remove `orgID` from that user's
`UserProfile.orgIDs` atomically.

#### Scenario: Requesting admin access
- **WHEN** `addAdminRequestForCurrentUser(orgID)` is called by an
  authenticated user with an email address
- **THEN** an `AdminEntry` document SHALL be created at
  `orgs/{orgID}/admin-requests/{userID}` via a transactional write, and the
  user's `orgIDs` SHALL be updated (via a separate, non-transactional
  read-then-write) to include `orgID`.

#### Scenario: Approving an admin request
- **WHEN** `approveAdminRequest(orgID, userID)` is called for a user with an
  existing entry in `orgs/{orgID}/admin-requests`
- **THEN** that entry SHALL be deleted from `admin-requests` and an
  equivalent `AdminEntry` document SHALL be created at
  `orgs/{orgID}/active-admins/{userID}`, within a single transaction.

#### Scenario: Approving a request that no longer exists
- **WHEN** `approveAdminRequest(orgID, userID)` is called but no document
  exists at `orgs/{orgID}/admin-requests/{userID}`
- **THEN** the transaction SHALL fail with an error and no documents SHALL
  be written to `active-admins`.

#### Scenario: Denying an admin request
- **WHEN** `denyAdminRequest(orgID, userID)` is called
- **THEN** the document at `orgs/{orgID}/admin-requests/{userID}` SHALL be
  deleted and `orgID` SHALL be removed from `users/{userID}.orgIDs` via
  `FieldValue.arrayRemove`, both within a single transaction.

#### Scenario: Removing an active admin
- **WHEN** `removeAdmin(orgID, userID)` is called
- **THEN** the document at `orgs/{orgID}/active-admins/{userID}` SHALL be
  deleted and `orgID` SHALL be removed from `users/{userID}.orgIDs` via
  `FieldValue.arrayRemove`, both within a single transaction.
