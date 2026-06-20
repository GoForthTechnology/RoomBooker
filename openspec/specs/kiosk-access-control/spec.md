# Kiosk Access Control Specification: Room Booker

## Purpose
This document specifies the Kiosk's room-scoped Firebase Auth identity and
the Firestore access controls derived from it, including the Cloud
Functions that establish and revoke that identity during
(de)provisioning.

## [KIOSK-ACL-000] Compliance
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

## Requirements

### Requirement: Kiosk Anonymous Identity
The Kiosk application MUST authenticate with Firebase using Anonymous
Authentication, providing a stable `request.auth.uid` for all Firestore
access.

#### Scenario: First Launch Sign-In
- **WHEN** the Kiosk application starts and no Firebase Auth session exists
- **THEN** the system SHALL sign in anonymously and persist the resulting
  session across restarts and reboots.

### Requirement: Room-Scoped Kiosk Grant
The system SHALL record an authorization linking a Kiosk's anonymous
identity to a single `(orgID, roomID)` pair as a document at
`orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}`.

#### Scenario: Grant Created on Activation
- **WHEN** a Kiosk successfully claims an activation code via
  `claimKioskGrant`
- **THEN** the system SHALL create `kiosk-grants/{uid}` for the Kiosk's
  anonymous `uid` under the room identified by the activation code,
  containing at least `deviceID` and `createdAt`.

#### Scenario: Grant Revoked on De-provisioning
- **WHEN** a Kiosk de-provisions itself via `revokeKioskGrant`
- **THEN** the system SHALL delete the corresponding `kiosk-grants/{uid}`
  document.

#### Scenario: Grant Document is Server-Managed
- **WHEN** any client (Kiosk or Portal) attempts to directly create,
  update, or delete a `kiosk-grants/{uid}` document via Firestore
- **THEN** the write SHALL be rejected; only the Admin SDK (via
  `claimKioskGrant`/`revokeKioskGrant`) may write these documents.

### Requirement: Claim Kiosk Grant Function
The system SHALL provide a callable Cloud Function `claimKioskGrant` that
validates an activation code and establishes a Room-Scoped Kiosk Grant for
the calling Kiosk's anonymous identity.

#### Scenario: Valid, Unexpired Code
- **WHEN** an authenticated (anonymous) Kiosk calls `claimKioskGrant` with
  a `code` and `deviceID` that corresponds to an existing, unexpired
  `provisioning_codes/{code}` document
- **THEN** the system SHALL create the Kiosk's grant document, delete the
  activation code, and return the `orgID`, `roomID`, `orgName`, and
  `roomName`.

#### Scenario: Invalid or Expired Code
- **WHEN** an authenticated (anonymous) Kiosk calls `claimKioskGrant` with
  a `code` that does not exist or is expired
- **THEN** the system SHALL reject the call without creating a grant, and
  SHALL delete an expired code if found.

#### Scenario: Unauthenticated Caller
- **WHEN** `claimKioskGrant` is called without an authenticated
  `context.auth`
- **THEN** the system SHALL reject the call.

### Requirement: Revoke Kiosk Grant Function
The system SHALL provide a callable Cloud Function `revokeKioskGrant` that
deletes the calling Kiosk's Room-Scoped Kiosk Grant.

#### Scenario: Authenticated Revocation
- **WHEN** an authenticated (anonymous) Kiosk calls `revokeKioskGrant`
  with the `orgID` and `roomID` of its current grant
- **THEN** the system SHALL delete `orgs/{orgID}/rooms/{roomID}/kiosk-grants/{uid}`
  for the caller's `uid`.

#### Scenario: No Existing Grant
- **WHEN** `revokeKioskGrant` is called and no matching grant document
  exists
- **THEN** the system SHALL succeed without error (idempotent).

### Requirement: Scoped Private Request Details Access
An authorized Kiosk SHALL be granted read access to a
`PrivateRequestDetails` document only if the corresponding confirmed
request belongs to the Kiosk's assigned room.

#### Scenario: Kiosk Reads Details for Its Own Room
- **WHEN** a Kiosk with a valid grant for `roomID` reads
  `request-details/{requestID}`
- **AND** the corresponding `confirmed-requests/{requestID}` document has
  `roomID` matching the Kiosk's grant
- **THEN** the read SHALL be allowed.

#### Scenario: Kiosk Reads Details for Another Room
- **WHEN** a Kiosk with a valid grant for `roomID` reads
  `request-details/{requestID}`
- **AND** the corresponding `confirmed-requests/{requestID}` document has
  a different `roomID`
- **THEN** the read SHALL be denied.

### Requirement: Scoped Confirmed Request Creation
An authorized Kiosk SHALL be granted create access to
`confirmed-requests/{requestID}` only when the new document's `roomID`
matches the Kiosk's assigned room.

#### Scenario: Kiosk Creates Booking for Its Own Room
- **WHEN** a Kiosk with a valid grant for `roomID` creates a
  `confirmed-requests/{requestID}` document with `roomID` equal to its
  grant's room
- **THEN** the create SHALL be allowed.

#### Scenario: Kiosk Attempts to Create Booking for Another Room
- **WHEN** a Kiosk with a valid grant for `roomID` creates a
  `confirmed-requests/{requestID}` document with a different `roomID`
- **THEN** the create SHALL be denied.

### Requirement: Unauthenticated Kiosk Access Denied
The system SHALL NOT grant Kiosk-specific access to `PrivateRequestDetails`
or write access to `confirmed-requests` to a client with no valid
Room-Scoped Kiosk Grant, including unauthenticated clients.

#### Scenario: No Grant Document Exists
- **WHEN** a client (anonymous or otherwise) without a `kiosk-grants/{uid}`
  document for the relevant room reads `request-details/{requestID}` or
  creates a `confirmed-requests/{requestID}` document
- **AND** the client is not an org admin
- **THEN** the request SHALL be denied.

### Requirement: Provisioning Error Document Access
An authorized Kiosk SHALL be granted read and delete access to documents in
`orgs/{orgID}/rooms/{roomID}/provisioning-errors` scoped to its assigned
room. No other client (including unauthenticated clients and non-admin
Portal users) SHALL have write or read access to this subcollection.

#### Scenario: Kiosk Reads Error Documents for Its Room
- **WHEN** a Kiosk with a valid grant for `roomID` reads documents from
  `orgs/{orgID}/rooms/{roomID}/provisioning-errors`
- **THEN** the read SHALL be allowed

#### Scenario: Kiosk Deletes Error Document After Dismissal
- **WHEN** a Kiosk with a valid grant for `roomID` deletes a document from
  `orgs/{orgID}/rooms/{roomID}/provisioning-errors`
- **THEN** the delete SHALL be allowed

#### Scenario: Kiosk Cannot Access Error Documents for Another Room
- **WHEN** a Kiosk with a valid grant for `roomID` attempts to read or
  delete documents from `provisioning-errors` under a different room
- **THEN** the request SHALL be denied

#### Scenario: Unauthenticated Client Cannot Access Error Documents
- **WHEN** a client without a valid `kiosk-grants/{uid}` document attempts
  to access `provisioning-errors` for any room
- **THEN** the request SHALL be denied

#### Scenario: Only Admin SDK May Write Error Documents
- **WHEN** any Firestore client (Kiosk, Portal, or anonymous) attempts to
  create or update a document in `provisioning-errors`
- **THEN** the write SHALL be denied; only the Cloud Functions Admin SDK
  MAY write to this subcollection
