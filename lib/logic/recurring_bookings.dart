import 'package:room_booker/entities/request.dart';
import 'package:intl/intl.dart';

Map<Frequency, String> getRecurringBookingOptions(DateTime currentDate) {
  var options = {
    Frequency.never: "Never",
    Frequency.daily: "Daily",
  };

  var weekdayName = getWeekdayName(currentDate);
  options[Frequency.weekly] = "Weekly on ${weekdayName}s";

  var monthlyOcurrence = getMonthlyOccurrence(currentDate);
  options[Frequency.monthly] = "Monthly on the $monthlyOcurrence $weekdayName";

  var formatter = DateFormat('MMMM');
  var monthName = formatter.format(currentDate);
  options[Frequency.annually] =
      "Annually on $monthName ${currentDate.day}${numberSuffix(currentDate.day)}";

  options[Frequency.custom] = "Custom";
  return options;
}

String getWeekdayName(DateTime date) {
  var weekdayName = getWeekday(date).toString().split('.').last;
  weekdayName = weekdayName[0].toUpperCase() + weekdayName.substring(1);
  return getWeekday(date).toString().split('.').last;
}

String getMonthlyOccurrence(DateTime date) {
  int occurrence = 0;
  for (int i = 1; i <= date.day; i++) {
    if (DateTime(date.year, date.month, i).weekday == date.weekday) {
      occurrence++;
    }
  }
  return "$occurrence${numberSuffix(occurrence)}";
}

String numberSuffix(int i) {
  switch (i) {
    case 1:
    case 21:
    case 31:
      return "st";
    case 2:
    case 22:
      return "nd";
    case 3:
    case 23:
      return "rd";
    default:
      return "th";
  }
}
