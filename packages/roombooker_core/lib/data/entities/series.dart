import 'package:roombooker_core/data/entities/request.dart';

class Series {
  final Request request;
  final RecurrancePattern pattern;

  Series({required this.request, required this.pattern});
}
