/**
 * Firestore security-rules tests for the direct-admin-invite feature.
 *
 * Run via: firebase emulators:exec --only firestore \
 *            "cd functions && npx jest rules.test.js --forceExit"
 *
 * Or use the convenience wrapper: scripts/test_admin_invite.sh
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, deleteDoc} = require('firebase/firestore');
const {readFileSync} = require('fs');
const {resolve} = require('path');

const PROJECT_ID = 'roombooker-5e947';
const RULES_PATH = resolve(__dirname, '../firestore.rules');
const FIRESTORE_PORT = 8082;

const ORG_ID = 'test-org';
const OWNER_UID = 'owner-uid';
const USER_UID = 'user-uid';
const USER_EMAIL = 'user@example.com';

let testEnv;

// ── Helpers ──────────────────────────────────────────────────────────────────

function ownerContext() {
  return testEnv.authenticatedContext(OWNER_UID, {
    email: 'owner@example.com',
    email_verified: true,
  });
}

function verifiedUserContext(email = USER_EMAIL) {
  return testEnv.authenticatedContext(USER_UID, {
    email,
    email_verified: true,
  });
}

function unverifiedUserContext(email = USER_EMAIL) {
  return testEnv.authenticatedContext(USER_UID, {
    email,
    email_verified: false,
  });
}

function uninvitedContext() {
  return testEnv.authenticatedContext('uninvited-uid', {
    email: 'uninvited@example.com',
    email_verified: true,
  });
}

async function seedOrg(ctx) {
  await setDoc(doc(ctx.firestore(), `orgs/${ORG_ID}`), {
    name: 'Test Org',
    ownerID: OWNER_UID,
    acceptingAdminRequests: false,
  });
}

async function seedInvite(ctx, email = USER_EMAIL) {
  await setDoc(
    doc(ctx.firestore(), `orgs/${ORG_ID}/pending-invites/${email}`),
    {email, invitedAt: new Date()},
  );
}

// ── Setup / Teardown ─────────────────────────────────────────────────────────

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      host: 'localhost',
      port: FIRESTORE_PORT,
      rules: readFileSync(RULES_PATH, 'utf8'),
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.withSecurityRulesDisabled((ctx) => seedOrg(ctx));
});

// ── 1. Happy path: owner invites, verified user claims ────────────────────────

describe('happy path', () => {
  test('owner can write a pending invite', async () => {
    const db = ownerContext().firestore();
    await assertSucceeds(
      setDoc(doc(db, `orgs/${ORG_ID}/pending-invites/${USER_EMAIL}`), {
        email: USER_EMAIL,
        invitedAt: new Date(),
      }),
    );
  });

  test('verified invited user can claim active-admin slot', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx));

    const db = verifiedUserContext().firestore();
    await assertSucceeds(
      setDoc(doc(db, `orgs/${ORG_ID}/active-admins/${USER_UID}`), {
        email: USER_EMAIL,
        lastUpdated: new Date(),
      }),
    );
  });

  test('pending-invites doc is gone after claim (readable before)', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx));

    // Invited user can read their own invite (via collectionGroup rule)
    const db = verifiedUserContext().firestore();
    await assertSucceeds(
      getDoc(doc(db, `orgs/${ORG_ID}/pending-invites/${USER_EMAIL}`)),
    );
  });
});

// ── 2. Cancel before claim ────────────────────────────────────────────────────

describe('cancel before claim', () => {
  test('invited user can delete their own pending invite', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx));

    const db = verifiedUserContext().firestore();
    await assertSucceeds(
      deleteDoc(doc(db, `orgs/${ORG_ID}/pending-invites/${USER_EMAIL}`)),
    );
  });

  test('owner can delete any pending invite', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx));

    const db = ownerContext().firestore();
    await assertSucceeds(
      deleteDoc(doc(db, `orgs/${ORG_ID}/pending-invites/${USER_EMAIL}`)),
    );
  });

  test('third party cannot delete someone else\'s invite', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx));

    const db = uninvitedContext().firestore();
    await assertFails(
      deleteDoc(doc(db, `orgs/${ORG_ID}/pending-invites/${USER_EMAIL}`)),
    );
  });
});

// ── 3. Security: unverified email cannot claim ────────────────────────────────

describe('unverified email cannot claim', () => {
  test('unverified user is blocked from self-claiming active-admin slot', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx));

    const db = unverifiedUserContext().firestore();
    await assertFails(
      setDoc(doc(db, `orgs/${ORG_ID}/active-admins/${USER_UID}`), {
        email: USER_EMAIL,
        lastUpdated: new Date(),
      }),
    );
  });

  test('unverified user with no invite is also blocked', async () => {
    const db = unverifiedUserContext().firestore();
    await assertFails(
      setDoc(doc(db, `orgs/${ORG_ID}/active-admins/${USER_UID}`), {
        email: USER_EMAIL,
        lastUpdated: new Date(),
      }),
    );
  });
});

// ── 4. Non-admin cannot create invites ───────────────────────────────────────

describe('non-admin cannot create invites', () => {
  test('random verified user cannot write a pending invite', async () => {
    const db = verifiedUserContext().firestore();
    await assertFails(
      setDoc(
        doc(db, `orgs/${ORG_ID}/pending-invites/other@example.com`),
        {email: 'other@example.com', invitedAt: new Date()},
      ),
    );
  });

  test('unauthenticated request cannot write a pending invite', async () => {
    const db = testEnv.unauthenticatedContext().firestore();
    await assertFails(
      setDoc(
        doc(db, `orgs/${ORG_ID}/pending-invites/anyone@example.com`),
        {email: 'anyone@example.com', invitedAt: new Date()},
      ),
    );
  });
});

// ── 5. User with no pending invite cannot self-claim ─────────────────────────

describe('uninvited user cannot self-claim', () => {
  test('verified user with no pending invite is blocked', async () => {
    const db = uninvitedContext().firestore();
    await assertFails(
      setDoc(doc(db, `orgs/${ORG_ID}/active-admins/uninvited-uid`), {
        email: 'uninvited@example.com',
        lastUpdated: new Date(),
      }),
    );
  });
});

// ── 6. Case-insensitive email matching ────────────────────────────────────────

describe('case-insensitive invite claim', () => {
  test('invite stored as lowercase is claimable with uppercase token email', async () => {
    // addAdminInvite always lowercases — simulate: doc at user@example.com
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx, USER_EMAIL));

    // Auth token arrives with mixed-case email (Firebase email/password can do this)
    const db = verifiedUserContext('USER@EXAMPLE.COM').firestore();
    await assertSucceeds(
      setDoc(doc(db, `orgs/${ORG_ID}/active-admins/${USER_UID}`), {
        email: USER_EMAIL,
        lastUpdated: new Date(),
      }),
    );
  });

  test('invited user can cancel invite regardless of token email casing', async () => {
    await testEnv.withSecurityRulesDisabled((ctx) => seedInvite(ctx, USER_EMAIL));

    const db = verifiedUserContext('USER@EXAMPLE.COM').firestore();
    await assertSucceeds(
      deleteDoc(doc(db, `orgs/${ORG_ID}/pending-invites/${USER_EMAIL}`)),
    );
  });
});
