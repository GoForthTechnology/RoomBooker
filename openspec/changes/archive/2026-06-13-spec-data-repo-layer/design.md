## Context

`packages/roombooker_core/lib/data/repos/` contains six classes that wrap
Firestore (and, for `PreferencesRepo`, `shared_preferences`) and are
consumed by `BookingService` and the portal/kiosk UIs (via `providers.dart`).
This change documents their *current* behavior as a spec; it does not change
any code. The spec is derived by reading the existing implementations
(`booking_repo.dart`, `org_repo.dart`, `room_repo.dart`, `log_repo.dart`,
`user_repo.dart`, `prefs_repo.dart`).

## Goals / Non-Goals

**Goals:**
- Capture the Firestore collection layout each repo reads/writes
  (`orgs/{orgID}/...`, `users/{uID}`), so future changes don't silently
  diverge from it.
- Document transactional guarantees (e.g. `submitBookingRequest` writes the
  request and its private details atomically; `confirmRequest`/`denyRequest`
  move documents between status collections atomically).
- Document the recurring-booking edit-choice contract
  (`thisInstance` / `thisAndFuture` / `all`) used by `updateBooking` and
  `deleteBooking`, since this is the most behaviorally complex part of the
  layer.
- Document side effects that are easy to miss: every mutating `BookingRepo`
  method writes an audit log entry via `LogRepo` and fires an analytics
  event; `OrgRepo`/`UserRepo` mutations keep `users/{uID}.orgIDs` and org
  membership in sync.
- Document `UserRepo.deleteUserData`'s cross-collection deletion contract
  (profile + matching `request-details` + corresponding pending/confirmed/
  denied request docs), since it's a privacy-relevant guarantee.

**Non-Goals:**
- No new requirements or behavior changes — this is a backfill of the
  as-built system.
- Not documenting `BookingService` (already covered by
  `instance-rescheduling`/`data-model`) except where a repo contract is only
  meaningful in terms of how `BookingService` calls it.
- Not documenting Firestore security rules (separate concern, not in this
  package).

## Decisions

- **One capability spec, six requirement groups** (one per repo class)
  rather than one spec per repo: the repos are small, related, and reviewed
  together; six tiny specs would fragment a single coherent "data access"
  concern.
- **Describe collection paths literally** (e.g.
  `orgs/{orgID}/pending-requests`) since these are de-facto part of the
  contract — other tooling (Firestore rules, indexes) depends on them.
- **Treat `PreferencesRepo` as in-scope** despite being local-only (no
  Firestore): it's in the same `data/repos/` directory and follows the same
  "repo wraps a storage backend and notifies listeners" pattern, so excluding
  it would leave a gap.

## Risks / Trade-offs

- [Spec drift if repos change without updating the spec] → The spec text
  will reference concrete collection names/paths so future diffs touching
  those paths are an obvious trigger to update the spec; this is a normal
  spec-maintenance responsibility going forward, not enforced by tooling.
- [Some implementation details (e.g. `DetailCache` in `BookingRepo`) are
  performance optimizations, not contracts] → Document the externally
  observable behavior (a cached stream of `PrivateRequestDetails`) without
  specifying caching as a requirement.

## Migration Plan

N/A — documentation only, no code or data changes.
