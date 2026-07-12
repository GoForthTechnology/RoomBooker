const test = require("firebase-functions-test")();
const admin = require("firebase-admin");

// --- Firestore mock ---

const profileRef = {get: jest.fn(), update: jest.fn()};
const activeAdminRef = {get: jest.fn()};
const activeAdminsCollRef = {doc: jest.fn(() => activeAdminRef)};
const usersCollRef = {doc: jest.fn(() => profileRef)};

const orgDocRef = {
  collection: jest.fn((name) => {
    if (name === "active-admins") return activeAdminsCollRef;
    throw new Error(`Unexpected collection: ${name}`);
  }),
};
const orgsCollRef = {doc: jest.fn(() => orgDocRef)};

const firestoreMock = {
  collection: jest.fn((name) => {
    if (name === "orgs") return orgsCollRef;
    if (name === "users") return usersCollRef;
    throw new Error(`Unexpected collection: ${name}`);
  }),
};

jest.spyOn(admin, "firestore").mockReturnValue(firestoreMock);
admin.firestore.FieldValue = {
  arrayRemove: jest.fn((v) => ({_type: "arrayRemove", value: v})),
  serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
};

jest.mock("@google-cloud/secret-manager", () => ({
  SecretManagerServiceClient: jest.fn().mockImplementation(() => ({
    accessSecretVersion: jest.fn(),
  })),
}));

jest.mock("googleapis", () => ({
  google: {
    auth: {JWT: jest.fn()},
    meet: jest.fn(),
  },
}));

const myFunctions = require("../index.js");

describe("onAdminRequestDenied", () => {
  const handler = myFunctions.onAdminRequestDenied.run;
  const snap = {data: () => ({email: "user@example.com"})};
  const context = {params: {orgID: "org1", userID: "user1"}};

  afterEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  it("removes orgID from user profile when request was denied", async () => {
    activeAdminRef.get.mockResolvedValue({exists: false});
    profileRef.get.mockResolvedValue({exists: true});
    profileRef.update.mockResolvedValue();

    await handler(snap, context);

    expect(activeAdminsCollRef.doc).toHaveBeenCalledWith("user1");
    expect(usersCollRef.doc).toHaveBeenCalledWith("user1");
    expect(profileRef.update).toHaveBeenCalledWith({
      orgIDs: admin.firestore.FieldValue.arrayRemove("org1"),
    });
  });

  it("does not touch user profile when request was approved", async () => {
    activeAdminRef.get.mockResolvedValue({exists: true});

    await handler(snap, context);

    expect(profileRef.update).not.toHaveBeenCalled();
  });

  it("does not throw when user profile does not exist", async () => {
    activeAdminRef.get.mockResolvedValue({exists: false});
    profileRef.get.mockResolvedValue({exists: false});

    await expect(handler(snap, context)).resolves.toBeUndefined();
    expect(profileRef.update).not.toHaveBeenCalled();
  });
});
