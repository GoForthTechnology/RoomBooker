## 1. Cloud Function Trigger

- [x] 1.1 Add `exports.onAdminInviteCreated` trigger in `functions/index.js` on `orgs/{orgID}/pending-invites/{email}` onCreate, following the v1 `functions.firestore.document().onCreate()` pattern
- [x] 1.2 Inside the trigger, derive the recipient from `context.params.email` and look up the org name with the existing `getOrg(orgID)` helper
- [x] 1.3 Call `sendEmail` with subject "You've been invited to join <org name>" and a body that names the org and includes a `<PORTAL_BASE_URL>/join/{orgID}` link, where `PORTAL_BASE_URL` defaults to `https://roombooker-5e947.web.app`
- [x] 1.4 Wrap the `sendEmail` call in a try/catch; log the error on failure but do not re-throw (consistent with `onAdminRequestRevoked`)

## 2. Tests

- [x] 2.1 Create `functions/test/admin_invite_created.test.js` with a test for the happy path: invite document created → `sendEmail` called with the correct recipient, subject, and a body containing the org name and join link
- [x] 2.2 Add a test for the error-suppression path: `sendEmail` throws → function resolves without propagating the error
- [x] 2.3 Run `npm test` in `functions/` and confirm all tests pass
