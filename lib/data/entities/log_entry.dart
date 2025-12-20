import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:room_booker/data/entities/request.dart';

part 'log_entry.g.dart';

@JsonSerializable(explicitToJson: true)
class RequestLogEntry {
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  final String requestID;
  final DateTime timestamp;
  final String? adminEmail;
  final Action action;
  final Request? before;
  final Request? after;

  RequestLogEntry({
    required this.requestID,
    required this.timestamp,
    required this.action,
    this.adminEmail,
    this.before,
    this.after,
    this.id,
  });

  RequestLogEntry copyWith({String? id}) {
    return RequestLogEntry(
      requestID: requestID,
      timestamp: timestamp,
      action: action,
      adminEmail: adminEmail,
      before: before,
      after: after,
      id: id ?? this.id,
    );
  }

  factory RequestLogEntry.fromJson(Map<String, dynamic> json) =>
      _$RequestLogEntryFromJson(json);
  Map<String, dynamic> toJson() => _$RequestLogEntryToJson(this);

  String render() {
    if (before == null && after == null) {
      return 'No changes detected.';
    }

    if (before == null) {
      return 'Created: ${_requestToString(after!)}';
    }

    if (after == null) {
      return 'Deleted: ${_requestToString(before!)}';
    }

    return _diff(before!, after!);
  }

  String _diff(Request before, Request after) {
    final changes = <String>[];

    if (before.publicName != after.publicName) {
      changes.add(
        'Public Name changed from "${before.publicName}" to "${after.publicName}"',
      );
    }
    if (before.eventStartTime != after.eventStartTime) {
      changes.add(
        'Start Time changed from "${_formatDateTime(before.eventStartTime)}" to "${_formatDateTime(after.eventStartTime)}"',
      );
    }
    if (before.eventEndTime != after.eventEndTime) {
      changes.add(
        'End Time changed from "${_formatDateTime(before.eventEndTime)}" to "${_formatDateTime(after.eventEndTime)}"',
      );
    }
    if (before.roomName != after.roomName) {
      changes.add(
        'Room changed from "${before.roomName}" to "${after.roomName}"',
      );
    }
    if (before.status != after.status) {
      changes.add(
        'Status changed from "${_statusToString(before.status)}" to "${_statusToString(after.status)}"',
      );
    }
    if (before.recurrancePattern != after.recurrancePattern) {
      changes.add(
        'Recurrence changed from "${before.recurrancePattern}" to "${after.recurrancePattern}"',
      );
    }
    if (before.ignoreOverlaps != after.ignoreOverlaps) {
      changes.add(
        'Ignore Overlaps changed from "${before.ignoreOverlaps}" to "${after.ignoreOverlaps}"',
      );
    }

    if (changes.isEmpty) {
      return 'No changes detected.';
    }

    return changes.join('\n');
  }

  String _requestToString(Request request) {
    return 'Event "${request.publicName}" in room "${request.roomName}" from ${_formatDateTime(request.eventStartTime)} to ${_formatDateTime(request.eventEndTime)}. Status: ${_statusToString(request.status)}.';
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat.yMMMd().add_jm().format(dateTime);
  }

  String _statusToString(RequestStatus? status) {
    switch (status) {
      case RequestStatus.confirmed:
        return 'Confirmed';
      case RequestStatus.denied:
        return 'Denied';
      case RequestStatus.pending:
        return 'Pending';
      default:
        return 'Unknown';
    }
  }
}

enum Action {
  create,
  request,
  approve,
  reject,
  revisit,
  endRecurring,
  ignoreOverlaps,
  update,
  delete,
}

class DecoratedLogEntry {
  final RequestLogEntry entry;
  final Request request;
  final PrivateRequestDetails details;

  DecoratedLogEntry(this.details, {required this.entry, required this.request});
}
