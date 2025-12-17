const { calculateOverlaps } = require('../overlap_calculator');

describe('calculateOverlaps', () => {
  const baseBooking = {
    id: 'booking1',
    roomID: 'room1',
    eventStartTime: '2023-10-27T10:00:00.000Z',
    eventEndTime: '2023-10-27T11:00:00.000Z',
    recurrancePattern: { frequency: 'never' }
  };

  it('should return empty array if no other bookings', () => {
    const result = calculateOverlaps(baseBooking, 'booking1', []);
    expect(result).toEqual([]);
  });

  it('should return empty array if other booking is in different room', () => {
    const otherBooking = {
      id: 'booking2',
      roomID: 'room2',
      eventStartTime: '2023-10-27T10:00:00.000Z',
      eventEndTime: '2023-10-27T11:00:00.000Z',
      recurrancePattern: { frequency: 'never' }
    };
    const result = calculateOverlaps(baseBooking, 'booking1', [otherBooking]);
    expect(result).toEqual([]);
  });

  it('should return empty array if other booking is in same room but different time', () => {
    const otherBooking = {
      id: 'booking2',
      roomID: 'room1',
      eventStartTime: '2023-10-27T11:00:00.000Z',
      eventEndTime: '2023-10-27T12:00:00.000Z',
      recurrancePattern: { frequency: 'never' }
    };
    const result = calculateOverlaps(baseBooking, 'booking1', [otherBooking]);
    expect(result).toEqual([]);
  });

  it('should return overlap if other booking overlaps in same room', () => {
    const otherBooking = {
      id: 'booking2',
      roomID: 'room1',
      eventStartTime: '2023-10-27T10:30:00.000Z',
      eventEndTime: '2023-10-27T11:30:00.000Z',
      recurrancePattern: { frequency: 'never' }
    };
    const result = calculateOverlaps(baseBooking, 'booking1', [otherBooking]);
    expect(result).toHaveLength(1);
    expect(result[0]).toMatchObject({
      bookingID1: 'booking1',
      bookingID2: 'booking2',
      roomID: 'room1'
    });
  });

  it('should detect overlap with daily recurrence', () => {
    const recurringBooking = {
      ...baseBooking,
      recurrancePattern: { frequency: 'daily', period: 1 }
    };
    
    // Booking 2 is tomorrow at the same time
    const otherBooking = {
      id: 'booking2',
      roomID: 'room1',
      eventStartTime: '2023-10-28T10:00:00.000Z',
      eventEndTime: '2023-10-28T11:00:00.000Z',
      recurrancePattern: { frequency: 'never' }
    };

    const result = calculateOverlaps(recurringBooking, 'booking1', [otherBooking]);
    expect(result).toHaveLength(1);
    expect(result[0].bookingID2).toBe('booking2');
  });
});
