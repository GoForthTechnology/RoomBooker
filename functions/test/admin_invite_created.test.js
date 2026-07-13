const test = require("firebase-functions-test")();
const admin = require("firebase-admin");

// --- Firestore mock ---

const mailAdd = jest.fn();
const mailCollRef = {add: mailAdd};

const orgDocRef = {get: jest.fn()};
const orgsCollRef = {doc: jest.fn(() => orgDocRef)};

const firestoreMock = {
  collection: jest.fn((name) => {
    if (name === "orgs") return orgsCollRef;
    if (name === "mail") return mailCollRef;
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

describe("onAdminInviteCreated", () => {
  const handler = myFunctions.onAdminInviteCreated.run;
  const snap = {data: () => ({email: "invitee@example.com", invitedAt: new Date()})};
  const context = {params: {orgID: "org1", email: "invitee@example.com"}};

  afterEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  it("sends an invite email with the org name and join link", async () => {
    orgDocRef.get.mockResolvedValue({data: () => ({name: "St. Michael's"})});
    mailAdd.mockResolvedValue({});

    await handler(snap, context);

    expect(orgsCollRef.doc).toHaveBeenCalledWith("org1");
    expect(mailAdd).toHaveBeenCalledTimes(1);

    const mailDoc = mailAdd.mock.calls[0][0];
    expect(mailDoc.to).toBe("invitee@example.com");
    expect(mailDoc.message.subject).toContain("St. Michael's");
    expect(mailDoc.message.text).toContain("St. Michael's");
    expect(mailDoc.message.text).toContain("/join/org1");
  });

  it("resolves without throwing when sendEmail fails", async () => {
    orgDocRef.get.mockResolvedValue({data: () => ({name: "Test Org"})});
    mailAdd.mockRejectedValue(new Error("Firestore write failed"));

    await expect(handler(snap, context)).resolves.toBeUndefined();
  });
});
