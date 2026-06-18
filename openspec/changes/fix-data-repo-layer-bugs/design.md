## Context

`packages/roombooker_core/lib/data/repos/` was recently documented (spec
`data-repo-layer`) by reading the existing implementations as-built. That
read-through found four independent bugs across `log_repo.dart`,
`user_repo.dart`, `org_repo.dart`, and `booking_repo.dart`. All four are
small, localized fixes with no shared mechanism between them; this design
covers each in turn. `fake_cloud_firestore` is already used by
`booking_repo_test.dart`, `org_repo_test.dart`, and `user_repo_test.dart`, so
each fix can be covered by a focused unit test.

## Goals / Non-Goals

**Goals:**
- Make `LogRepo.addLogEntry` genuinely propagate Firestore write errors as a
  failed `Future`, so `BookingRepo._log`'s existing `catch`/`rethrow` works
  as the spec already describes.
- Make `UserRepo.addOrg` use the `Transaction` it's given (read+write via
  `t`), and make both `OrgRepo` call sites `await` it.
- Make `OrgRepo.removeOrg` delete the org document via `t.delete` so the
  whole operation is atomic and retry-safe.
- Make `null` recurring-edit choices true no-ops in both
  `BookingRepo.updateBooking` and `BookingRepo.deleteBooking`.

**Non-Goals:**
- No changes to `RoomRepo`, `PreferencesRepo`, or the public method
  signatures of any repo (return types stay `Future<...>`/`Stream<...>` as
  today).
- Not addressing `BookingRepo.DetailCache`'s `requestID`-only cache key
  (practically safe given Firestore's globally-unique push IDs; not a bug
  worth the churn here).
- Not changing `OrgRepo.addOrgForCurrentUser`'s best-effort (non-transactional,
  catch-and-log) creation of the first `Room` — that's a separate, lower-risk
  gap not raised by this review.

## Decisions

### 1. `LogRepo.addLogEntry` — await and propagate

Change:
```dart
await db.collection("orgs").doc(orgID).collection("request-logs")
    .add(entry.toJson());
```
Drop the `.catchError` that `throw`s into a detached future — once awaited,
a failure naturally completes `addLogEntry`'s `Future` with an error, which
is exactly what `BookingRepo._log`'s `try { await logRepo.addLogEntry(...); }
catch (e, s) { log(...); rethrow; }` already expects.

**Alternative considered**: keep `.catchError` but `await` the chain. Rejected
— redundant once awaited; a plain `await` lets the error surface naturally
and is simpler.

### 2. `UserRepo.addOrg` — use the transaction, await call sites

Change `addOrg`'s body to use `t.get(profileRef)` and `t.set`/`t.update`
instead of `profileRef.get()`/`profileRef.set()`. Since Firestore transactions
require all reads before any writes, and `addOrg` is called *after* other
reads/writes have already happened in both call sites
(`addOrgForCurrentUser`, `addAdminRequestForCurrentUser`), this requires
re-ordering: do `addOrg`'s `t.get` first (or restructure so all transaction
reads happen up front), then perform the dependent writes.

Concretely:
- `addOrgForCurrentUser`: read the user profile via `t` *before* `t.add`-ing
  the new org doc (note: `_db.collection("orgs").add(...)` is itself
  *not* a transactional write — `CollectionReference.add` has no transaction
  variant. Use `t.set` on a pre-allocated `doc()` reference instead, so the
  org-doc creation is part of the same transaction as the profile update).
- `addAdminRequestForCurrentUser`: read the user profile via `t` before
  `t.set`-ing the admin-request doc.

Both call sites change `_userRepo.addOrg(t, ...)` (fire-and-forget) to
`await _userRepo.addOrg(t, ...)`.

**Alternative considered**: leave `addOrg` non-transactional but `await` it
after the transaction commits (two sequential operations). Rejected — this
keeps the user-profile update non-atomic with the triggering write, which is
the core bug; doing the read-then-write inside the same transaction is not
materially more complex here since both call sites already use
`runTransaction`.

### 3. `OrgRepo.removeOrg` — transactional delete

Change `await orgRef.delete()` to `t.delete(orgRef)`. Combined with the
existing `t.get(orgRef)` existence check and `_userRepo.removeOrg(t, ...)`
(already uses `t.update`), the whole operation becomes a single atomic
transaction: if it retries, the org doc hasn't actually been deleted yet on
the retried attempt, so `org.exists` is still accurate.

### 4. `BookingRepo` — true no-ops for `null` edit choice

- `deleteBooking`: replace `case null: throw UnimplementedError();` with
  `case null: return;` *and* skip the `_log(...)` call entirely for this
  case (move the `_log` call out of the shared `finally` for the `null`
  branch, or early-return before entering the `try/finally`).
- `updateBooking` / `_updateConfirmedBooking`: when `choice == null`,
  propagate a signal (e.g. a sentinel/flag, or restructure so
  `_updateConfirmedBooking` returning early causes `updateBooking` to skip
  both the `t.set(privateDetailsRef, ...)` and the post-transaction `_log`
  call). Simplest approach: have `_updateConfirmedBooking` return a `bool`
  (`true` if it made changes), and have `updateBooking` skip the
  `privateDetailsRef` write and `_log` call when it returns `false` for the
  confirmed-with-recurrence-and-null-choice case. The `pending`-status branch
  and the non-recurring confirmed branch always return `true`.

**Alternative considered**: throw a dedicated `BookingEditCancelledException`
and catch it in `updateBooking`/`deleteBooking` to skip side effects.
Rejected — using exceptions for normal user-cancellation control flow is
noisier than a boolean return / early return, and the existing `catch` blocks
already exist for genuine errors.

## Risks / Trade-offs

- [LogRepo error propagation is a **BREAKING** change to `addLogEntry`'s
  contract — any caller relying on it never throwing will now see errors] →
  Only one caller exists today (`BookingRepo._log`), which already has a
  `try/catch`+`rethrow`; no other change needed. Covered by the proposal's
  Impact note.
- [Reordering reads-before-writes in `addOrgForCurrentUser` /
  `addAdminRequestForCurrentUser` changes transaction read-write ordering,
  which Firestore transactions enforce strictly] → Write a unit test with
  `fake_cloud_firestore` for each path to confirm the transaction still
  commits successfully end-to-end.
- [`updateBooking`'s no-op path changing from "always writes privateDetails +
  logs" to "writes nothing" could be surprising if some caller depended on
  the audit-log side effect even for cancelled edits] → No such dependency
  found in `BookingService` or UI callers during this review; flagged in
  proposal Impact for a final check during implementation.

## Migration Plan

No data migration. Roll out as a normal code change; existing Firestore data
and collection layouts are unaffected. Update the four repo unit test files
to cover the new behaviors (transactional atomicity, error propagation,
no-op paths).
