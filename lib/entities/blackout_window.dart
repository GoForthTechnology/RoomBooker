class BlackoutWindow {
  final DateTime start;
  final DateTime end;
  final String? recurrenceRule;
  final String reason;

  BlackoutWindow(
      {required this.start,
      required this.end,
      this.recurrenceRule,
      required this.reason});
}
