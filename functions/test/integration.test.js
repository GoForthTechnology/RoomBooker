const test = require("firebase-functions-test")();
const admin = require("firebase-admin");

// Mock overlap_calculator before requiring index.js
jest.mock("../overlap_calculator", () => ({
  calculateOverlaps: jest.fn(),
}));

const {calculateOverlaps} = require("../overlap_calculator");

// Mock Firestore
const firestoreMock = {
  collection: jest.fn(),
  batch: jest.fn(),
};

const collectionMock = {
  doc: jest.fn(),
  where: jest.fn(),
};

const docMock = {
  collection: jest.fn(),
  delete: jest.fn(), // Add delete method for batch.delete(doc.ref)
};

const queryMock = {
  get: jest.fn(),
};

const batchMock = {
  set: jest.fn(),
  delete: jest.fn(),
  commit: jest.fn(),
};

// Setup mock return values
jest.spyOn(admin, "firestore").mockReturnValue(firestoreMock);
firestoreMock.collection.mockReturnValue(collectionMock);
firestoreMock.batch.mockReturnValue(batchMock);
collectionMock.doc.mockReturnValue(docMock);
collectionMock.where.mockReturnValue(queryMock);
docMock.collection.mockReturnValue(collectionMock); // For subcollections

// Now require index.js
const myFunctions = require("../index.js");

describe("onBookingWrite", () => {
  let wrapped;

  beforeAll(() => {
    wrapped = test.wrap(myFunctions.onBookingWrite);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  afterAll(() => {
    test.cleanup();
  });

  it("should calculate overlaps and save them", async () => {
    const orgID = "org1";
    const bookingID = "booking1";
    const bookingData = {
      roomID: "room1",
      eventStartTime: "2023-10-27T10:00:00.000Z",
      eventEndTime: "2023-10-27T11:00:00.000Z",
    };

    // Mock existing bookings in the same room
    const otherBookingData = {
      roomID: "room1",
      eventStartTime: "2023-10-27T10:30:00.000Z",
      eventEndTime: "2023-10-27T11:30:00.000Z",
    };

    const querySnapshot = {
      forEach: (callback) => {
        callback({id: "booking2", data: () => otherBookingData});
      },
    };

    // Mock get() for finding other bookings
    queryMock.get.mockResolvedValueOnce(querySnapshot);

    // Mock get() for removing existing overlaps (2 calls)
    const emptySnapshot = {forEach: () => {}};
    queryMock.get.mockResolvedValue(emptySnapshot);

    // Mock calculateOverlaps result
    const overlaps = [{
      bookingID1: bookingID,
      bookingID2: "booking2",
      startTime: "2023-10-27T10:30:00.000Z",
      endTime: "2023-10-27T11:00:00.000Z",
      startTime2: "2023-10-27T10:30:00.000Z",
      endTime2: "2023-10-27T11:00:00.000Z",
      roomID: "room1",
    }];
    calculateOverlaps.mockReturnValue(overlaps);

    // Create a Change object manually
    const change = {
      before: {
        exists: false,
        data: () => null,
        id: bookingID,
      },
      after: {
        exists: true,
        data: () => bookingData,
        id: bookingID,
      },
    };

    await wrapped(change, {params: {orgID, bookingID}});

    // Verify calculateOverlaps was called
    expect(calculateOverlaps).toHaveBeenCalledWith(
        expect.objectContaining(bookingData),
        bookingID,
        expect.arrayContaining([expect.objectContaining(otherBookingData)]),
    );

    // Verify batch commit was called
    expect(batchMock.commit).toHaveBeenCalled();

    // Verify overlaps were saved (2 sets per overlap: forward and reverse)
    expect(batchMock.set).toHaveBeenCalledTimes(2);
  });

  it("should remove overlaps if booking is deleted", async () => {
    const orgID = "org1";
    const bookingID = "booking1";

    // Mock get() for removing existing overlaps (2 calls)
    const overlapDoc = {ref: "ref1"};
    const overlapSnapshot = {
      forEach: (callback) => callback(overlapDoc),
    };
    queryMock.get.mockResolvedValue(overlapSnapshot);

    // Create a Change object (deletion) manually
    const changeMock = {
      before: {
        exists: true,
        data: () => ({foo: "bar"}),
        id: bookingID,
      },
      after: {
        exists: false,
        data: () => null,
        id: bookingID,
      },
    };

    await wrapped(changeMock, {params: {orgID, bookingID}});

    // Verify calculateOverlaps was NOT called
    expect(calculateOverlaps).not.toHaveBeenCalled();

    // Verify removeOverlaps was called (batch delete)
    expect(batchMock.delete).toHaveBeenCalled();
    expect(batchMock.commit).toHaveBeenCalled();
  });
});
