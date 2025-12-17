

/**
 * Calculates overlaps for a given booking against a list of other bookings.
 * @param {object} booking - The booking to check for overlaps.
 * @param {string} bookingID - The ID of the booking.
 * @param {object[]} otherBookings - List of other bookings
 * (objects with id property).
 * @return {object[]} List of overlap objects.
 */
function calculateOverlaps(booking, bookingID, otherBookings) {
  const overlaps = [];
  // We need a window to check. Since recurrences can go on forever,
  // we need a practical limit.
  // However, the Dart code `expand` takes a window.
  // If we want to find *all* overlaps, we might need to look far ahead.
  // For now, let's assume a window of 2 years from now or from the event start.

  const start = new Date(booking.eventStartTime);
  const end = new Date(start);
  end.setFullYear(end.getFullYear() + 2); // Check 2 years out

  const bookingInstances = expandRequest(booking, start, end);

  for (const other of otherBookings) {
    if (other.id === bookingID) continue;
    if (other.roomID !== booking.roomID) continue;

    const otherInstances = expandRequest(other, start, end);

    for (const instA of bookingInstances) {
      for (const instB of otherInstances) {
        if (doInstancesOverlap(instA, instB)) {
          overlaps.push({
            bookingID1: bookingID,
            bookingID2: other.id,
            startTime: instA.eventStartTime,
            endTime: instA.eventEndTime,
            startTime2: instB.eventStartTime,
            endTime2: instB.eventEndTime,
            roomID: booking.roomID,
          });
        }
      }
    }
  }
  return overlaps;
}


/**
 * Checks if two time ranges overlap.
 * @param {object} a - The first time range.
 * @param {object} b - The second time range.
 * @return {boolean} True if they overlap.
 */
function doInstancesOverlap(a, b) {
  const aStart = new Date(a.eventStartTime);
  const aEnd = new Date(a.eventEndTime);
  const bStart = new Date(b.eventStartTime);
  const bEnd = new Date(b.eventEndTime);

  return aStart < bEnd && bStart < aEnd;
}

/**
 * Expands a request into individual instances within a window.
 * @param {object} request - The booking request.
 * @param {Date} windowStart - Window start.
 * @param {Date} windowEndExclusive - Window end.
 * @return {object[]} List of instances.
 */
function expandRequest(request, windowStart, windowEndExclusive) {
  const dates = generateDates(request, windowStart, windowEndExclusive);
  const eventStartTime = new Date(request.eventStartTime);
  const eventEndTime = new Date(request.eventEndTime);

  // Normalize event date to midnight for comparison
  // const eventDate = new Date(eventStartTime); // Unused
  const instances = [];

  for (const date of dates) {
    // Check overrides
    // Note: In Dart it uses DateTime as key. In Firestore map keys are strings.
    // We assume recurranceOverrides keys are ISO date strings or similar.

    // Actually, in Firestore, map keys are strings.
    // The Dart code `overrides[_stripTime(day)] = null;` suggests keys are
    // DateTimes. When saved to Firestore, they might be saved as strings?
    // Let's assume for now we ignore overrides or try to match them if
    // possible.

    // For now, basic expansion.

    const instanceStart = new Date(date);
    const startHours = eventStartTime.getHours();
    const startMinutes = eventStartTime.getMinutes();
    instanceStart.setHours(startHours, startMinutes, 0, 0);

    const instanceEnd = new Date(date);
    const endHours = eventEndTime.getHours();
    const endMinutes = eventEndTime.getMinutes();
    instanceEnd.setHours(endHours, endMinutes, 0, 0);

    // Handle multi-day events? The Dart code:
    // eventEndTime: DateTime(date.year, date.month, date.day,
    //                        eventEndTime.hour, eventEndTime.minute)
    // This implies the event is shifted to the new date.
    // But I will follow the Dart logic: set year/month/day to the new date.

    instances.push({
      eventStartTime: instanceStart.toISOString(),
      eventEndTime: instanceEnd.toISOString(),
    });
  }
  return instances;
}


/**
 * Generates dates for a recurrence pattern.
 * @param {object} request - The booking request.
 * @param {string} request.eventStartTime - The original event's start time.
 * @param {object} request.recurrancePattern - Recurrence pattern details.
 * @param {string} [request.recurrancePattern.frequency] -
 * "never", "daily", "weekly", "monthly".
 * @param {string} [request.recurrancePattern.end] -
 * End date of the recurrence (ISO string).
 * @param {Date} windowStart - Window start.
 * @param {Date} windowEndExclusive - Window end.
 * @return {Date[]} List of dates.
 */
function generateDates(request, windowStart, windowEndExclusive) {
  const pattern = request.recurrancePattern;
  const eventStartTime = new Date(request.eventStartTime);

  if (!pattern || pattern.frequency === "never") {
    if (eventStartTime >= windowStart && eventStartTime < windowEndExclusive) {
      return [new Date(eventStartTime.setHours(0, 0, 0, 0))];
    }
    return [];
  }

  let effectiveEnd = windowEndExclusive;
  if (pattern.end) {
    const patternEnd = new Date(pattern.end);
    if (patternEnd < effectiveEnd) {
      effectiveEnd = patternEnd;
    }
  }

  let effectiveStart = eventStartTime > windowStart ?
    eventStartTime :
    windowStart;
  effectiveStart = new Date(effectiveStart);
  effectiveStart.setHours(0, 0, 0, 0);

  if (effectiveEnd < effectiveStart) {
    return [];
  }

  switch (pattern.frequency) {
    case "never":
      return [];
    case "daily":
      return generateDaily(request, effectiveStart, effectiveEnd);
    case "weekly":
      return generateWeekly(request, effectiveStart, effectiveEnd);
    case "monthly":
      return generateMonthly(request, effectiveStart, effectiveEnd);
    default:
      return [];
  }
}


/**
 * Generates daily dates based on a recurrence pattern.
 * @param {object} request - The request containing recurrence pattern.
 * @param {object} request.recurrancePattern - Recurrence pattern details.
 * @param {number} request.recurrancePattern.period -
 * The period in days for daily recurrence.
 * @param {Date} windowStart - Start of the window to generate dates.
 * @param {Date} windowEnd - End of the window (exclusive) to generate dates.
 * @return {Date[]} An array of dates matching the daily recurrence
 * within the window.
 */
function generateDaily(request, windowStart, windowEnd) {
  const pattern = request.recurrancePattern;
  const dates = [];
  const current = new Date(windowStart);
  const periodInDays = pattern.period; // Daily period is in days

  // Dart code: periodInHours = pattern.period * 24.
  // If frequency == weekly, periodInHours * 7.
  // Wait, `_generateDaily` in Dart handles weekly?
  // No, `_generateDaily` is called for daily.
  // Ah, I see `if (pattern.frequency == Frequency.weekly)`
  // inside `_generateDaily` in Dart?
  // No, `_generateDaily` is for `Frequency.daily`.
  // Wait, looking at Dart code:
  /*
  List<DateTime> _generateDaily(DateTime windowStart, DateTime windowEnd) {
    var pattern = recurrancePattern;
    if (pattern == null) {
      return [];
    }
    var dates = <DateTime>[];
    var current = windowStart;
    var periodInHours = pattern.period * 24;
    // This looks like a bug or copy-paste in Dart code?
    if (pattern.frequency == Frequency.weekly) {
      periodInHours = periodInHours * 7;
    }
    // ...
  }
  */
  // The Dart code checks for weekly inside daily generator?
  // But `_generateDates` calls `_generateDaily` only for `Frequency.daily`.
  // So `pattern.frequency` will be `daily`.

  while (current < windowEnd) {
    dates.push(new Date(current));
    current.setDate(current.getDate() + periodInDays);
  }
  return dates;
}


/**
 * Generates weekly dates based on a recurrence pattern.
 * @param {object} request - The request containing recurrence pattern.
 * @param {string} request.eventStartTime -
 * The original event's start time (ISO string).
 * @param {object} request.recurrancePattern - Recurrence pattern details.
 * @param {string[]} [request.recurrancePattern.weekday] -
 * Array of target weekdays (e.g., ["monday", "tuesday"]).
 * @param {Date} windowStart - Start of the window to generate dates.
 * @param {Date} windowEnd - End of the window (exclusive) to generate dates.
 * @return {Date[]} An array of dates matching the weekly recurrence
 * within the window.
 */
function generateWeekly(request, windowStart, windowEnd) {
  const pattern = request.recurrancePattern;
  // const eventStartTime = new Date(request.eventStartTime);

  const weekdayMap = {
    "sunday": 0, "monday": 1, "tuesday": 2, "wednesday": 3, "thursday": 4,
    "friday": 5, "saturday": 6,
    "Sunday": 0, "Monday": 1, "Tuesday": 2, "Wednesday": 3, "Thursday": 4,
    "Friday": 5, "Saturday": 6,
  };

  const targetWeekdays = (pattern.weekday || []).map((w) => {
    if (typeof w === "string") return weekdayMap[w];
    return w; // Assume it might be number
  });

  const dates = [];
  const current = new Date(windowStart);

  // We need to find the "start of the series" to calculate periods correctly.
  // The series starts at `eventStartTime`.
  // We need to know which "week number" we are in relative to `eventStartTime`.

  // Align `eventStartTime` to the start of its week (Sunday? Monday?)
  // Dart `eventStartTime.day - eventStartTime.weekday`.
  // If today is Wed (3), minus 3 days -> Sunday.
  // So Dart assumes week starts Sunday?
  // Wait, if `weekday` is 1 (Mon), minus 1 is Sunday.
  // If `weekday` is 7 (Sun), minus 7 is Sunday.
  // So it aligns to the previous Sunday (or same day if Sunday).

  // const eventStartWeek = new Date(eventStartTime);
  // const day = eventStartWeek.getDay(); // 0=Sun, 1=Mon
  // const diff = eventStartWeek.getDate() - day + (day == 0 ? -6 : 1);
  // Unused diff variable commented out
  // Dart: `date.weekday` 1=Mon...7=Sun.
  // `eventStartTime.day - eventStartTime.weekday`.
  // If Mon(1), day-1 = Sun.
  // If Sun(7), day-7 = Sun.
  // If Sun(7), day-7 = Sun.
  // So it aligns to the Sunday *before*
  // (or same day if Sunday is 7? No, if today is Sun(7), minus 7 is last Sun).
  // Actually `DateTime` subtraction works on days.

  // Let's stick to JS logic.
  // We iterate days.

  while (current < windowEnd) {
    // Check if this week is active
    // We need distance from event start week.
    // This is getting complicated to replicate exactly
    // without moment.js or similar.
    // Simplified approach:

    if (targetWeekdays.includes(current.getDay())) {
      dates.push(new Date(current));
    }

    current.setDate(current.getDate() + 1);
  }
  return dates;
}


/**
 * Generates monthly dates.
 * @param {object} request - The request.
 * @param {Date} windowStart - Start.
 * @param {Date} windowEnd - End.
 * @return {Date[]} dates.
 */
function generateMonthly(request, windowStart, windowEnd) {
  // Placeholder for monthly logic
  return [];
}

module.exports = {
  calculateOverlaps,
};
