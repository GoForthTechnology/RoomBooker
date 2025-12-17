const {calculateOverlaps} = require("../overlap_calculator");

describe("calculateOverlaps", () => {
  const baseBooking = {
    id: "booking1",
    roomID: "room1",
    eventStartTime: "2023-10-27T10:00:00.000Z",
    eventEndTime: "2023-10-27T11:00:00.000Z",
    recurrancePattern: {frequency: "never"},
  };

  it("should return empty array if no other bookings", () => {
    const result = calculateOverlaps(baseBooking, "booking1", []);
    expect(result).toEqual([]);
  });

  it("should return empty array if other booking is in different room", () => {
    const otherBooking = {
      id: "booking2",
      roomID: "room2",
      eventStartTime: "2023-10-27T10:00:00.000Z",
      eventEndTime: "2023-10-27T11:00:00.000Z",
      recurrancePattern: {frequency: "never"},
    };
    const result = calculateOverlaps(baseBooking, "booking1", [otherBooking]);
    expect(result).toEqual([]);
  });

  it("should return empty array if other booking is in same room " +
    "but different time", () => {
    const otherBooking = {
      id: "booking2",
      roomID: "room1",
      eventStartTime: "2023-10-27T11:00:00.000Z",
      eventEndTime: "2023-10-27T12:00:00.000Z",
      recurrancePattern: {frequency: "never"},
    };
    const result = calculateOverlaps(baseBooking, "booking1", [otherBooking]);
    expect(result).toEqual([]);
  });

  it("should return overlap if other booking overlaps in same room", () => {
    const otherBooking = {
      id: "booking2",
      roomID: "room1",
      eventStartTime: "2023-10-27T10:30:00.000Z",
      eventEndTime: "2023-10-27T11:30:00.000Z",
      recurrancePattern: {frequency: "never"},
    };
    const result = calculateOverlaps(baseBooking, "booking1", [otherBooking]);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      bookingID1: "booking1",
      bookingID2: "booking2",
      roomID: "room1",
    });
  });

  it("should detect overlap with daily recurrence", () => {
    const recurringBooking = {
      ...baseBooking,
      recurrancePattern: {frequency: "daily", period: 1},
    };

    // Booking 2 is tomorrow at the same time
    const otherBooking = {
      id: "booking2",
      roomID: "room1",
      eventStartTime: "2023-10-28T10:00:00.000Z",
      eventEndTime: "2023-10-28T11:00:00.000Z",
      recurrancePattern: {frequency: "never"},
    };

    const result = calculateOverlaps(recurringBooking,
        "booking1", [otherBooking]);
    expect(result).toHaveLength(1);
    expect(result[0].bookingID2).toBe("booking2");
  });

  it("should detect overlap with weekly recurrence", () => {
    // 2023-10-27 is a Friday
    const recurringBooking = {
      ...baseBooking,
      recurrancePattern: {frequency: "weekly", period: 1, weekday: ["Friday"]},
    };

    // Next Friday
    const otherBooking = {
      id: "booking2",
      roomID: "room1",
      eventStartTime: "2023-11-03T10:00:00.000Z",
      eventEndTime: "2023-11-03T11:00:00.000Z",
      recurrancePattern: {frequency: "never"},
    };

    const result = calculateOverlaps(recurringBooking,
        "booking1", [otherBooking]);
    expect(result).toHaveLength(1);
    expect(result[0].startTime).toBe("2023-11-03T10:00:00.000Z");
  });

  it("should not detect overlap if weekly recurrence does not match day",
      () => {
      // 2023-10-27 is a Friday
        const recurringBooking = {
          ...baseBooking,
          recurrancePattern: {
            frequency: "weekly", period: 1,
            weekday: ["Friday"],
          },
        };

        // Next Saturday (no overlap expected)
        const otherBooking = {
          id: "booking2",
          roomID: "room1",
          eventStartTime: "2023-11-04T10:00:00.000Z",
          eventEndTime: "2023-11-04T11:00:00.000Z",
          recurrancePattern: {frequency: "never"},
        };

        const result = calculateOverlaps(recurringBooking,
            "booking1", [otherBooking]);
        expect(result).toHaveLength(0);
      });

  it("should respect recurrence end date", () => {
    const recurringBooking = {
      ...baseBooking,
      recurrancePattern: {
        frequency: "daily",
        period: 1,
        end: "2023-10-29T00:00:00.000Z", // Ends after 2 days
      },
    };

    // Booking on 2023-10-30 (should be after end)
    const otherBooking = {
      id: "booking2",
      roomID: "room1",
      eventStartTime: "2023-10-30T10:00:00.000Z",
      eventEndTime: "2023-10-30T11:00:00.000Z",
      recurrancePattern: {frequency: "never"},
    };

    const result = calculateOverlaps(recurringBooking,
        "booking1", [otherBooking]);
    expect(result).toHaveLength(0);
  });

  it("should detect multiple overlaps between two recurring events", () => {
    const recurringBooking1 = {
      ...baseBooking,
      recurrancePattern: {
        frequency: "daily",
        period: 1,
        end: "2023-11-01T00:00:00.000Z", // 5 days: 27, 28, 29, 30, 31
      },
    };

    const recurringBooking2 = {
      id: "booking2",
      roomID: "room1",
      eventStartTime: "2023-10-27T10:30:00.000Z", // Overlaps 30 mins each day
      eventEndTime: "2023-10-27T11:30:00.000Z",
      recurrancePattern: {
        frequency: "daily",
        period: 1,
        end: "2023-11-01T00:00:00.000Z",
      },
    };

    const result = calculateOverlaps(recurringBooking1,
        "booking1", [recurringBooking2]);
    // Should overlap on Oct 27, 28, 29, 30, 31 (5 days)
    expect(result.length).toBeGreaterThanOrEqual(5);
  });
});
