## Why

While backfilling the `data-repo-layer` spec (see archived change
`spec-data-repo-layer`), cross-checking the spec against
`packages/roombooker_core/lib/data/repos/` surfaced several real correctness
bugs in the repo implementations themselves (not just spec inaccuracies):
silent/unobservable logging failures, non-transactional writes presented as
atomic, a dangling-reference hazard on org removal, and two "no-op" recurring
booking edit paths that aren't actually no-ops. These should be fixed now,
before more code is built on top of the documented (but incorrect) contracts.

## What Changes

- **LogRepo.addLogEntry**: `await` and `return` the underlying Firestore
  `.add()` call so write failures actually propagate to callers (currently
  the failure is dropped into a detached `Future` via an unawaited
  `.catchError` that `throw`s, producing an unhandled async error instead of
  the documented "error is rethrown to the caller" behavior). **BREAKING**:
  `addLogEntry`'s `Future<void>` now genuinely completes with an error when
  the Firestore write fails, where previously it always completed
  successfully.
- **UserRepo.addOrg**: make it actually use the supplied `Transaction` (via
  `t.get`/`t.set`) instead of issuing a separate non-transactional
  `get()`/`set()`, and `await` it at both call sites
  (`OrgRepo.addOrgForCurrentUser`, `OrgRepo.addAdminRequestForCurrentUser`)
  so the org-membership update is atomic with, and observable alongside, the
  surrounding write.
- **OrgRepo.removeOrg**: perform the `orgs/{orgID}` document delete via the
  transaction (`t.delete`) instead of a direct, non-transactional
  `.delete()`, so a transaction retry can't leave the org deleted but the
  user's `orgIDs` still referencing it.
- **BookingRepo.deleteBooking**: when the `RecurringBookingEditChoiceProvider`
  resolves to `null` (user cancelled), return without throwing
  `UnimplementedError` and without writing an audit log entry — cancellation
  is a legitimate no-op, not an unimplemented code path.
- **BookingRepo.updateBooking**: when the edit-choice provider resolves to
  `null` for a recurring confirmed request, make the entire operation a true
  no-op — skip the `privateDetails` write and the `UpdateBooking` audit log
  entry/analytics event, matching the "no Firestore writes, no-op" intent.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `data-repo-layer`:
  - "Audit Logging and Analytics on Booking Mutations": logging failures
    SHALL propagate as real errors from `LogRepo.addLogEntry`.
  - "Recurring Booking Edit Choice Handling": a `null` edit choice SHALL be a
    true no-op for both `updateBooking` and `deleteBooking` (no writes, no
    audit log entries, no thrown errors).
  - "Organization CRUD and Visibility": `removeOrg` SHALL delete the org
    document and update the user's `orgIDs` within the same atomic
    transaction.
  - "Admin Request Workflow" and "User Profile and Org Membership":
    `UserRepo.addOrg` SHALL perform its read/write through the caller's
    `Transaction`, and callers SHALL await it.

## Impact

- **Affected code**:
  `packages/roombooker_core/lib/data/repos/{log_repo,user_repo,org_repo,booking_repo}.dart`
  and their tests.
- **Affected specs**: Modifies `openspec/specs/data-repo-layer/spec.md`
  (requirements listed above).
- **Risk**: `LogRepo.addLogEntry` becoming a real failure path means
  `BookingRepo._log`'s existing `try/catch`+`rethrow` will now actually
  trigger on logging failures, which already rethrows to the booking
  mutation's caller (per the existing documented contract) — callers of
  booking mutations should already be prepared for this, but should be
  re-checked.
