class BookingDateHelper {
  static DateTime getFirstDate(DateTime focusDate) {
    return DateTime(focusDate.year, focusDate.month);
  }

  static DateTime getLastDate(DateTime firstDate) {
    return firstDate.add(const Duration(days: 365));
  }
}
