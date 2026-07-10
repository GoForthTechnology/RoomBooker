
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const fs = require("fs");

const PROJECT_ID = "roombooker-5e947";

describe("Firestore Security Rules", () => {
  let testEnv;

  beforeAll(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: PROJECT_ID,
      firestore: {
        rules: fs.readFileSync("../firestore.rules", "utf8"),
        host: "127.0.0.1",
        port: 8082,
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  // Pass uid and any extra token claims (e.g. email_verified).
  const getDb = (auth) => {
    const uid = auth ? auth.uid : "alice";
    const { uid: _uid, ...extraClaims } = auth || {};
    return testEnv.authenticatedContext(uid, {
      email: `${uid}@test.com`,
      email_verified: true,
      ...extraClaims,
    }).firestore();
  };

  describe("Users Collection", () => {
    it("should allow a user to read/write their own document", async () => {
      const db = getDb({ uid: "user123" });
      const userRef = db.collection("users").doc("user123");
      await assertSucceeds(userRef.set({ name: "Alice" }));
      await assertSucceeds(userRef.get());
    });

    it("should not allow a user to read/write another user's document", async () => {
      const db = getDb({ uid: "user123" });
      const otherUserRef = db.collection("users").doc("otherUser");
      await assertFails(otherUserRef.set({ name: "Bob" }));
      await assertFails(otherUserRef.get());
    });
  });

  describe("Orgs Collection", () => {
    it("should allow public read access to orgs", async () => {
      const db = testEnv.unauthenticatedContext().firestore();
      const orgRef = db.collection("orgs").doc("org1");
      await assertSucceeds(orgRef.get());
    });

    it("should allow an authenticated user to create an org if they are the owner", async () => {
      const db = getDb({ uid: "owner1" });
      const orgRef = db.collection("orgs").doc("org1");
      await assertSucceeds(orgRef.set({
        name: "My Org",
        ownerID: "owner1",
        acceptingAdminRequests: true
      }));
    });

    it("should not allow creating an org with missing fields", async () => {
      const db = getDb({ uid: "owner1" });
      const orgRef = db.collection("orgs").doc("org1");
      await assertFails(orgRef.set({
        name: "My Org",
        ownerID: "owner1",
        // missing acceptingAdminRequests
      }));
    });

    it("should not allow creating an org if ownerID does not match auth", async () => {
      const db = getDb({ uid: "user1" });
      const orgRef = db.collection("orgs").doc("org1");
      await assertFails(orgRef.set({
        name: "My Org",
        ownerID: "otherUser",
        acceptingAdminRequests: true
      }));
    });
  });

  describe("Org Subcollections", () => {
    // Setup helper to create an org and get context
    async function setupOrg(orgID, ownerID) {
      // We need to use system/admin context to setup initial state to bypass normal rules if needed,
      // but since we just tested creation, we can use valid creation.
      // Actually, rules-unit-testing bypasses rules if we use proper setup or just use a valid user.
      // Let's us a valid owner to create the org.
      const ownerDb = getDb({ uid: ownerID });
      await ownerDb.collection("orgs").doc(orgID).set({
        name: "Test Org",
        ownerID: ownerID,
        acceptingAdminRequests: true
      });
    }

    const orgID = "testOrg";
    const ownerID = "ownerUser";
    const adminID = "adminUser";
    const regularUserID = "regularUser";

    beforeEach(async () => {
      await setupOrg(orgID, ownerID);
      // Seed the admin entry bypassing rules — we test rule behaviour separately.
      await testEnv.withSecurityRulesDisabled(async (ctx) => {
        await ctx.firestore()
          .collection(`orgs/${orgID}/active-admins`)
          .doc(adminID)
          .set({ email: `${adminID}@test.com`, lastUpdated: new Date() });
      });
    });

    describe("active-admins", () => {
      it("should allow admin/owner to write", async () => {
        const db = getDb({ uid: ownerID });
        await assertSucceeds(db.collection(`orgs/${orgID}/active-admins`).doc("newAdmin").set({}));
      });

      it("should not allow regular user to write", async () => {
        const db = getDb({ uid: regularUserID });
        await assertFails(db.collection(`orgs/${orgID}/active-admins`).doc("newAdmin").set({}));
      });

      it("should allow user to see their own admin status", async () => {
        const db = getDb({ uid: adminID });
        await assertSucceeds(db.collection(`orgs/${orgID}/active-admins`).doc(adminID).get());
      });
    });

    describe("admin-requests", () => {
      it("should allow user to create a request for themselves", async () => {
        const db = getDb({ uid: regularUserID });
        await assertSucceeds(db.collection(`orgs/${orgID}/admin-requests`).doc(regularUserID).set({}));
      });

      it("should not allow user to create request for others", async () => {
        const db = getDb({ uid: regularUserID });
        await assertFails(db.collection(`orgs/${orgID}/admin-requests`).doc("otherUser").set({}));
      });

      it("should allow admin to read requests", async () => {
        const db = getDb({ uid: adminID });
        // Create a request first
        const userDb = getDb({ uid: regularUserID });
        await userDb.collection(`orgs/${orgID}/admin-requests`).doc(regularUserID).set({});

        await assertSucceeds(db.collection(`orgs/${orgID}/admin-requests`).doc(regularUserID).get());
      });
    });

    describe("rooms", () => {
      it("should allow public read", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await assertSucceeds(db.collection(`orgs/${orgID}/rooms`).doc("room1").get());
      });

      it("should allow admin to create room", async () => {
        const db = getDb({ uid: adminID });
        await assertSucceeds(db.collection(`orgs/${orgID}/rooms`).doc("room1").set({
          name: "Conference Room"
        }));
      });

      it("allows admin write even when name field is absent (no field validation in rules)", async () => {
        // Firestore rules for rooms only check isAdmin(), not field presence.
        const db = getDb({ uid: adminID });
        await assertSucceeds(db.collection(`orgs/${orgID}/rooms`).doc("room2").set({
          // missing name — rules do not validate
        }));
      });

      it("should not allow regular user to create room", async () => {
        const db = getDb({ uid: regularUserID });
        await assertFails(db.collection(`orgs/${orgID}/rooms`).doc("room3").set({
          name: "Hacker Room"
        }));
      });
    });

    describe("pending-requests", () => {
      it("should allow anyone to create a request", async () => {
        const db = getDb({ uid: regularUserID });
        await assertSucceeds(db.collection(`orgs/${orgID}/pending-requests`).add({
          someData: "test" // Schema not strictly enforced here per rules
        }));
      });

      it("should allow anyone to read", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await assertSucceeds(db.collection(`orgs/${orgID}/pending-requests`).limit(1).get());
      });
    });

    describe("request-details", () => {
      it("should allow create with valid fields", async () => {
        // "allow create: if true && hasAll(...) ..." matches anyone? 
        // The rule says `allow create: if true ...` so yes, anyone can create if valid.
        // Wait, the rule is `allow create: if true && hasAll(...) ...` inside `match /request-details/{requestID}`
        // So unauthenticated? `request.auth` is not checked.

        const db = getDb({ uid: regularUserID });
        const now = new Date();
        const later = new Date(now.getTime() + 3600000);

        await assertSucceeds(db.collection(`orgs/${orgID}/request-details`).doc("req1").set({
          name: "Meeting",
          email: "test@example.com",
          eventName: "Strategy",
          eventStartTime: now,
          eventEndTime: later
        }));
      });

      it("allows create even if end time before start time (no timestamp validation in rules)", async () => {
        // request-details rules say `allow create: if true` — no field validation.
        const db = getDb({ uid: regularUserID });
        const now = new Date();
        const earlier = new Date(now.getTime() - 3600000);

        await assertSucceeds(db.collection(`orgs/${orgID}/request-details`).doc("req2").set({
          name: "Meeting",
          email: "test@example.com",
          eventName: "Strategy",
          eventStartTime: now,
          eventEndTime: earlier
        }));
      });

      it("allows create with missing fields (no field validation in rules)", async () => {
        // request-details rules say `allow create: if true` — no field validation.
        const db = getDb({ uid: regularUserID });
        await assertSucceeds(db.collection(`orgs/${orgID}/request-details`).doc("req3").set({
          name: "Meeting",
          // missing others
        }));
      });
    });
  });

  describe("Kiosk Access Control", () => {
    const orgID = "kioskOrg";
    const ownerID = "kioskOwner";
    const roomID = "room1";
    const otherRoomID = "room2";
    const kioskUid = "kioskUid";
    const requestID = "req1";
    const otherRequestID = "req2";

    beforeEach(async () => {
      const ownerDb = getDb({ uid: ownerID });
      await ownerDb.collection("orgs").doc(orgID).set({
        name: "Kiosk Org",
        ownerID: ownerID,
        acceptingAdminRequests: true,
      });

      // Seed data that clients cannot write directly (kiosk-grants), plus
      // confirmed-requests used by the request-details scoping rule.
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.doc(`orgs/${orgID}/rooms/${roomID}/kiosk-grants/${kioskUid}`).set({
          deviceID: "device-1",
          createdAt: new Date(),
        });
        await db.doc(`orgs/${orgID}/confirmed-requests/${requestID}`).set({ roomID });
        await db.doc(`orgs/${orgID}/confirmed-requests/${otherRequestID}`).set({ roomID: otherRoomID });
      });
    });

    describe("kiosk-grants", () => {
      it("allows an admin to read a room's grants", async () => {
        const db = getDb({ uid: ownerID });
        await assertSucceeds(db.doc(`orgs/${orgID}/rooms/${roomID}/kiosk-grants/${kioskUid}`).get());
      });

      it("denies clients from writing grants directly", async () => {
        const db = getDb({ uid: kioskUid });
        await assertFails(db.doc(`orgs/${orgID}/rooms/${roomID}/kiosk-grants/${kioskUid}`).set({ deviceID: "hacked" }));
      });
    });

    describe("request-details", () => {
      it("allows an authorized kiosk to read details for its own room", async () => {
        const db = getDb({ uid: kioskUid });
        await assertSucceeds(db.doc(`orgs/${orgID}/request-details/${requestID}`).get());
      });

      it("denies an authorized kiosk reading details for another room", async () => {
        const db = getDb({ uid: kioskUid });
        await assertFails(db.doc(`orgs/${orgID}/request-details/${otherRequestID}`).get());
      });

      it("denies a client with no grant", async () => {
        const db = getDb({ uid: "randomUser" });
        await assertFails(db.doc(`orgs/${orgID}/request-details/${requestID}`).get());
      });

      it("denies an unauthenticated client", async () => {
        const db = testEnv.unauthenticatedContext().firestore();
        await assertFails(db.doc(`orgs/${orgID}/request-details/${requestID}`).get());
      });
    });

    describe("confirmed-requests", () => {
      it("allows an authorized kiosk to create a booking for its own room", async () => {
        const db = getDb({ uid: kioskUid });
        await assertSucceeds(db.collection(`orgs/${orgID}/confirmed-requests`).add({ roomID }));
      });

      it("denies an authorized kiosk creating a booking for another room", async () => {
        const db = getDb({ uid: kioskUid });
        await assertFails(db.collection(`orgs/${orgID}/confirmed-requests`).add({ roomID: otherRoomID }));
      });

      it("denies a client with no grant from creating a booking", async () => {
        const db = getDb({ uid: "randomUser" });
        await assertFails(db.collection(`orgs/${orgID}/confirmed-requests`).add({ roomID }));
      });
    });

    describe("request-logs", () => {
      it("allows an authorized kiosk to create a log entry for a booking in its own room", async () => {
        const db = getDb({ uid: kioskUid });
        await assertSucceeds(db.collection(`orgs/${orgID}/request-logs`).add({
          requestID,
          action: "create",
          timestamp: new Date().toISOString(),
        }));
      });

      it("denies an authorized kiosk creating a log entry for a booking in another room", async () => {
        const db = getDb({ uid: kioskUid });
        await assertFails(db.collection(`orgs/${orgID}/request-logs`).add({
          requestID: otherRequestID,
          action: "create",
          timestamp: new Date().toISOString(),
        }));
      });

      it("denies a client with no grant from creating a log entry", async () => {
        const db = getDb({ uid: "randomUser" });
        await assertFails(db.collection(`orgs/${orgID}/request-logs`).add({
          requestID,
          action: "create",
          timestamp: new Date().toISOString(),
        }));
      });

      it("denies an authorized kiosk reading log entries", async () => {
        const db = getDb({ uid: kioskUid });
        await assertFails(db.collection(`orgs/${orgID}/request-logs`).get());
      });
    });
  });
});
