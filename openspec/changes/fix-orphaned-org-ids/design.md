## Context

`UserProfile.orgIDs` is the source of truth for which orgs appear on a user's
landing screen. It is updated (added) whenever a user joins an org via request,
invite, or org creation. The removal side was never completed: `removeAdmin` has
the call commented out since the original codebase, and `denyAdminRequest` never
had one.

The existing `UserRepo.removeOrg(Transaction t, String userID, String orgID)`
method is already implemented and correct — it uses `t.update()` with
`FieldValue.arrayRemove`, which is idempotent and requires no prior read.

## Goals / Non-Goals

**Goals:**
- `UserProfile.orgIDs` is cleaned up atomically when an admin is removed.
- `UserProfile.orgIDs` is cleaned up atomically when an admin request is denied.

**Non-Goals:**
- Backfilling existing stale `orgIDs` for users who were removed before this fix.
- Fixing the `addOrg` transaction issue (separate known tech debt, tracked in
  `UserRepo`).
- Any UI changes.

## Decisions

### `removeAdmin`: uncomment the existing call

`UserRepo.removeOrg` uses only `t.update()` — no read — so it is safe to call
inside the existing transaction in `removeAdmin`. The defensive comment-out was
not warranted. Uncommenting is the full fix.

_Alternative considered_: call `removeOrg` outside the transaction (fire-and-
forget). Rejected — the transaction already exists and `removeOrg` is
transaction-safe, so there's no reason not to use it.

### `denyAdminRequest`: introduce a transaction

`denyAdminRequest` currently issues a bare `.delete()` with no transaction.
Introducing `_db.runTransaction` lets us call `_userRepo.removeOrg` inside it,
keeping the profile update atomic with the request deletion.

_Alternative considered_: add a second non-transactional `UserRepo.removeOrgDirectly`
method that doesn't require a `Transaction`. Rejected — introduces API surface
for a problem that is solved cleanly by adding a transaction.

## Risks / Trade-offs

[Stale profiles for previously-removed admins] → Not fixed by this change. The
org entry persists in their profile but all Firestore operations on that org are
denied by security rules, so no data is accessible. A one-time migration is out
of scope.

[`t.update()` fails if user profile doc does not exist] → `UserProfile` is
created on first login and is never deleted during normal operation. This edge
case cannot occur in practice. `arrayRemove` is also a no-op if the orgID is not
present, making the call safe even if the profile existed but lacked the entry.
