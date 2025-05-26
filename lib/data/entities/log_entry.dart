import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/data/entities/request.dart';

part 'log_entry.g.dart';

@JsonSerializable(explicitToJson: true)
class RequestLogEntry {
  final String requestID;
  final DateTime timestamp;
  final String? adminEmail;
  final Action action;

  RequestLogEntry({
    required this.requestID,
    required this.timestamp,
    required this.action,
    this.adminEmail,
  });

  factory RequestLogEntry.fromJson(Map<String, dynamic> json) =>
      _$RequestLogEntryFromJson(json);
  Map<String, dynamic> toJson() => _$RequestLogEntryToJson(this);
}

enum Action {
  create,
  request,
  approve,
  reject,
  revisit,
  endRecurring,
  update,
  delete,
}

class DecoratedLogEntry {
  final RequestLogEntry entry;
  final Request request;
  final PrivateRequestDetails details;

  DecoratedLogEntry(this.details, {required this.entry, required this.request});
}
