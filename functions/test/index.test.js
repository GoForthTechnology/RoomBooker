/* global describe, it, expect */

const {bookingInfo} = require("../index.js");


describe("bookingInfo", () => {
  it("should return correctly formatted booking information", () => {
    const eventName = "Test Event";
    const data = {
      roomName: "Room A",
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
    };

    const expected = `
  Event: Test Event
  Room: Room A
  Start Time: 10:00 AM
  End Time: 11:00 AM`;

    const result = bookingInfo(eventName, data);
    expect(result).toEqual(expected);
  });
});

const {getUpdates} = require("../index.js"); // Assuming getUpdates is exported

describe("getUpdates", () => {
  it("should return an empty array if no values have changed", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
    };
    const newValue = {...oldValue}; // Create a deep copy

    const result = getUpdates(oldValue, newValue);
    expect(result).toEqual([]);
  });

  it("should return updates for changed eventStartTime", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
    };
    const newValue = {
      eventStartTime: "10:30 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
    };

    const expected = ["Event Start Time: 10:00 AM -> 10:30 AM"];
    const result = getUpdates(oldValue, newValue);
    expect(result).toEqual(expected);
  });

  it("should return updates for changed eventEndTime", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
    };
    const newValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "12:00 PM",
      roomName: "Room A",
    };

    const expected = ["Event End Time: 11:00 AM -> 12:00 PM"];
    const result = getUpdates(oldValue, newValue);
    expect(result).toEqual(expected);
  });

  it("should return updates for changed roomName", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
    };
    const newValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room B",
    };

    const expected = ["Room Name: Room A -> Room B"];
    const result = getUpdates(oldValue, newValue);
    expect(result).toEqual(expected);
  });

  it("should return updates for added recurrence overrides", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
    };
    const newValue = {
      ...oldValue,
      recurranceOverrides: {
        "2024-01-01T10:00:00.000Z": {
          eventStartTime: "10:30 AM",
          eventEndTime: "11:30 AM",
          roomName: "Room B",
        },
        "2024-01-08T10:00:00.000Z": null, // cancellation
      },
    };

    const result = getUpdates(oldValue, newValue);
    const expected = [
      "Added override for 2024-01-01:",
      "  - Room Name: Room B",
      "  - Event Start Time: 10:30 AM",
      "  - Event End Time: 11:30 AM",
      "Cancelled occurrence on 2024-01-08",
    ];
    // Sort both arrays to make the test independent of property order.
    expect(result.sort()).toEqual(expected.sort());
  });

  it("should return updates for modified recurrence overrides", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
      recurranceOverrides: {
        "2024-01-01T10:00:00.000Z": {
          eventStartTime: "10:30 AM",
          eventEndTime: "11:30 AM",
          roomName: "Room B",
        },
        "2024-01-08T10:00:00.000Z": null,
        "2024-01-15T10:00:00.000Z": {
          eventStartTime: "9:00 AM",
          eventEndTime: "10:00 AM",
          roomName: "Room C",
        },
      },
    };
    const newValue = {
      ...oldValue,
      recurranceOverrides: {
        "2024-01-01T10:00:00.000Z": { // modified
          eventStartTime: "10:45 AM",
          eventEndTime: "11:30 AM",
          roomName: "Room B",
        },
        "2024-01-08T10:00:00.000Z": { // cancellation -> override
          eventStartTime: "10:00 AM",
          eventEndTime: "11:00 AM",
          roomName: "Room D",
        },
        "2024-01-15T10:00:00.000Z": null, // override -> cancellation
      },
    };

    const result = getUpdates(oldValue, newValue);
    const expected = [
      "Updated override for 2024-01-01:",
      "  - Event Start Time: 10:30 AM -> 10:45 AM",
      "Updated occurrence on 2024-01-08 (was cancelled):",
      "  - Room Name: Room D",
      "  - Event Start Time: 10:00 AM",
      "  - Event End Time: 11:00 AM",
      "Cancelled occurrence on 2024-01-15 (was an override)",
    ];
    expect(result.sort()).toEqual(expected.sort());
  });

  it("should return updates for removed recurrence overrides", () => {
    const oldValue = {
      eventStartTime: "10:00 AM",
      eventEndTime: "11:00 AM",
      roomName: "Room A",
      recurranceOverrides: {
        "2024-01-01T10:00:00.000Z": {
          eventStartTime: "10:30 AM",
          eventEndTime: "11:30 AM",
          roomName: "Room B",
        },
        "2024-01-08T10:00:00.000Z": null,
      },
    };
    const newValue = {
      ...oldValue,
      recurranceOverrides: {},
    };

    const result = getUpdates(oldValue, newValue);
    const expected = [
      "Removed override for 2024-01-01",
      "Removed cancellation for 2024-01-08",
    ];
    expect(result.sort()).toEqual(expected.sort());
  });
});
