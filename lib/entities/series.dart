import 'package:room_booker/entities/request.dart';

class Series {
  final Request request;
  final RecurrancePattern pattern;

  Series({required this.request, required this.pattern});
}
