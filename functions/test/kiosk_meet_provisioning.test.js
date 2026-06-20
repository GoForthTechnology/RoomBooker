const test = require("firebase-functions-test")();
const admin = require("firebase-admin");

// --- Firestore mock ---

const errorDocRef = {set: jest.fn(), id: "error-doc-id"};
const bookingDocRef = {delete: jest.fn()};
const detailsDocRef = {get: jest.fn(), update: jest.fn(), delete: jest.fn()};
const errorsCollectionRef = {doc: jest.fn(() => errorDocRef)};

const roomDocRef = {collection: jest.fn(() => errorsCollectionRef)};
const roomsCollectionRef = {doc: jest.fn(() => roomDocRef)};
const confirmedCollectionRef = {doc: jest.fn(() => bookingDocRef)};
const requestDetailsCollectionRef = {doc: jest.fn(() => detailsDocRef)};

const orgDocRef = {
  collection: jest.fn((name) => {
    if (name === "rooms") return roomsCollectionRef;
    if (name === "confirmed-requests") return confirmedCollectionRef;
    if (name === "request-details") return requestDetailsCollectionRef;
    throw new Error(`Unexpected collection: ${name}`);
  }),
};
const orgsCollectionRef = {doc: jest.fn(() => orgDocRef)};
const firestoreMock = {collection: jest.fn(() => orgsCollectionRef)};

jest.spyOn(admin, "firestore").mockReturnValue(firestoreMock);
admin.firestore.FieldValue = {
  serverTimestamp: jest.fn(() => "SERVER_TIMESTAMP"),
};

// --- googleapis Meet mock ---

const mockSpacesCreate = jest.fn();
const mockMeetClient = {spaces: {create: mockSpacesCreate}};

jest.mock("googleapis", () => ({
  google: {
    auth: {
      GoogleAuth: jest.fn().mockImplementation(() => ({getClient: jest.fn()})),
    },
    meet: jest.fn(() => mockMeetClient),
  },
}));

// --- Secret Manager mock ---

const mockAccessSecretVersion = jest.fn();
jest.mock("@google-cloud/secret-manager", () => ({
  SecretManagerServiceClient: jest.fn().mockImplementation(() => ({
    accessSecretVersion: mockAccessSecretVersion,
  })),
}));

// Pre-seed a valid secret so getMeetClient resolves
mockAccessSecretVersion.mockResolvedValue([
  {
    payload: {
      data: Buffer.from(JSON.stringify({type: "service_account"})),
    },
  },
]);

const myFunctions = require("../index.js");

describe("onKioskBookingCreated", () => {
  const handler = myFunctions.onKioskBookingCreated.run;

  afterEach(() => {
    jest.clearAllMocks();
    // Re-seed secret mock after clearAllMocks
    mockAccessSecretVersion.mockResolvedValue([
      {
        payload: {
          data: Buffer.from(JSON.stringify({type: "service_account"})),
        },
      },
    ]);
  });

  afterAll(() => {
    test.cleanup();
  });

  const makeSnap = (data) => ({data: () => data});

  const makeContext = () => ({
    params: {orgID: "org1", bookingID: "booking1"},
  });

  it("ignores non-kiosk bookings", async () => {
    const snap = makeSnap({bookedVia: "portal", roomID: "room1"});
    await handler(snap, makeContext());
    expect(detailsDocRef.get).not.toHaveBeenCalled();
    expect(mockSpacesCreate).not.toHaveBeenCalled();
  });

  it("skips Meet API when meetingUrl already set (idempotency guard)", async () => {
    const snap = makeSnap({bookedVia: "kiosk", roomID: "room1"});
    detailsDocRef.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({meetingUrl: "https://meet.google.com/existing"}),
    });

    await handler(snap, makeContext());

    expect(mockSpacesCreate).not.toHaveBeenCalled();
    expect(detailsDocRef.update).not.toHaveBeenCalled();
  });

  it("creates Meet space and writes meetingUrl on success", async () => {
    const snap = makeSnap({bookedVia: "kiosk", roomID: "room1"});
    detailsDocRef.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({meetingUrl: null}),
    });
    mockSpacesCreate.mockResolvedValueOnce({
      data: {meetingUri: "https://meet.google.com/abc-defg-hij"},
    });

    await handler(snap, makeContext());

    expect(mockSpacesCreate).toHaveBeenCalledWith({
      requestBody: {config: {accessType: "OPEN"}},
    });
    expect(detailsDocRef.update).toHaveBeenCalledWith({
      meetingUrl: "https://meet.google.com/abc-defg-hij",
    });
    expect(errorDocRef.set).not.toHaveBeenCalled();
    expect(bookingDocRef.delete).not.toHaveBeenCalled();
  });

  it("writes error doc and deletes booking on Meet API failure", async () => {
    const snap = makeSnap({bookedVia: "kiosk", roomID: "room1"});
    detailsDocRef.get.mockResolvedValueOnce({
      exists: true,
      data: () => ({meetingUrl: null}),
    });
    mockSpacesCreate.mockRejectedValueOnce(new Error("Meet API unavailable"));

    await handler(snap, makeContext());

    expect(errorDocRef.set).toHaveBeenCalledWith({
      bookingID: "booking1",
      message: "Couldn't generate Meet link. Please try again.",
      timestamp: "SERVER_TIMESTAMP",
    });
    expect(bookingDocRef.delete).toHaveBeenCalled();
    expect(detailsDocRef.delete).toHaveBeenCalled();
    expect(detailsDocRef.update).not.toHaveBeenCalled();
  });

  it("writes error doc and deletes booking when request-details doc is missing", async () => {
    const snap = makeSnap({bookedVia: "kiosk", roomID: "room1"});
    detailsDocRef.get.mockResolvedValueOnce({exists: false, data: () => ({})});
    mockSpacesCreate.mockRejectedValueOnce(new Error("some error"));

    await handler(snap, makeContext());

    expect(errorDocRef.set).toHaveBeenCalled();
    expect(bookingDocRef.delete).toHaveBeenCalled();
  });
});
