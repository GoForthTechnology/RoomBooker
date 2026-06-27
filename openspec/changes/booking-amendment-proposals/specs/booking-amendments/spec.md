## ADDED Requirements

### Requirement: Amendment Submission by Non-Admin
Any authenticated non-admin user SHALL be able to propose a change to a
confirmed booking that has not yet started. The proposal SHALL capture the
full desired state of the booking: all `Request` fields (time, room, public
name, recurrence scope) and all `PrivateRequestDetails` fields (event name,
contact name, email, phone, meeting URL, message). For a recurring booking
instance the user SHALL first select a scope — "this event only" or "this and
future events" — before editing. The system SHALL reject a proposal if a
pending amendment already exists on that booking.

#### Scenario: Non-admin proposes a change to a one-off confirmed booking
- **WHEN** an authenticated non-admin user opens a confirmed booking dialog
  and taps "Propose Change"
- **THEN** an edit form pre-filled with the booking's current public fields
  is shown, the user can modify any field, and submitting writes a
  `BookingAmendment` document to `amendment-details/{requestID}` and sets
  `hasPendingAmendment: true` on the confirmed-request document atomically.

#### Scenario: Scope picker shown before edit form for recurring instances
- **WHEN** a non-admin opens the proposal form for a recurring booking instance
- **THEN** a scope picker ("This event only" / "This and future events") is
  shown before the edit form, and the chosen scope is recorded on the
  `BookingAmendment`.

#### Scenario: Proposal blocked if amendment already pending
- **WHEN** a non-admin opens the dialog for a confirmed booking whose
  `hasPendingAmendment` is `true`
- **THEN** the "Propose Change" button is not shown; a "Change pending"
  indicator is displayed instead, and no amendment form can be opened.

#### Scenario: Proposal blocked for past or in-progress bookings
- **WHEN** a non-admin opens the dialog for a confirmed booking whose
  `eventStartTime` is in the past or within the current moment
- **THEN** the "Propose Change" button SHALL NOT be shown.

### Requirement: Pending Indicator on Confirmed Booking
A confirmed booking with `hasPendingAmendment: true` SHALL display a visual
indicator to all users (admin and non-admin) wherever the booking appears in
the UI.

#### Scenario: Indicator shown in confirmed booking dialog
- **WHEN** any user opens the dialog for a confirmed booking that has a
  pending amendment
- **THEN** a "Change pending" label or badge is visible in the dialog.

### Requirement: Admin Cannot Directly Edit a Booking with a Pending Amendment
When a confirmed booking has `hasPendingAmendment: true`, the admin's "Edit"
action SHALL be replaced with a message instructing the admin to resolve the
pending amendment first.

#### Scenario: Edit action blocked for admin while amendment is pending
- **WHEN** an admin opens the editor for a confirmed booking with
  `hasPendingAmendment: true`
- **THEN** the "Edit" button is absent and a message directs the admin to
  the pending amendment.

### Requirement: Amendments Surface in the Admin Pending Queue
Pending amendments SHALL appear in the existing Pending booking list
alongside new booking requests. Each amendment entry SHALL be visually
distinguished (e.g., labelled "Edit Proposal") so admins can identify it as
a change to an existing confirmed booking rather than a new request.

#### Scenario: Amendment appears in Pending list with visual differentiation
- **WHEN** an admin views the Pending queue and there is at least one
  confirmed booking with a pending amendment
- **THEN** the amendment appears in the list with a label or badge
  distinguishing it from new-booking requests.

### Requirement: Admin Diff View for Amendment Review
When an admin opens a pending amendment for review, the UI SHALL present a
diff of the current booking state versus the proposed state, along with the
proposer's contact details for identity verification.

#### Scenario: Admin sees current vs. proposed diff with contact info
- **WHEN** an admin opens a pending amendment from the Pending queue
- **THEN** the view shows the proposer's name, email, and phone; the
  amendment scope (if recurring); and a field-by-field comparison of current
  vs. proposed values for all changed fields.

### Requirement: Admin Apply Amendment
An admin SHALL be able to apply a pending amendment. Applying SHALL
atomically update the confirmed-request document with the proposed `Request`
fields, update the `request-details` document with the proposed
`PrivateRequestDetails`, clear `hasPendingAmendment`, delete the
`amendment-details` document, and log an `amendmentApproved` event.

#### Scenario: Admin applies a one-off amendment
- **WHEN** an admin taps "Apply Amendment" on a pending amendment for a
  one-off booking
- **THEN** the confirmed-request document is updated with the proposed
  fields, the `request-details` document is updated with the proposed
  details, `hasPendingAmendment` is cleared, the `amendment-details`
  document is deleted, and an `amendmentApproved` log entry is written —
  all atomically.

#### Scenario: Admin applies a "this instance" amendment for a recurring booking
- **WHEN** an admin applies an amendment scoped to "this event only" on a
  recurring booking
- **THEN** the proposed changes are stored as a `recurranceOverride` for
  that instance on the series document, consistent with the existing
  single-instance override pattern.

#### Scenario: Admin applies a "this and future" amendment for a recurring booking
- **WHEN** an admin applies an amendment scoped to "this and future events"
- **THEN** the series is split: the original series is ended before the
  instance date and a new confirmed-request document is created starting from
  that date with the proposed fields, consistent with the existing
  "this and future" edit pattern.

### Requirement: Admin Reject Amendment
An admin SHALL be able to reject a pending amendment. Rejecting SHALL
atomically clear `hasPendingAmendment` on the confirmed-request document,
delete the `amendment-details` document, and log an `amendmentRejected`
event. The confirmed booking SHALL remain unchanged.

#### Scenario: Admin rejects an amendment
- **WHEN** an admin taps "Reject" on a pending amendment
- **THEN** `hasPendingAmendment` is cleared on the confirmed-request
  document, the `amendment-details` document is deleted, and an
  `amendmentRejected` log entry is written — all atomically. The original
  booking is unchanged.

### Requirement: Amendment Notification on Submission
When a non-admin submits an amendment, the system SHALL send a notification
to the `bookingCreated` notification target email. The email body SHALL serve
dual purposes: confirming the amendment to the requestor and alerting
anyone who did not initiate the change to contact their admin to challenge it.

#### Scenario: Notification sent on amendment submission
- **WHEN** a non-admin successfully submits an amendment proposal
- **THEN** a notification email is sent to the address configured for
  `bookingCreated` in the org's notification settings, including the proposed
  changes, the proposer's contact details, and a challenge step.

### Requirement: Amendment Events Logged
Amendment lifecycle events SHALL be recorded in the existing request log
system using the same `logRepo.addLogEntry` pattern as other booking actions.

#### Scenario: Amendment submission is logged
- **WHEN** a non-admin submits an amendment
- **THEN** an `amendmentProposed` log entry is written for the affected
  request ID.

#### Scenario: Amendment resolution is logged
- **WHEN** an admin applies or rejects an amendment
- **THEN** an `amendmentApproved` or `amendmentRejected` log entry is
  written for the affected request ID.

### Requirement: Amendment Form Uses Fullscreen Layout on Mobile
On narrow viewports (width < 650 px) the amendment proposal form SHALL be
presented as a fullscreen dialog (`Dialog.fullscreen`) with an AppBar
containing the title, a close button, and the submit action — matching the
presentation used for the new-booking editor. On wide viewports the existing
constrained `AlertDialog` layout SHALL be used instead. The breakpoint of
650 px matches the `isSmallView` threshold used elsewhere in the portal.

#### Scenario: Amendment form is fullscreen on a mobile viewport
- **WHEN** a user on a narrow screen (< 650 px wide) opens the amendment
  proposal form
- **THEN** the form occupies the full screen with an AppBar header and a
  scrollable body, matching the new-booking editor presentation.

#### Scenario: Amendment form is a dialog on a wide viewport
- **WHEN** a user on a wide screen (≥ 650 px) opens the amendment proposal
  form
- **THEN** the form is presented as a constrained `AlertDialog` with Cancel
  and Submit actions at the bottom.

### Requirement: Amendment Cleaned Up on Booking Deletion
If an admin deletes a confirmed booking that has a pending amendment, the
`amendment-details` document for that booking SHALL be deleted atomically
with the booking.

#### Scenario: Deleting a booking with a pending amendment removes the amendment
- **WHEN** an admin deletes a confirmed booking that has `hasPendingAmendment: true`
- **THEN** the `amendment-details/{requestID}` document is deleted in the
  same transaction as the booking deletion.
