## Context

Confirmed bookings are stored in `orgs/{orgID}/confirmed-requests/{id}` and
are publicly readable but admin-write-only. Private contact details live in
the admin-only `orgs/{orgID}/request-details/{id}` subcollection. The
existing review flow moves documents between `pending-requests`,
`confirmed-requests`, and `denied-requests` collections.

Non-admins currently have no write path to a confirmed booking. The
`RequestEditorViewModel` builds action lists based on `RequestStatus` and
`currentUserIsAdmin`; for non-admins viewing a confirmed booking there are
no actions at all.

## Goals / Non-Goals

**Goals:**

- Non-admins can propose a full edit to any future confirmed booking.
- Proposals surface in the admin Pending queue alongside new requests,
  visually differentiated.
- Admin can apply or reject the amendment atomically.
- The original booking remains active and unchanged while the amendment is
  pending.
- Security rules enforce that non-admins can only write the amendment fields,
  not the core booking data.

**Non-Goals:**

- Non-admins cannot withdraw their own amendment (admin-only).
- Amendments on past or in-progress bookings are not supported.
- Multiple concurrent amendments on the same booking are not supported.
- "All instances" scope for recurring amendments is not supported (only
  "this instance" and "this and future").

## Decisions

### Decision: Separate `amendment-details` collection, not embedded

**Chosen:** New sibling collection `orgs/{orgID}/amendment-details/{id}`
holds the full amendment payload (proposed `Request` fields + proposed
`PrivateRequestDetails`). A lightweight `hasPendingAmendment: true` flag on
the confirmed-request document signals existence to all readers.

**Alternative considered:** Embedding the amendment directly in the
confirmed-request document. Rejected because `confirmed-requests` is
publicly readable and embedding `PrivateRequestDetails` (name, email, phone)
there would expose sensitive contact information to unauthenticated readers.

**Alternative considered:** Adding a `pendingAmendmentDetails` field to the
existing `request-details` document. Rejected because it complicates approval
logic (need to cleanly separate current vs. proposed details) and makes the
security rules for the amendment write path harder to express.

### Decision: `hasPendingAmendment` flag on the confirmed-request doc

**Chosen:** A single boolean field `hasPendingAmendment` on the
`confirmed-request` document. This makes the indicator visible to all readers
in the same read that fetches the booking, avoiding a second query per
booking in list views. It is the only field non-admins are permitted to write
on this document.

**Alternative considered:** Querying `amendment-details` for each booking to
detect pending amendments. Rejected because it would require N extra reads in
the confirmed bookings list and is not expressible in a Firestore `where`
clause across a join.

### Decision: Amendments appear in the Pending queue, not a separate section

**Chosen:** `BookingService.getAmendmentStream` emits amendments as synthetic
`Request` objects with a new `RequestStatus.amendmentPending` value (or a
wrapper type). The Pending list renders these with a visual badge ("Edit
Proposal") alongside new-request cards.

**Alternative considered:** A separate "Proposed Amendments" section on the
review screen. Rejected per product decision to keep one unified admin queue.

### Decision: Admin is blocked from direct edits while an amendment is pending

**Chosen:** `RequestEditorViewModel` checks `hasPendingAmendment` on the
confirmed booking; if true, the "Edit" action is replaced with a message
directing the admin to resolve the amendment first.

**Rationale:** Prevents a collision where the admin silently overwrites an
in-flight amendment. Simpler than automatic invalidation and gives the admin
explicit visibility.

### Decision: Recurring amendment scope is chosen upfront

**Chosen:** When proposing a change to a recurring booking instance, a scope
picker ("This event" / "This and future events") is shown before the edit
form opens. The selected scope is stored on the `BookingAmendment` entity and
used by the apply logic.

**Rationale:** Mirrors the existing admin edit dialog pattern and ensures the
admin can see the intended scope clearly in the diff view.

**Non-goal scope:** "All instances" is excluded — applying "all" would need
to rewrite past occurrences, which is not permitted by this change.

### Decision: `bookingCreated` notification email is reused for amendments

**Chosen:** `amendmentProposed` defaults its notification target to the same
email address as `bookingCreated`. The email body explains the proposed
change, confirms it to the original requestor, and includes a challenge step
("If you did not request this change, contact your admin immediately").

**Rationale:** Keeps the admin alert in the same inbox as new booking
notifications. The dual-purpose body acts as a lightweight security control
without requiring a separate email address to configure.

## Risks / Trade-offs

- **Flag/data desync** → If the app crashes after setting `hasPendingAmendment`
  but before writing `amendment-details` (or vice versa), the flag and data
  are out of sync. Mitigation: use a Firestore batch write to set the flag
  and create the amendment-details document atomically.

- **Non-admin sets flag on any confirmed booking** → The security rule
  carve-out allows any authenticated user to set `hasPendingAmendment: true`
  on any confirmed booking (not just "their own"). Mitigation: accepted per
  product decision — identity verification is the admin's responsibility
  during review, aided by the contact details in `amendment-details`.

- **`amendment-details` orphan on booking deletion** → If a confirmed booking
  with a pending amendment is deleted by an admin, the `amendment-details`
  document is not automatically removed. Mitigation: `BookingRepo.deleteBooking`
  is extended to also delete `amendment-details/{id}` if it exists.

## Migration Plan

No data migration required. The `hasPendingAmendment` field is absent on all
existing `confirmed-requests` documents; the app treats absence as `false`.
The `amendment-details` collection is new and starts empty.

Firestore security rule changes are deployed before the app update to ensure
the new client can write to the new collection from day one.

## Open Questions

- Should the amendment email include a direct deep-link to the admin review
  screen? (Requires dynamic links or a web portal URL — deferred.)
