## Context

Admin access is currently initiated by the user: they open a join link, submit a request, and the owner approves. The `active-admins/{uid}` subcollection is keyed by Firebase Auth UID. When an owner receives an out-of-band request to add someone, they cannot act unilaterally — they don't know the target user's UID, and there's no email → UID lookup available on the client.

## Goals / Non-Goals

**Goals:**
- Owner can pre-approve an email address as admin without knowing the user's UID
- Invite is automatically claimed the next time that user signs in or cold-starts the app
- Owner can cancel a pending invite before it is claimed
- No new packages or Cloud Functions required

**Non-Goals:**
- Email notification to the invited user (no transactional email in scope)
- Real-time auto-claim for users already active in the app (sign-out/restart is the fallback)
- Modifying the existing self-join request/approve flow

## Decisions

### 1. Subcollection `orgs/{orgID}/pending-invites/{email}` (not top-level)

**Alternatives considered:**
- Top-level `pending-invites/{email}` with `orgIDs` array — O(1) claim lookup and simpler rules, but write authorization cannot be scoped to a specific org at rule-evaluation time (Firestore rules cannot iterate arrays to call `isAdmin()` per orgID). This would require `isAuthenticated()` on writes, allowing any signed-in user to create invites for orgs they don't admin.

**Decision:** Subcollection under the org. The `orgID` is in the path, so the existing `isAdmin()` helper works for write authorization without any change.

Doc structure — email stored in both the ID and the body (body needed for collectionGroup query):
```
orgs/{orgID}/pending-invites/{email}:
  email: "user@example.com"   // duplicated from ID for collectionGroup query
  invitedAt: Timestamp
```

One document per org per invited email. Cancellation is a simple doc delete.

### 2. Firestore security rules: three distinct rules required

**Subcollection rule** (admin writes, email-gated reads within a known org):
```
match /orgs/{orgID}/pending-invites/{email} {
  allow read: if request.auth.token.email == email || isAdmin();
  allow create: if isAdmin();
  allow delete: if isAdmin() || request.auth.token.email == email;
}
```
Delete allows either an admin (cancellation) or the invited user themselves (claim cleanup).

**CollectionGroup wildcard rule** (allows claiming without knowing which orgs to check):
```
match /{path=**}/pending-invites/{email} {
  allow read: if isAuthenticated()
    && resource.data.email == request.auth.token.email;
}
```
The collectionGroup query in `claimPendingInvites()` uses `.where('email', '==', currentUser.email)`, which this rule satisfies. `FieldPath.documentId()` is not used because in a collectionGroup context it matches the full path, not just the last segment.

**Self-claim exception on `active-admins`** (required for claim to succeed):
The existing `active-admins` write rule is `isAdmin()` only. The claiming user is not yet an admin, so `claimPendingInvites()` would fail without a rule change. Add a self-claim `create` exception (not `write` — that would also allow update/delete before the user is a full admin):
```
match /active-admins/{userID} {
  allow read: if request.auth.uid == userID || isAdmin();
  allow create: if isAdmin()
    || (request.auth.uid == userID
        && exists(/databases/$(database)/documents/orgs/$(orgID)/pending-invites/$(request.auth.token.email)));
  allow update, delete: if isAdmin();
}
```
The `exists()` check ensures the self-claim is only permitted when a valid, admin-created invite exists. Since `pending-invites` creates require `isAdmin()`, this chain cannot be forged by the claiming user. The `request.auth.uid == userID` guard prevents writing to a different user's `active-admins` entry.

`request.auth.token.email` is reliably set by both Google Sign-In and email/password auth in Firebase.

### 3. Claim hook: dialog on org page load (replaces auth/LandingViewModel hooks)

**Original design** used fire-and-forget claim calls in `auth.dart` `SignedIn`/`UserCreated` actions and `LandingViewModel.init()`. This was abandoned because:
- Silent auto-claim gave users no visibility into why they suddenly had admin access
- The `FutureBuilder` in `OrgStateProvider` is one-shot; after auto-claim the page never re-evaluated admin status, so admin controls didn't appear without a manual page reload
- Removing the stream subscription used to track admin status live caused regressions for org owners

**Adopted approach**: `OrgStateProvider` checks for a pending invite immediately after the org loads (via a post-frame callback), shows a confirmation dialog, and on acceptance calls `claimInviteForOrg`:

```
OrgStateProvider.build()
  └─ FutureBuilder resolves with OrgState
  └─ addPostFrameCallback → _maybeShowInviteDialog(orgState)
       ├─ orgRepo.hasPendingInviteForOrg(orgID) → bool
       ├─ if true: showDialog → user accepts/declines
       └─ if accepted: claimInviteForOrg(orgID) → bool
            ├─ if true (claimed): orgState.updateAdminStatus(true) + snackbar
            └─ if false (invite gone): "Invitation no longer available" snackbar
```

`_inviteCheckStarted` guards against re-firing on widget rebuilds; it is reset by `_loadState()` so the check runs once per session/auth-change.

**New OrgRepo methods:**
- `hasPendingInviteForOrg(orgID)` — reads `orgs/{orgID}/pending-invites/{email}` directly (single-org check, no collectionGroup query)
- `claimInviteForOrg(orgID)` — runs a transaction that checks `!fresh.exists` and returns `false` if the invite is gone (race condition safety); returns `true` and fires `AdminInviteClaimed` analytics only if the write actually happened

**OrgState as ChangeNotifier:**
`OrgState` exposes `updateAdminStatus(bool)` which sets `_currentUserIsAdmin` and calls `notifyListeners()`. Consumers (e.g. `Consumer<OrgState>`) rebuild automatically, showing admin controls without a page reload. The `_resolvedState` field in `OrgStateProvider` is kept for snackbar access but `updateAdminStatus` is called via the `orgState` parameter (not `_resolvedState?`) to avoid a null race if `_loadState()` fires during the Firestore round-trip.

### 4. Invite cancellation — delete the subcollection doc directly

`cancelAdminInvite(orgID, email)` deletes `orgs/{orgID}/pending-invites/{email}`. No array manipulation needed — one doc per org per email. The `isAdmin()` delete rule covers this.

### 5. `OrgRepo` owns all invite operations

New methods on `OrgRepo` (consistent with existing admin-request methods):
- `addAdminInvite(orgID, email)` — write `orgs/{orgID}/pending-invites/{email.toLowerCase()}`
- `cancelAdminInvite(orgID, email)` — delete `orgs/{orgID}/pending-invites/{email}`
- `pendingInvites(orgID)` — stream of pending invite docs for owner UI
- `claimPendingInvites()` — collectionGroup query by email; for each match, transaction-writes `active-admins/{uid}` and deletes the invite doc, then calls `_userRepo.addOrg` separately (fire-and-forget, see Risks); entire method wraps all errors in try/catch and logs them rather than propagating, since all callers are fire-and-forget

**`AdminEntry` construction during claim:** `_activeAdminsRef` expects an `AdminEntry` with `email` and `lastUpdated` fields. The pending-invite doc stores `invitedAt`, not `lastUpdated`. `claimPendingInvites()` MUST construct a new `AdminEntry(email: claimedEmail, lastUpdated: DateTime.now())` rather than converting the invite doc directly.

## Risks / Trade-offs

**CollectionGroup wildcard rule covers any collection named `pending-invites`** → The `/{path=**}/pending-invites/{email}` rule allows reads from any subcollection with this name anywhere in the Firestore tree, not just under `/orgs`. Currently no other such collection exists; this is an accepted low risk, monitored by keeping the rule's `resource.data.email` filter tight.

**Self-claim rule on `active-admins` increases write surface** → Scoped to `create` only (not `update`/`delete`), so an invited-but-not-yet-admin user cannot modify or remove an existing `active-admins` entry. The `exists()` check is the gating condition; since pending-invites can only be created by admins, the chain is not forgeable.

**`_userRepo.addOrg` is not transactional** → `addOrg` performs its own separate Firestore write outside any transaction. It is wrapped in try/catch inside all transaction callbacks that call it — a failure logs a debug message but does not abort the surrounding transaction. The user becomes an admin (`active-admins` written) even if `addOrg` fails; the org will appear on their landing screen on the next successful call. Any call site that calls `addOrg` inside a Firestore transaction MUST wrap it in try/catch.

**`claimInviteForOrg` returns bool for race safety** → If the owner cancels the invite between `hasPendingInviteForOrg` returning true and the user clicking Accept, the transaction finds `!fresh.exists` and returns `false`. The caller treats `false` as "invite no longer available" and shows an informational snackbar without updating admin status or firing analytics.

**Multiple orgs = multiple independent transactions** → If a user has pending invites in two orgs, each is claimed in a separate transaction. If the second fails, they become admin in org 1 but not org 2, with the invite for org 2 preserved for retry on next org page load. This is correct behavior.

**Already-active-in-app users on other pages don't get prompted** → The dialog only fires when the user navigates to the invited org's page. If the user never visits that page in the current session, the invite remains pending. This is acceptable — the invite is dormant until the user chooses to visit the org.

**Email address as document ID** → Firestore allows `@` and `.` in doc IDs. Normalized to lowercase on write; `request.auth.token.email` from Firebase is already lowercase for Google and email/password accounts.

**Concurrent claim from multiple sessions** → Both would write `active-admins/{uid}` (idempotent via `create` rule) and race on deleting the invite doc. Firestore transaction semantics ensure one succeeds; the other retries and finds the doc gone — handled as a no-op.

**`removeAdmin` leaves orphan org in user profile** → The existing `removeAdmin` method has `_userRepo.removeOrg` commented out. When an invited admin is removed, the org remains in their `UserProfile.orgIDs` and still appears on their landing screen (but all org reads/writes will be denied). This is pre-existing debt, out of scope for this change.
