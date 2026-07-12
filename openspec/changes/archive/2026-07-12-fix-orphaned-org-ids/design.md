## Context

`UserProfile.orgIDs` is the source of truth for which orgs appear on a user's
landing screen. Keeping it in sync on the addition side always works because
users add themselves to orgs — they write to their own profile. On the removal
side, a third party (the org admin) is doing the removing, so client-side
writes to `users/{userID}` are rejected by the Firestore rule
`allow write: if request.auth.uid == userID`.

The project already uses Cloud Functions with the Admin SDK for all privileged
writes (kiosk grants, etc.). Two existing triggers on admin lifecycle events
(`onAdminRequestRevoked` on `active-admins` deletion, `onAdminRequestApproved`
on `active-admins` creation) confirm the pattern is established. The
`onAdminRequestRevoked` trigger is the natural hook for `removeAdmin` cleanup.

## Goals / Non-Goals

**Goals:**
- `UserProfile.orgIDs` is cleaned up when an active admin is removed.
- `UserProfile.orgIDs` is cleaned up when an admin request is denied.

**Non-Goals:**
- Backfilling stale `orgIDs` for users affected before this fix.
- Fixing the `addOrg` transaction issue in `UserRepo` (separate tech debt).
- Any UI or Flutter changes.

## Decisions

### Extend `onAdminRequestRevoked` for remove-admin cleanup

The existing `onDelete` trigger on `orgs/{orgID}/active-admins/{userID}` sends
the "access revoked" email. Adding `arrayRemove` of `orgID` from
`users/{userID}.orgIDs` is a natural extension of the same event. One function,
one trigger path, no duplication.

### New `onAdminRequestDenied` trigger for deny-request cleanup

`orgs/{orgID}/admin-requests/{userID}` is deleted on both approval and denial.
To distinguish them: since approval always writes `active-admins/{userID}` in
the same Firestore transaction as deleting the request, by the time the
`onDelete` trigger fires the `active-admins` doc either exists (approved) or
does not (denied). The check is safe because Firestore transactions commit
atomically.

_Alternative_: Use a Firestore rule to allow admins to strip a single orgID
from another user's profile. Rejected — the rule would need to compute a set
difference and then look up admin status on the inferred org, which Firestore
rule expressions cannot do cleanly.

### No Dart changes required

The commented-out `_userRepo.removeOrg` call in `removeAdmin` becomes dead
code and should be removed for clarity. No other Dart changes are needed.

## Risks / Trade-offs

[Async delivery] → Cloud Function triggers are eventually consistent. There is
a brief window after removal where the org still appears in the user's profile.
Acceptable: the same window exists today (infinite). Firestore rules already
block all access for the removed user.

[Approval race condition] → If the `admin-requests` onDelete trigger fires
before the `active-admins` write in an approval transaction, it could
incorrectly remove the org. This cannot happen: Firestore document triggers
fire after the write that caused them, and a transaction is atomic — both
writes commit together before any trigger fires.

[User profile doc not found] → `arrayRemove` on a missing document would
throw. User profiles are created on first login and are never deleted during
normal operation. Guard with a `.exists()` check in the function as a
defensive measure.

[`arrayRemove` when org not present] → Idempotent no-op. Safe in all cases,
including if `addOrg` had failed when the user originally submitted the request.
