import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/ui/widgets/request_logs_widget.dart';

class LogsWidget extends StatelessWidget {
  final Organization org;
  final String requestID;
  final bool readOnly;

  const LogsWidget({
    super.key,
    required this.org,
    required this.requestID,
    required this.readOnly,
  });

  static final dateFormat = DateFormat('MM/dd/yyyy');
  static final timeFormat = DateFormat('HH:mm');

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text("Request Log"),
      enabled: !readOnly,
      children: [
        RequestLogsWidget(
          org: org,
          allowPagination: false,
          requestID: requestID,
          titleBuilder: (entry) => Text(
            "${entry.action.name} on ${dateFormat.format(entry.timestamp)}",
          ),
          subtitleBuilder: (entry) => Text(
            "By ${entry.adminEmail} at ${timeFormat.format(entry.timestamp)}",
          ),
          showViewButton: false,
        ),
      ],
    );
  }
}
