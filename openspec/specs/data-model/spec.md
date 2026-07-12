# Data Model Specification: Room Booker

## Purpose
This document specifies the core data entities and their properties for the Room Booker system.

## [DATA-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.
## Requirements
### Requirement: Request Entity
The system SHALL include a `Request` entity that represents a booking for a
room. The `Request` entity SHALL NOT include a `meetingUrl` field. The
`Request` entity SHALL include an optional `bookedVia` field identifying
the origin of a booking (e.g. Kiosk-originated "In-Room" bookings).

#### Scenario: Verify Request Fields
- **WHEN** creating a new `Request`
- **THEN** it includes fields for `id`, `eventStartTime`, `eventEndTime`,
  `roomID`, `roomName`, `status`, and `bookedVia`, and does not include
  `meetingUrl`.

#### Scenario: Default bookedVia is absent
- **WHEN** creating a `Request` without specifying `bookedVia`
- **THEN** the `bookedVia` field SHALL be `null`/absent, and existing
  stored `Request` documents without a `bookedVia` field SHALL deserialize
  successfully with `bookedVia == null`.

#### Scenario: Kiosk-originated booking
- **WHEN** a `Request` is created via the Kiosk's Quick Book feature
- **THEN** its `bookedVia` field SHALL identify it as Kiosk-originated

### Requirement: Recurrance Support
The `Request` entity SHALL support recurrence through a `RecurrancePattern`.

#### Scenario: Define Recurrence
- **WHEN** a user selects a daily frequency
- **THEN** the `RecurrancePattern` specifies a daily interval with an optional end date.

### Requirement: hasPendingAmendment Flag on Request
The `Request` entity SHALL include an optional `hasPendingAmendment` boolean
field. When absent from a Firestore document it SHALL deserialize as `false`.
This field SHALL NOT be included in `toJson` output when `false` or `null`
(to avoid polluting existing documents).

#### Scenario: Absent hasPendingAmendment deserializes as false
- **WHEN** a `Request` is deserialized from a Firestore document that does
  not contain a `hasPendingAmendment` field
- **THEN** `request.hasPendingAmendment` is `false`.

#### Scenario: hasPendingAmendment true is preserved through serialization
- **WHEN** a `Request` with `hasPendingAmendment: true` is serialized and
  deserialized
- **THEN** the round-trip value is `true`.

### Requirement: Private Request Details
Sensitive information about a booking MUST be stored separately in
`PrivateRequestDetails`, including the booking's video conference link. The
`PrivateRequestDetails` entity is also used as the proposed details payload
within `BookingAmendment` — its fields represent the desired state if the
amendment is applied.

#### Scenario: Verify Sensitive Info Separation
- **WHEN** a guest submits a booking
- **THEN** their name, email, and phone are stored in a
  `PrivateRequestDetails` record.

#### Scenario: Verify Meeting URL Storage
- **WHEN** a booking has an associated video conference link
- **THEN** the link is stored as `meetingUrl` on that booking's
  `PrivateRequestDetails` record, and not on the `Request` record.

#### Scenario: PrivateRequestDetails used as amendment proposed payload
- **WHEN** a `BookingAmendment` is created
- **THEN** its `proposedDetails` field is a `PrivateRequestDetails` instance
  containing the full desired contact and event details for the amended booking.

### Requirement: BookingAmendment Entity
The system SHALL include a `BookingAmendment` entity that represents a
pending proposed change to a confirmed booking. It SHALL contain the full
proposed `Request` state, the full proposed `PrivateRequestDetails`, the
amendment scope (`AmendmentScope`), and a `proposedAt` timestamp. The entity
SHALL be serializable to/from Firestore JSON via `json_serializable`.

#### Scenario: BookingAmendment fields are present
- **WHEN** a `BookingAmendment` is created
- **THEN** it contains `proposedRequest` (a `Request`), `proposedDetails`
  (a `PrivateRequestDetails`), `scope` (an `AmendmentScope`), and
  `proposedAt` (a `DateTime`).

### Requirement: AmendmentScope Enum
The system SHALL include an `AmendmentScope` enum with values `thisInstance`
and `thisAndFuture`. This value is stored on `BookingAmendment` and
determines the apply logic used by `BookingRepo`.

#### Scenario: Scope values are serializable
- **WHEN** an `AmendmentScope` value is serialized to JSON and back
- **THEN** the deserialized value equals the original.

### Requirement: User Profile
The system SHALL support a `UserProfile` entity for authenticated users.

#### Scenario: Store User Info
- **WHEN** a user signs in for the first time
- **THEN** a `UserProfile` is created with their UID, display name, and email.

### Requirement: Firestore Collections
Data SHALL be organized into logical Firestore collections: `requests`, `private_request_details`, `users`, and `rooms`.

#### Scenario: Check Firestore Structure
- **WHEN** inspecting the Firestore database
- **THEN** the specified collections are present with their respective documents.

### Requirement: Meeting URL Migration
The system MUST migrate existing `confirmed-requests` documents with a
non-null `meetingUrl` field to the corresponding
`PrivateRequestDetails.meetingUrl` before the `Request.meetingUrl` field is
removed from the deployed application, so that no meeting links are lost.

#### Scenario: Backfill existing confirmed requests
- **WHEN** the migration script runs against an org's `confirmed-requests`
  collection
- **THEN** every document with a non-null `meetingUrl` has that value copied
  into its `private-request-details/{requestID}` document's `meetingUrl`
  field, and the `meetingUrl` field is removed from the `confirmed-requests`
  document.

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

