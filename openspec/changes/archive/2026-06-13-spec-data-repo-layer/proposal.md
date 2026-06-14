## Why

`packages/roombooker_core/lib/data/repos/` (~1,160 lines: `BookingRepo`,
`OrgRepo`, `RoomRepo`, `LogRepo`, `UserRepo`, `PreferencesRepo`) is the sole
Firestore/local-storage access layer underpinning every feature in the
product, yet it has no corresponding spec. The `data-model` spec documents
entity shapes but not repo contracts: collection layout, query/stream
semantics, transactional guarantees, or side effects (audit logging,
analytics events). This makes it easy for future changes to silently break
data-access guarantees (e.g. ordering, real-time updates, GDPR deletion
completeness) with no spec to check against. This is a documentation-only
change (no behavior changes) to backfill that gap.

## What Changes

- Add a new `data-repo-layer` capability spec documenting the contracts of
  each repo class:
  - **BookingRepo**: Firestore collection layout for booking requests
    (`pending-requests`, `confirmed-requests`, `denied-requests`,
    `request-details`), transactional create/update/delete/confirm/deny/
    revisit semantics, recurring-booking edit-choice handling
    (`thisInstance` / `thisAndFuture` / `all`), real-time `listRequests`
    query/stream behavior, and audit-log + analytics side effects on
    mutations.
  - **OrgRepo**: organization CRUD, visibility (`publiclyVisible`),
    admin-request workflow (request/approve/deny/remove admin), notification
    settings updates, and org listing for the current user vs. public orgs.
  - **RoomRepo**: room CRUD within an org and ordered-list (`orderKey`)
    reordering semantics.
  - **LogRepo**: audit log entry creation and paginated/filtered retrieval
    for booking requests.
  - **UserRepo**: user profile creation, org-membership management, and
    GDPR-style `deleteUserData` (profile + cross-collection booking-data
    deletion by email).
  - **PreferencesRepo**: local (`shared_preferences`-backed) user preference
    storage (default calendar view, last-opened org) and its
    load/persist/notify contract.
- No modifications to existing specs and no code changes — this is a spec
  backfill describing current, already-implemented behavior.

## Capabilities

### New Capabilities
- `data-repo-layer`: Contracts for the Firestore- and local-storage-backed
  repository classes in `roombooker_core/lib/data/repos/` that mediate all
  data access for bookings, organizations, rooms, audit logs, users, and
  local preferences.

### Modified Capabilities
(none)

## Impact

- **Affected code**: None (documentation only). Reference files:
  `packages/roombooker_core/lib/data/repos/{booking_repo,org_repo,room_repo,log_repo,user_repo,prefs_repo}.dart`.
- **Affected specs**: Adds `openspec/specs/data-repo-layer/spec.md`.
- **Dependencies**: Builds on entity shapes already defined in `data-model`
  and the booking-service rules in `instance-rescheduling`.
