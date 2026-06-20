# Kiosk Access Control Specification (Delta): Room Booker

## ADDED Requirements

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
