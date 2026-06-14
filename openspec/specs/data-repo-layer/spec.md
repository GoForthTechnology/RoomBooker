# Data Repo Layer Specification: Room Booker

## Purpose
This document specifies the Firestore/local-storage access-layer contracts
provided by `packages/roombooker_core/lib/data/repos/` (`BookingRepo`,
`OrgRepo`, `RoomRepo`, `LogRepo`, `UserRepo`, `PreferencesRepo`): collection
layout, query/stream semantics, transactional guarantees, and side effects
(audit logging, analytics events).

## [REPO-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Booking Request Collection Layout
`BookingRepo` SHALL store booking requests as Firestore documents under
`orgs/{orgID}/pending-requests`, `orgs/{orgID}/confirmed-requests`, and
`orgs/{orgID}/denied-requests`, with each request's private contact/details
stored separately in `orgs/{orgID}/request-details/{requestID}`. The
collection a request lives in SHALL determine its `RequestStatus`
(`pending`, `confirmed`, `denied`).

#### Scenario: New booking request is submitted
- **WHEN** `submitBookingRequest` is called with a `Request` and
  `PrivateRequestDetails`
- **THEN** a new document SHALL be created in
  `orgs/{orgID}/pending-requests` and a corresponding document SHALL be
  created in `orgs/{orgID}/request-details` with the same generated ID, both
  written atomically in a single transaction.

#### Scenario: Reading a request resolves across status collections
- **WHEN** `getRequest(orgID, requestID)` is called
- **THEN** the stream SHALL first check
  `orgs/{orgID}/confirmed-requests/{requestID}`, and if no document exists
  there, SHALL fall back to streaming
  `orgs/{orgID}/pending-requests/{requestID}`.

### Requirement: Transactional Booking Status Transitions
`BookingRepo` SHALL move a booking request document between status
collections atomically when its status changes, never leaving the request
present in more than one status collection.

#### Scenario: Confirming a pending request
- **WHEN** `confirmRequest(orgID, requestID)` is called for a request that
  exists in `pending-requests`
- **THEN** the request document SHALL be copied to
  `orgs/{orgID}/confirmed-requests/{requestID}` and deleted from
  `orgs/{orgID}/pending-requests/{requestID}` within a single transaction.

#### Scenario: Denying a pending request
- **WHEN** `denyRequest(orgID, requestID)` is called for a request that
  exists in `pending-requests`
- **THEN** the request document SHALL be copied to
  `orgs/{orgID}/denied-requests/{requestID}` and deleted from
  `orgs/{orgID}/pending-requests/{requestID}` within a single transaction.

#### Scenario: Revisiting a confirmed or denied request
- **WHEN** `revisitBookingRequest(orgID, request)` is called for a request
  whose status is `confirmed` or `denied`
- **THEN** the request document SHALL be moved back to
  `orgs/{orgID}/pending-requests/{requestID}` from its current
  (`confirmed-requests` or `denied-requests`) collection within a single
  transaction.

#### Scenario: Deleting a non-recurring booking
- **WHEN** `deleteBooking` is called for a request whose recurrence
  frequency is `never`
- **THEN** the request document in `confirmed-requests` and its
  corresponding `request-details` document SHALL both be deleted within a
  single transaction, without prompting for a recurring-edit choice.

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
- **THEN** the confirmed-request document itself SHALL NOT be modified, but
  the transaction SHALL still write `privateDetails` to
  `orgs/{orgID}/request-details/{requestID}`, and an `UpdateBooking` audit log
  entry and analytics event SHALL still be recorded.

#### Scenario: No recurring edit choice provided for a delete
- **WHEN** `deleteBooking` is called for a recurring request and the
  `RecurringBookingEditChoiceProvider` resolves to `null`
- **THEN** the operation SHALL throw `UnimplementedError`, but a
  `DeleteBooking` audit log entry SHALL still be written (in a `finally`
  block) before the exception propagates to the caller.

### Requirement: Booking Query and Streaming
`BookingRepo.listRequests` SHALL return a real-time stream of all `Request`
documents matching the given organization, time window
(`[startTime, endTime]`, normalized to whole days), optional status filter,
and optional room-ID filter, combining results across the relevant status
collections.

#### Scenario: Default status filter includes pending, confirmed, and denied
- **WHEN** `listRequests` is called without `includeStatuses`
- **THEN** the result stream SHALL include matching documents from
  `pending-requests`, `denied-requests`, and non-recurring (`frequency:
  "never"`) documents from `confirmed-requests`, as well as recurring
  confirmed requests whose recurrence overlaps the time window.

#### Scenario: Recurring confirmed requests are included by recurrence end date
- **WHEN** `listRequests` is called and a confirmed request has
  `recurrancePattern.frequency != "never"`
- **THEN** that request SHALL be included if its `recurrancePattern.end` is
  null or on/after `startTime`, and its `eventStartTime` is on/before
  `endTime`, regardless of whether its own `eventStartTime`/`eventEndTime`
  fall within the window.

#### Scenario: Room ID filter narrows all sub-queries
- **WHEN** `listRequests` is called with `includeRoomIDs` non-null
- **THEN** every underlying Firestore query SHALL additionally filter on
  `roomID` being one of the given IDs.

#### Scenario: Stream emits an initial empty list
- **WHEN** `listRequests` is subscribed to, before the first Firestore
  snapshot for any sub-query arrives
- **THEN** the combined stream SHALL emit an empty list as its first value
  (via `startWith([])`).

### Requirement: Audit Logging and Analytics on Booking Mutations
`BookingRepo` SHALL record a corresponding `RequestLogEntry` via
`LogRepo.addLogEntry` and emit an analytics event with the org ID and
request ID after the underlying Firestore write completes, for every method
that mutates a booking request (submit, update, add, end, ignore-overlaps,
delete, confirm, deny, revisit).

#### Scenario: Mutation succeeds but logging fails
- **WHEN** a `BookingRepo` mutation's Firestore write succeeds but the
  subsequent `LogRepo.addLogEntry` call throws
- **THEN** the error SHALL be logged via `dart:developer.log` and rethrown
  to the caller, even though the underlying data mutation has already been
  committed.

### Requirement: Request Details Caching
`BookingRepo.getRequestDetails` SHALL return a cached, shared stream of
`PrivateRequestDetails` keyed by `requestID`, backed by a single Firestore
listener on `orgs/{orgID}/request-details/{requestID}`, so that multiple
subscribers do not each open a separate Firestore listener.

#### Scenario: Multiple subscribers share one Firestore listener
- **WHEN** `getRequestDetails(orgID, requestID)` is called more than once
  for the same `requestID`
- **THEN** all returned streams SHALL be backed by the same underlying
  Firestore document listener and SHALL receive the same emitted values.

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
- **THEN** the `orgs/{orgID}` document SHALL be deleted via a direct
  (non-transactional) delete call, and the calling user's `orgIDs` SHALL be
  updated via a transactional `FieldValue.arrayRemove` of `orgID`, both
  issued from within the same `runTransaction` callback.

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
  deleted.

### Requirement: Organization Listing for Current User
`OrgRepo.getOrgsForCurrentUser` SHALL return a real-time stream of the
`Organization` documents corresponding to the current user's `orgIDs`,
updating whenever the user's profile or any referenced org document changes.

#### Scenario: User is not signed in
- **WHEN** `getOrgsForCurrentUser` is called and `FirebaseAuth.currentUser`
  is `null`
- **THEN** the stream SHALL emit an empty list and SHALL not attempt to read
  `users/{uID}`.

#### Scenario: User profile updates change the org list
- **WHEN** the current user's `users/{uID}` document's `orgIDs` field
  changes (e.g. an org is added or removed)
- **THEN** the stream returned by `getOrgsForCurrentUser` SHALL re-emit a
  list reflecting the updated set of organizations.

### Requirement: Room CRUD and Ordering
`RoomRepo` SHALL manage `Room` documents under `orgs/{orgID}/rooms`,
supporting create, read (single and list), update, delete, and an explicit
display-order via an `orderKey` field.

#### Scenario: Listing rooms returns them in orderKey order
- **WHEN** `listRooms(orgID)` is subscribed to
- **THEN** the emitted list of rooms SHALL be sorted ascending by each
  room's `orderKey` (rooms with a null `orderKey` SHALL sort using a
  fallback comparison against `1`).

#### Scenario: Reordering rooms updates orderKey for all rooms
- **WHEN** `reorderRooms(orgID, rooms)` is called with a list of rooms in
  the desired display order
- **THEN** each room's document SHALL be updated with `orderKey` set to its
  zero-based index in the supplied list, applied via a single batched write.

### Requirement: Audit Log Entry Creation and Retrieval
`LogRepo` SHALL store `RequestLogEntry` documents under
`orgs/{orgID}/request-logs`, each capturing the acting admin's email (if
any), an `Action`, a timestamp, and optional before/after `Request`
snapshots, and SHALL support retrieving entries filtered by request ID and
ordered most-recent-first.

#### Scenario: Adding a log entry captures the current admin's email
- **WHEN** `addLogEntry` is called while an admin user is signed in
- **THEN** the created `RequestLogEntry` document SHALL have `adminEmail`
  set to `FirebaseAuth.instance.currentUser?.email`.

#### Scenario: Retrieving log entries for specific requests
- **WHEN** `getLogEntries(orgID, requestIDs: {...})` is called with a
  non-empty set of request IDs
- **THEN** the returned stream SHALL only include entries whose `requestID`
  is in the given set, ordered by `timestamp` descending.

#### Scenario: Retrieving log entries with pagination
- **WHEN** `getLogEntries(orgID, limit: n, startAfter: entry)` is called
- **THEN** the returned stream SHALL contain at most `n` entries, all with
  `timestamp` after `entry.timestamp` in the descending order.

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
- **THEN** `orgID` SHALL be appended to that profile's `orgIDs`.

#### Scenario: Adding an org the user already belongs to
- **WHEN** `addOrg(t, userID, orgID)` is called and the user's `orgIDs`
  already contains `orgID`
- **THEN** the profile SHALL be left unchanged (no duplicate entries).

#### Scenario: Removing an org from a profile
- **WHEN** `removeOrg(t, userID, orgID)` is called
- **THEN** `orgID` SHALL be removed from `users/{userID}.orgIDs` via an
  array-remove update.

### Requirement: User Data Deletion
`UserRepo.deleteUserData` SHALL delete a user's profile and all
booking-related data associated with their email address across every
organization, as a single atomic batch.

#### Scenario: Deleting a user with submitted booking requests
- **WHEN** `deleteUserData(uID, email)` is called for a user whose email
  appears on one or more `request-details` documents across any
  organization
- **THEN** the batch SHALL delete the `users/{uID}` profile document, each
  matching `request-details` document, and the corresponding request
  document from whichever of `pending-requests`, `confirmed-requests`, or
  `denied-requests` it exists in within that org.

#### Scenario: Deleting a user with an empty email
- **WHEN** `deleteUserData(uID, "")` is called
- **THEN** only the `users/{uID}` profile document SHALL be deleted; no
  `request-details` lookup or cross-collection booking deletion SHALL be
  performed.

### Requirement: Local User Preferences Storage
`PreferencesRepo` SHALL persist the user's default calendar view and
last-opened organization ID using `shared_preferences`, loading them on
construction and notifying listeners whenever either value changes.

#### Scenario: Loading preferences with no stored values
- **WHEN** `PreferencesRepo` is constructed and `shared_preferences` has no
  stored `default_calendar_view` or `last_opened_org_id`
- **THEN** `defaultCalendarView` SHALL be `CalendarView.month` and
  `lastOpenedOrgId` SHALL be `null`.

#### Scenario: Loading an invalid stored calendar view
- **WHEN** `PreferencesRepo` is constructed and the stored
  `default_calendar_view` string does not match any `CalendarView` value
- **THEN** `defaultCalendarView` SHALL fall back to `CalendarView.month`.

#### Scenario: Updating the default calendar view persists and notifies
- **WHEN** `setDefaultCalendarView(view)` is called
- **THEN** `defaultCalendarView` SHALL be updated synchronously, listeners
  SHALL be notified, and the new value SHALL be persisted to
  `shared_preferences` under `default_calendar_view`.

#### Scenario: Clearing the last-opened organization
- **WHEN** `setLastOpenedOrgId(null)` is called
- **THEN** `lastOpenedOrgId` SHALL become `null`, listeners SHALL be
  notified, and the `last_opened_org_id` key SHALL be removed from
  `shared_preferences`.
