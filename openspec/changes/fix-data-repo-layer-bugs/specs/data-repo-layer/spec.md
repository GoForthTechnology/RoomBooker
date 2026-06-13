## MODIFIED Requirements

### Requirement: Audit Logging and Analytics on Booking Mutations
`BookingRepo` SHALL record a corresponding `RequestLogEntry` via
`LogRepo.addLogEntry` and emit an analytics event with the org ID and
request ID after the underlying Firestore write completes, for every method
that mutates a booking request (submit, update, add, end, ignore-overlaps,
delete, confirm, deny, revisit).

#### Scenario: Mutation succeeds but logging fails
- **WHEN** a `BookingRepo` mutation's Firestore write succeeds but the
  underlying `request-logs` Firestore write inside `LogRepo.addLogEntry`
  fails
- **THEN** `LogRepo.addLogEntry`'s returned `Future` SHALL complete with that
  error (rather than completing successfully), and `BookingRepo._log` SHALL
  log the error via `dart:developer.log` and rethrow it to the caller, even
  though the underlying data mutation has already been committed.

### Requirement: Recurring Booking Edit Choice Handling
`BookingRepo.updateBooking` and `BookingRepo.deleteBooking` SHALL, for
requests whose recurrence frequency is not "never", invoke the supplied
`RecurringBookingEditChoiceProvider` and apply one of three edit scopes:
`thisInstance`, `thisAndFuture`, or `all`.

#### Scenario: Editing this instance only
- **WHEN** `updateBooking` is called for a recurring request with edit
  choice `thisInstance`
- **THEN** the original recurring request SHALL gain a
  `recurranceOverrides` entry keyed by the (stripped-to-day) original start
  time, mapping to the updated request, and the base recurrence definition
  SHALL remain unchanged.

#### Scenario: Editing this and future instances
- **WHEN** `updateBooking` is called for a recurring request with edit
  choice `thisAndFuture`
- **THEN** the original recurring request's `recurrancePattern.end` SHALL be
  set to one day before the updated request's event end date, and a new
  confirmed-request document SHALL be created representing the updated
  request as a new (independent) recurring series.

#### Scenario: Editing all instances
- **WHEN** `updateBooking` is called for a recurring request with edit
  choice `all`
- **THEN** the existing confirmed-request document SHALL be overwritten with
  the updated request's fields while preserving the original request's
  `eventStartTime` and `eventEndTime`.

#### Scenario: Deleting this instance of a recurring series
- **WHEN** `deleteBooking` is called for a recurring request with edit choice
  `thisInstance`
- **THEN** the original recurring request SHALL gain a
  `recurranceOverrides` entry keyed by the (stripped-to-day) event start
  time, mapped to `null`, removing that single occurrence without deleting
  the series.

#### Scenario: Deleting this and future instances of a recurring series
- **WHEN** `deleteBooking` is called for a recurring request with edit choice
  `thisAndFuture`
- **THEN** `endBooking` SHALL be invoked, setting
  `recurrancePattern.end` to the (stripped-to-day) `eventStartTime` of the
  request being deleted.

#### Scenario: No recurring edit choice provided for an update
- **WHEN** `updateBooking` is called for a recurring confirmed request and the
  `RecurringBookingEditChoiceProvider` resolves to `null`
- **THEN** the operation SHALL be a complete no-op: no write SHALL be made to
  the confirmed-request document or to
  `orgs/{orgID}/request-details/{requestID}`, and no `UpdateBooking` audit
  log entry or analytics event SHALL be recorded.

#### Scenario: No recurring edit choice provided for a delete
- **WHEN** `deleteBooking` is called for a recurring request and the
  `RecurringBookingEditChoiceProvider` resolves to `null`
- **THEN** the operation SHALL be a no-op: it SHALL return without throwing
  and without writing a `DeleteBooking` audit log entry.

### Requirement: Organization CRUD and Visibility
`OrgRepo` SHALL manage `Organization` documents under the `orgs` collection,
including creation (with an initial room and the creating user added as a
member), visibility toggling (`publiclyVisible`), notification settings
updates, and removal (including removing the org from the owning user's
`orgIDs`).

#### Scenario: Creating an organization for the current user
- **WHEN** `addOrgForCurrentUser(orgName, firstRoomName)` is called while a
  user is authenticated
- **THEN** a new `orgs` document SHALL be created with `ownerID` set to the
  current user's UID and `acceptingAdminRequests: false`, the user's
  `orgIDs` SHALL include the new org's ID, and a first `Room` named
  `firstRoomName` SHALL be created in `orgs/{orgID}/rooms`.

#### Scenario: Creating an organization while signed out
- **WHEN** `addOrgForCurrentUser` is called and `FirebaseAuth.currentUser`
  is `null`
- **THEN** the returned future SHALL complete with an error and no Firestore
  writes SHALL occur.

#### Scenario: Removing an organization
- **WHEN** `removeOrg(orgID)` is called by an authenticated user for an org
  that exists
- **THEN** the `orgs/{orgID}` document SHALL be deleted via `t.delete` and
  the calling user's `orgIDs` SHALL be updated via a transactional
  `FieldValue.arrayRemove` of `orgID`, both as part of the same atomic
  transaction, so a transaction retry cannot observe the org as already
  deleted while the user's `orgIDs` still references it.

#### Scenario: Listing public organizations excludes owned orgs on request
- **WHEN** `getOrgs(excludeOwned: true)` is called for an authenticated user
- **THEN** the returned stream SHALL contain only orgs with
  `publiclyVisible: true` whose IDs are not present in the current user's
  `orgIDs`.

### Requirement: Admin Request Workflow
`OrgRepo` SHALL support a request/approve/deny workflow for organization
admin access, storing pending requests in
`orgs/{orgID}/admin-requests/{userID}` and approved admins in
`orgs/{orgID}/active-admins/{userID}`.

#### Scenario: Requesting admin access
- **WHEN** `addAdminRequestForCurrentUser(orgID)` is called by an
  authenticated user with an email address
- **THEN** an `AdminEntry` document SHALL be created at
  `orgs/{orgID}/admin-requests/{userID}` and the user's `orgIDs` SHALL be
  updated to include `orgID`, both as part of the same transaction (via
  `t.get`/`t.set` on `users/{userID}` and `t.set` on the admin-request
  document).

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
  deleted.

### Requirement: User Profile and Org Membership
`UserRepo` SHALL manage `UserProfile` documents at `users/{uID}`, each
tracking the org IDs (`orgIDs`) the user belongs to, and SHALL keep this
list in sync as the user joins or leaves organizations.

#### Scenario: Creating a profile for a new user
- **WHEN** `addUser(user)` is called for a user with no existing profile
- **THEN** a `UserProfile` document SHALL be created at `users/{user.uid}`
  with an empty `orgIDs` list.

#### Scenario: Adding an org to an existing profile
- **WHEN** `addOrg(t, userID, orgID)` is called and `users/{userID}` already
  exists with `orgIDs` not containing `orgID`
- **THEN** `orgID` SHALL be appended to that profile's `orgIDs` via a read
  (`t.get`) and write (`t.set`) performed within the supplied transaction
  `t`.

#### Scenario: Adding an org the user already belongs to
- **WHEN** `addOrg(t, userID, orgID)` is called and the user's `orgIDs`
  already contains `orgID`
- **THEN** the profile SHALL be left unchanged (no duplicate entries, no
  write performed), using a transactional read (`t.get`) within `t`.

#### Scenario: Removing an org from a profile
- **WHEN** `removeOrg(t, userID, orgID)` is called
- **THEN** `orgID` SHALL be removed from `users/{userID}.orgIDs` via an
  array-remove update.
