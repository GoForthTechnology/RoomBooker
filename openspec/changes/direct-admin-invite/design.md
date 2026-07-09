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

### 1. Top-level `pending-invites/{email}` collection (not a subcollection)

**Alternatives considered:**
- `orgs/{orgID}/pending-invites/{email}` subcollection — keeps data co-located with the org, but requires a Firestore `collectionGroup` query (or a wildcard security rule) for the claim lookup, adding complexity.
- Subcollection with collectionGroup rule — workable but introduces `/{path=**}` wildcard rules that are harder to reason about and test.

**Decision:** Top-level collection keyed by email. Document structure:
```
pending-invites/{email}:
  orgIDs: [orgID1, orgID2]   // supports multi-org invites
  createdAt: Timestamp
```

This gives O(1) claim lookup (`get pending-invites/{user.email}`), keeps the rule simple, and is consistent with how this codebase gates writes at the application layer (the Admin Settings UI is the access control, not the rule).

### 2. Firestore security rule: authenticated write, email-gated read

```
match /pending-invites/{email} {
  allow read: if request.auth.token.email == email;
  allow write: if isAuthenticated();
}
```

Write is `isAuthenticated()` (not `isAdmin()`), consistent with patterns elsewhere in this codebase (e.g. `pending-requests` has `allow create: if true`). The UI is the gatekeeper — only the Admin Settings screen exposes the invite action.

`request.auth.token.email` is reliably set by both Google Sign-In and email/password auth in Firebase.

### 3. Claim hooks: login actions + LandingViewModel

Two complementary hooks cover all practical entry points:

| Entry point | Hook | Covers |
|---|---|---|
| Fresh login (existing account) | `AuthStateChangeAction<SignedIn>` in `auth.dart` | Google SSO, email/password re-login |
| First registration | `AuthStateChangeAction<UserCreated>` in `auth.dart` | New Google or email account |
| Cold start with existing session | `LandingViewModel.init()` | App reopen without login screen |

The `LandingViewModel` hook fires before the `lastOpenedOrgId` redirect, so the claim completes (fire-and-forget) before navigation. Already-active users (no login, no cold start) are not covered; restart is the workaround.

### 4. Invite cancellation — remove orgID from array, delete doc when empty

`cancelAdminInvite(orgID, email)` uses `FieldValue.arrayRemove` on `orgIDs`. If the resulting array is empty, the doc is deleted. This keeps the collection clean and avoids orphan documents.

### 5. `OrgRepo` owns all invite operations

New methods on `OrgRepo` (consistent with existing admin-request methods):
- `addAdminInvite(orgID, email)` — create/update the pending-invite doc
- `cancelAdminInvite(orgID, email)` — remove orgID; delete doc if array empty
- `pendingInvites(orgID)` — stream of pending email invites for owner UI
- `claimPendingInvites()` — called at sign-in/cold-start; reads and claims the doc for the current user's email

## Risks / Trade-offs

**Authorization is app-enforced, not rule-enforced** → Any authenticated user could technically call `addAdminInvite` directly. Accepted: consistent with the existing codebase posture; the invite only grants access to an org the caller must already be an admin of to know the orgID.

**Already-active-in-app users don't get auto-claimed** → Workaround: restart the app. A real-time Firestore listener would handle this but adds listener lifecycle complexity for an extremely rare scenario.

**Email address as document ID** → Firestore allows `@` and `.` in doc IDs. Normalized to lowercase on write to avoid case-mismatch issues (Firebase Auth emails are lowercase by convention).

**Multi-org invites share one doc** → If an invite is cancelled for one org while the user is in the process of signing in, a race condition could claim the removed orgID. Mitigation: `claimPendingInvites` uses a transaction to read-then-delete atomically.
