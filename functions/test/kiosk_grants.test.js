const test = require("firebase-functions-test")();
const admin = require("firebase-admin");

// Mock Firestore
const docMock = {
  get: jest.fn(),
  set: jest.fn(),
  delete: jest.fn(),
  collection: jest.fn(),
};

const collectionMock = {
  doc: jest.fn(() => docMock),
};

docMock.collection.mockReturnValue(collectionMock);

const firestoreMock = {
  collection: jest.fn(() => collectionMock),
};

jest.spyOn(admin, "firestore").mockReturnValue(firestoreMock);
admin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
};

const myFunctions = require("../index.js");

describe("claimKioskGrant", () => {
  let wrapped;

  beforeAll(() => {
    wrapped = test.wrap(myFunctions.claimKioskGrant);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  it("rejects unauthenticated callers", async () => {
    await expect(wrapped({code: "123456"}, {auth: null})).rejects.toThrow();
  });

  it("rejects when code does not exist", async () => {
    docMock.get.mockResolvedValueOnce({exists: false});

    await expect(wrapped({code: "123456"}, {auth: {uid: "uid1"}})).rejects.toThrow();
    expect(docMock.set).not.toHaveBeenCalled();
  });

  it("rejects and deletes the code when it is expired", async () => {
    const past = new Date(Date.now() - 60000);
    docMock.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        orgID: "org1",
        roomID: "room1",
        orgName: "Org",
        roomName: "Room",
        expiresAt: past,
      }),
    });

    await expect(wrapped({code: "123456"}, {auth: {uid: "uid1"}})).rejects.toThrow();
    expect(docMock.delete).toHaveBeenCalled();
    expect(docMock.set).not.toHaveBeenCalled();
  });

  it("creates the grant, deletes the code, and returns handshake info", async () => {
    const future = new Date(Date.now() + 10 * 60000);
    docMock.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({
        orgID: "org1",
        roomID: "room1",
        orgName: "Org",
        roomName: "Room",
        expiresAt: future,
      }),
    });

    const result = await wrapped({code: "123456", deviceID: "device-1"}, {auth: {uid: "uid1"}});

    expect(docMock.set).toHaveBeenCalledWith({
      deviceID: "device-1",
      createdAt: "SERVER_TIMESTAMP",
    });
    expect(docMock.delete).toHaveBeenCalled();
    expect(result).toEqual({orgID: "org1", roomID: "room1", orgName: "Org", roomName: "Room"});
  });
});

describe("revokeKioskGrant", () => {
  let wrapped;

  beforeAll(() => {
    wrapped = test.wrap(myFunctions.revokeKioskGrant);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  it("rejects unauthenticated callers", async () => {
    await expect(wrapped({orgID: "org1", roomID: "room1"}, {auth: null})).rejects.toThrow();
  });

  it("rejects when orgID or roomID is missing", async () => {
    await expect(wrapped({orgID: "org1"}, {auth: {uid: "uid1"}})).rejects.toThrow();
    await expect(wrapped({}, {auth: {uid: "uid1"}})).rejects.toThrow();
  });

  it("deletes the grant document and is idempotent", async () => {
    docMock.delete.mockResolvedValueOnce();

    const result = await wrapped({orgID: "org1", roomID: "room1"}, {auth: {uid: "uid1"}});

    expect(docMock.delete).toHaveBeenCalled();
    expect(result).toEqual({success: true});
  });
});
