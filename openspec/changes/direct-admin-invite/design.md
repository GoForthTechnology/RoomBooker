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
The existing `active-admins` write rule is `isAdmin()` only. The claiming user is not yet an admin, so `claimPendingInvites()` would fail without a rule change. Add a self-claim exception:
```
match /active-admins/{userID} {
  allow read: if request.auth.uid == userID || isAdmin();
  allow write: if isAdmin()
    || (request.auth.uid == userID
        && exists(/databases/$(database)/documents/orgs/$(orgID)/pending-invites/$(request.auth.token.email)));
}
```
The `exists()` check ensures the self-claim is only permitted when a valid, admin-created invite exists. Since `pending-invites` writes require `isAdmin()`, this chain cannot be forged by the claiming user.

`request.auth.token.email` is reliably set by both Google Sign-In and email/password auth in Firebase.

### 3. Claim hooks: login actions + LandingViewModel

Two complementary hooks cover all practical entry points:

| Entry point | Hook | Covers |
|---|---|---|
| Fresh login (existing account) | `AuthStateChangeAction<SignedIn>` in `auth.dart` | Google SSO, email/password re-login |
| First registration | `AuthStateChangeAction<UserCreated>` in `auth.dart` | New Google or email account |
| Cold start with existing session | `LandingViewModel.init()` | App reopen without login screen |

The `LandingViewModel` hook fires before the `lastOpenedOrgId` redirect, so the claim completes (fire-and-forget) before navigation. Already-active users (no login, no cold start) are not covered; restart is the workaround.

### 4. Invite cancellation — delete the subcollection doc directly

`cancelAdminInvite(orgID, email)` deletes `orgs/{orgID}/pending-invites/{email}`. No array manipulation needed — one doc per org per email. The `isAdmin()` delete rule covers this.

### 5. `OrgRepo` owns all invite operations

New methods on `OrgRepo` (consistent with existing admin-request methods):
- `addAdminInvite(orgID, email)` — write `orgs/{orgID}/pending-invites/{email.toLowerCase()}`
- `cancelAdminInvite(orgID, email)` — delete `orgs/{orgID}/pending-invites/{email}`
- `pendingInvites(orgID)` — stream of pending invite docs for owner UI
- `claimPendingInvites()` — collectionGroup query by email; for each match, transaction-writes `active-admins/{uid}`, adds org to user profile, and deletes the invite doc

## Risks / Trade-offs

**CollectionGroup wildcard rule covers any collection named `pending-invites`** → The `/{path=**}/pending-invites/{email}` rule allows reads from any subcollection with this name anywhere in the Firestore tree, not just under `/orgs`. Currently no other such collection exists; this is an accepted low risk, monitored by keeping the rule's `resource.data.email` filter tight.

**Self-claim rule on `active-admins` increases write surface** → The added `exists()` check on pending-invites is the gating condition; since pending-invites can only be created by admins, the chain is not forgeable. The risk is that the `exists()` call adds one extra Firestore read per `active-admins` write — negligible cost.

**Already-active-in-app users don't get auto-claimed** → Workaround: restart the app. A real-time Firestore listener would handle this but adds listener lifecycle complexity for an extremely rare scenario.

**Email address as document ID** → Firestore allows `@` and `.` in doc IDs. Normalized to lowercase on write; `request.auth.token.email` from Firebase is already lowercase for Google and email/password accounts.

**Concurrent claim from multiple sessions** → Both would write `active-admins/{uid}` (idempotent) and race on deleting the invite doc. Firestore transaction semantics ensure one succeeds; the other retries and finds the doc gone — handled as a no-op.
