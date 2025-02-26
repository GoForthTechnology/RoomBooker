import 'package:room_booker/entities/request.dart';

Map<Frequency, RecurrancePattern?> getRecurringBookingOptions(
    DateTime currentDate) {
  var options = <Frequency, RecurrancePattern?>{
    Frequency.never: RecurrancePattern.never(),
    Frequency.daily: RecurrancePattern.daily(),
  };

  options[Frequency.weekly] =
      RecurrancePattern.weekly(on: getWeekday(currentDate));

  var monthlyOcurrence = getMonthlyOccurrence(currentDate);
  options[Frequency.monthly] =
      RecurrancePattern.monthlyOnNth(monthlyOcurrence, getWeekday(currentDate));

  options[Frequency.annually] = RecurrancePattern.annually();

  options[Frequency.custom] = null;
  return options;
}

String getWeekdayName(DateTime date) {
  return getWeekday(date).name;
}

int getMonthlyOccurrence(DateTime date) {
  int occurrence = 0;
  for (int i = 1; i <= date.day; i++) {
    if (DateTime(date.year, date.month, i).weekday == date.weekday) {
      occurrence++;
    }
  }
  return occurrence;
}
