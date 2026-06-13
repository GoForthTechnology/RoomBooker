## 1. Verify spec accuracy against source

- [ ] 1.1 Cross-check the "Booking Request Collection Layout",
      "Transactional Booking Status Transitions", "Recurring Booking Edit
      Choice Handling", "Booking Query and Streaming", "Audit Logging and
      Analytics on Booking Mutations", and "Request Details Caching"
      requirements against `packages/roombooker_core/lib/data/repos/booking_repo.dart`;
      fix any inaccuracies found.
- [ ] 1.2 Cross-check the "Organization CRUD and Visibility", "Admin Request
      Workflow", and "Organization Listing for Current User" requirements
      against `packages/roombooker_core/lib/data/repos/org_repo.dart`; fix
      any inaccuracies found.
- [ ] 1.3 Cross-check the "Room CRUD and Ordering" requirement against
      `packages/roombooker_core/lib/data/repos/room_repo.dart`; fix any
      inaccuracies found.
- [ ] 1.4 Cross-check the "Audit Log Entry Creation and Retrieval"
      requirement against `packages/roombooker_core/lib/data/repos/log_repo.dart`;
      fix any inaccuracies found.
- [ ] 1.5 Cross-check the "User Profile and Org Membership" and "User Data
      Deletion" requirements against
      `packages/roombooker_core/lib/data/repos/user_repo.dart`; fix any
      inaccuracies found.
- [ ] 1.6 Cross-check the "Local User Preferences Storage" requirement
      against `packages/roombooker_core/lib/data/repos/prefs_repo.dart`; fix
      any inaccuracies found.

## 2. Validation

- [ ] 2.1 Run `openspec validate spec-data-repo-layer --strict` (or
      equivalent) and confirm the change's spec delta is valid.
- [ ] 2.2 Confirm no code or test files were modified (this change is
      documentation-only).
