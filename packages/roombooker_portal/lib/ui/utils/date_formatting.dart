import 'package:intl/intl.dart';
import 'package:roombooker_core/data/entities/request.dart';

String getFormattedBookingRange(Request request) {
  final start = request.eventStartTime.toLocal();
  final end = request.eventEndTime.toLocal();
  final isSameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  if (isSameDay) {
    return '${DateFormat.yMMMMEEEEd().format(start)} ⋅ ${DateFormat.jm().format(start)} - ${DateFormat.jm().format(end)}';
  }
  return '${DateFormat.yMd().add_jm().format(start)} - ${DateFormat.yMd().add_jm().format(end)}';
}
