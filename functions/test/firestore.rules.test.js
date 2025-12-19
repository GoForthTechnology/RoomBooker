
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
        port: 8081,
      },
    });
  });

  afterAll(async () => {
    await testEnv.cleanup();
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();
  });

  const getDb = (auth) => testEnv.authenticatedContext(auth ? auth.uid : "alice").firestore();
  const getAdminDb = () => testEnv.unauthenticatedContext().firestore(); // Admin SDK bypasses rules, but for rules testing we often simulate admin user via auth

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
      // Add an admin
      const ownerDb = getDb({ uid: ownerID });
      // Owner can write to active-admins because they are admin (isOwner || exists in active-admins)
      // Wait, isOwner check: 
      // function isOwner(orgID) { return get(...).data.ownerID == request.auth.uid; }
      // So owner can write to active-admins?
      // Rules: match /active-admins/{userID} { allow write: if isAdmin(); }
      // isAdmin() { return isOwner(orgID) || ... }
      // Yes.
      await ownerDb.collection(`orgs/${orgID}/active-admins`).doc(adminID).set({});
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

      it("should fail if name is missing", async () => {
        const db = getDb({ uid: adminID });
        await assertFails(db.collection(`orgs/${orgID}/rooms`).doc("room2").set({
          // missing name
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

      it("should fail create if end time before start time", async () => {
        const db = getDb({ uid: regularUserID });
        const now = new Date();
        const earlier = new Date(now.getTime() - 3600000);

        await assertFails(db.collection(`orgs/${orgID}/request-details`).doc("req2").set({
          name: "Meeting",
          email: "test@example.com",
          eventName: "Strategy",
          eventStartTime: now,
          eventEndTime: earlier
        }));
      });

      it("should fail create if missing fields", async () => {
        const db = getDb({ uid: regularUserID });
        await assertFails(db.collection(`orgs/${orgID}/request-details`).doc("req3").set({
          name: "Meeting",
          // missing others
        }));
      });
    });
  });
});
