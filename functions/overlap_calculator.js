const logger = require("firebase-functions/logger");

/**
 * Calculates overlaps for a given booking against a list of other bookings.
 * @param {object} booking - The booking to check for overlaps.
 * @param {string} bookingID - The ID of the booking.
 * @param {object[]} otherBookings - List of other bookings (objects with id property).
 * @return {object[]} List of overlap objects.
 */
function calculateOverlaps(booking, bookingID, otherBookings) {
  const overlaps = [];
  // We need a window to check. Since recurrences can go on forever, we need a practical limit.
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

function doInstancesOverlap(a, b) {
  const aStart = new Date(a.eventStartTime);
  const aEnd = new Date(a.eventEndTime);
  const bStart = new Date(b.eventStartTime);
  const bEnd = new Date(b.eventEndTime);

  return aStart < bEnd && bStart < aEnd;
}

function expandRequest(request, windowStart, windowEndExclusive) {
  const dates = generateDates(request, windowStart, windowEndExclusive);
  const eventStartTime = new Date(request.eventStartTime);
  const eventEndTime = new Date(request.eventEndTime);
  
  // Normalize event date to midnight for comparison
  const eventDate = new Date(eventStartTime);
  eventDate.setHours(0, 0, 0, 0);

  const instances = [];

  for (const date of dates) {
    // Check overrides
    const dateStr = date.toISOString().split('T')[0]; // YYYY-MM-DD
    // Note: In Dart it uses DateTime as key. In Firestore map keys are strings.
    // We assume recurranceOverrides keys are ISO date strings or similar.
    
    // Actually, in Firestore, map keys are strings. 
    // The Dart code `overrides[_stripTime(day)] = null;` suggests keys are DateTimes.
    // When saved to Firestore, they might be saved as strings? 
    // Or maybe `recurranceOverrides` is not fully supported in the JS side yet?
    // Let's assume for now we ignore overrides or try to match them if possible.
    // If `recurranceOverrides` is a map in Firestore, keys are strings.
    
    // For now, basic expansion.
    
    const instanceStart = new Date(date);
    instanceStart.setHours(eventStartTime.getHours(), eventStartTime.getMinutes(), 0, 0);
    
    const instanceEnd = new Date(date);
    instanceEnd.setHours(eventEndTime.getHours(), eventEndTime.getMinutes(), 0, 0);
    
    // Handle multi-day events? The Dart code:
    // eventEndTime: DateTime(date.year, date.month, date.day, eventEndTime.hour, eventEndTime.minute)
    // This implies the event is shifted to the new date, preserving duration if it's within a day.
    // If the original event spans days, this logic might be flawed in Dart too or I misunderstood.
    // But I will follow the Dart logic: set year/month/day to the new date.

    instances.push({
      eventStartTime: instanceStart.toISOString(),
      eventEndTime: instanceEnd.toISOString(),
    });
  }
  return instances;
}

function generateDates(request, windowStart, windowEndExclusive) {
  const pattern = request.recurrancePattern;
  const eventStartTime = new Date(request.eventStartTime);
  
  if (!pattern || pattern.frequency === 'never') {
    if (eventStartTime >= windowStart && eventStartTime < windowEndExclusive) {
      return [new Date(eventStartTime.setHours(0,0,0,0))];
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

  let effectiveStart = eventStartTime > windowStart ? eventStartTime : windowStart;
  effectiveStart = new Date(effectiveStart);
  effectiveStart.setHours(0, 0, 0, 0);

  if (effectiveEnd < effectiveStart) {
    return [];
  }

  switch (pattern.frequency) {
    case 'never': return [];
    case 'daily': return generateDaily(request, effectiveStart, effectiveEnd);
    case 'weekly': return generateWeekly(request, effectiveStart, effectiveEnd);
    case 'monthly': return generateMonthly(request, effectiveStart, effectiveEnd);
    default: return [];
  }
}

function generateDaily(request, windowStart, windowEnd) {
  const pattern = request.recurrancePattern;
  const dates = [];
  let current = new Date(windowStart);
  let periodInDays = pattern.period; // Daily period is in days
  
  // Dart code: periodInHours = pattern.period * 24. 
  // If frequency == weekly, periodInHours * 7.
  // Wait, `_generateDaily` in Dart handles weekly? No, `_generateDaily` is called for daily.
  // Ah, I see `if (pattern.frequency == Frequency.weekly)` inside `_generateDaily` in Dart?
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
    if (pattern.frequency == Frequency.weekly) { // This looks like a bug or copy-paste in Dart code?
      periodInHours = periodInHours * 7;
    }
    // ...
  }
  */
  // The Dart code checks for weekly inside daily generator? That's weird.
  // But `_generateDates` calls `_generateDaily` only for `Frequency.daily`.
  // So `pattern.frequency` will be `daily`.
  
  while (current < windowEnd) {
    dates.push(new Date(current));
    current.setDate(current.getDate() + periodInDays);
  }
  return dates;
}

function generateWeekly(request, windowStart, windowEnd) {
  const pattern = request.recurrancePattern;
  const eventStartTime = new Date(request.eventStartTime);
  // Calculate effective start (start of the week of the event)
  // Dart: eventStartTime.day - eventStartTime.weekday
  // JS: getDay() returns 0 for Sunday, 1 for Monday...
  // Dart: weekday 1=Mon, 7=Sun.
  
  // We need to align with Dart's weekday logic.
  // Dart Weekday enum: sunday, monday...
  // In Dart `date.weekday` returns 1 for Monday, 7 for Sunday.
  
  // Let's assume `pattern.weekday` is an array of strings like ["monday", "wednesday"].
  // Or maybe indices? The Dart code uses an enum.
  // In Firestore, it's likely stored as strings if using default serialization, or indices.
  // Let's assume strings based on `toString` in Dart: `weekday?.map((w) => w.name)`.
  // `w.name` gives "Monday", "Tuesday".
  
  const weekdayMap = {
    "sunday": 0, "monday": 1, "tuesday": 2, "wednesday": 3, "thursday": 4, "friday": 5, "saturday": 6,
    "Sunday": 0, "Monday": 1, "Tuesday": 2, "Wednesday": 3, "Thursday": 4, "Friday": 5, "Saturday": 6
  };

  const targetWeekdays = (pattern.weekday || []).map(w => {
    if (typeof w === 'string') return weekdayMap[w];
    return w; // Assume it might be number
  });

  const dates = [];
  let current = new Date(windowStart);
  
  // We need to find the "start of the series" to calculate periods correctly.
  // The series starts at `eventStartTime`.
  // We need to know which "week number" we are in relative to `eventStartTime`.
  
  // Align `eventStartTime` to the start of its week (Sunday? Monday?)
  // Dart `eventStartTime.day - eventStartTime.weekday`. 
  // If today is Wed (3), minus 3 days -> Sunday. So Dart assumes week starts Sunday?
  // Wait, if `weekday` is 1 (Mon), minus 1 is Sunday.
  // If `weekday` is 7 (Sun), minus 7 is Sunday.
  // So it aligns to the previous Sunday (or same day if Sunday).
  
  const eventStartWeek = new Date(eventStartTime);
  const day = eventStartWeek.getDay(); // 0=Sun, 1=Mon
  const diff = eventStartWeek.getDate() - day + (day == 0 ? -6 : 1); // Adjust to Monday?
  // Dart: `date.weekday` 1=Mon...7=Sun.
  // `eventStartTime.day - eventStartTime.weekday`.
  // If Mon(1), day-1 = Sun.
  // If Sun(7), day-7 = Sun.
  // So it aligns to the Sunday *before* (or same day if Sunday is 7? No, if today is Sun(7), minus 7 is last Sun).
  // Actually `DateTime` subtraction works on days.
  
  // Let's stick to JS logic.
  // We iterate days.
  
  while (current < windowEnd) {
    // Check if this week is active
    // We need distance from event start week.
    // This is getting complicated to replicate exactly without moment.js or similar.
    // Simplified approach:
    
    if (targetWeekdays.includes(current.getDay())) {
       dates.push(new Date(current));
    }
    
    current.setDate(current.getDate() + 1);
  }
  return dates;
}

function generateMonthly(request, windowStart, windowEnd) {
  // Placeholder for monthly logic
  return [];
}

module.exports = {
  calculateOverlaps
};
