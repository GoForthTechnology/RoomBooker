## 1. Data Model

- [ ] 1.1 Add `AmendmentScope` enum (`thisInstance`, `thisAndFuture`) to `roombooker_core` with JSON serialization
- [ ] 1.2 Add `BookingAmendment` entity (`proposedRequest`, `proposedDetails`, `scope`, `proposedAt`) with `json_serializable`
- [ ] 1.3 Add `hasPendingAmendment` optional bool field to `Request` entity; default-false on absent, excluded from `toJson` when false
- [ ] 1.4 Run `build_runner` to regenerate `request.g.dart` and `booking_amendment.g.dart`
- [ ] 1.5 Add `amendmentProposed`, `amendmentApproved`, `amendmentRejected` to `NotificationEvent` enum

## 2. Data Layer (BookingRepo)

- [ ] 2.1 Add `_amendmentDetailsRef(orgID, requestID)` Firestore reference helper (new `amendment-details` collection)
- [ ] 2.2 Implement `submitAmendment`: batch-write creates `amendment-details/{id}` and sets `hasPendingAmendment: true` on confirmed-request; throw `StateError` if flag already set
- [ ] 2.3 Implement `getAmendment`: return `Stream<BookingAmendment?>` from `amendment-details/{id}` snapshots
- [ ] 2.4 Implement `applyAmendment`: atomic transaction that updates confirmed-request, updates `request-details`, clears flag, deletes `amendment-details`; delegate to existing `_updateConfirmedBooking` logic for recurring scope handling
- [ ] 2.5 Implement `rejectAmendment`: batch-write clears `hasPendingAmendment` and deletes `amendment-details/{id}`
- [ ] 2.6 Extend `deleteBooking` to also delete `amendment-details/{id}` if it exists within the same transaction
- [ ] 2.7 Add amendment log entries in `submitAmendment`, `applyAmendment`, and `rejectAmendment` using `_log()`

## 3. Service Layer (BookingService)

- [ ] 3.1 Add `submitAmendment`, `getAmendment`, `applyAmendment`, `rejectAmendment` pass-through methods on `BookingService`

## 4. Security Rules

- [ ] 4.1 Add `amendment-details/{requestID}` rule: `allow create: if isAuthenticated()`, `allow read, update, delete: if isAdmin()`
- [ ] 4.2 Add carve-out on `confirmed-requests` `allow update`: authenticated user may update only if `affectedKeys().hasOnly(['hasPendingAmendment'])`, incoming value is `true`, and current value is absent/false

## 5. Admin Review UI — Pending Queue

- [ ] 5.1 Extend the pending bookings list to query and display pending amendments alongside new requests, with a visual badge ("Edit Proposal")
- [ ] 5.2 Build `AmendmentDiffWidget`: shows proposer contact info, amendment scope (if recurring), and a field-by-field current-vs-proposed comparison for all changed fields
- [ ] 5.3 Wire "Apply Amendment" action: calls `BookingService.applyAmendment`, closes the review entry on success
- [ ] 5.4 Wire "Reject" action: calls `BookingService.rejectAmendment`, closes the review entry on success

## 6. Admin Editor — Block Direct Edit

- [ ] 6.1 In `RequestEditorViewModel._getActionsForConfirmedRequest`, check `hasPendingAmendment`; if true, replace "Edit" action with a no-op action whose title explains that the amendment must be resolved first

## 7. Non-Admin Entry Point

- [ ] 7.1 Add a confirmed-booking dialog for non-admins (or extend existing read-only panel): shows "Propose Change" button when `hasPendingAmendment` is false and booking is in the future; shows "Change pending" indicator when `hasPendingAmendment` is true
- [ ] 7.2 For recurring bookings, show a scope picker (`AmendmentScope`) before the edit form
- [ ] 7.3 Build or adapt the amendment edit form: pre-fill public `Request` fields, provide all `PrivateRequestDetails` fields (contact info required for admin verification); submit calls `BookingService.submitAmendment`

## 8. Tests

- [ ] 8.1 Unit tests for `BookingAmendment` serialization round-trip and `AmendmentScope` serialization
- [ ] 8.2 Unit tests for `Request.hasPendingAmendment` default-false deserialization
- [ ] 8.3 Unit tests for `BookingRepo.submitAmendment` — success path and `StateError` when already pending
- [ ] 8.4 Unit tests for `BookingRepo.applyAmendment` — one-off, `thisInstance`, and `thisAndFuture` scopes
- [ ] 8.5 Unit tests for `BookingRepo.rejectAmendment` — clears flag and deletes amendment doc
- [ ] 8.6 Unit tests for `BookingRepo.deleteBooking` — deletes amendment doc when `hasPendingAmendment` is true
- [ ] 8.7 Widget tests for `AmendmentDiffWidget` — renders changed fields and proposer contact info
- [ ] 8.8 Widget tests for non-admin confirmed-booking dialog — "Propose Change" visible for future bookings, indicator shown when pending, button hidden when pending
