import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/core/heading.dart';

class RequestLogsWidget extends StatelessWidget {
  final Organization org;

  const RequestLogsWidget({super.key, required this.org});

  @override
  Widget build(BuildContext context) {
    var logRepo = Provider.of<LogRepo>(context, listen: false);
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    var entries = StreamBuilder(
      stream: bookingRepo.decorateLogs(org.id!, logRepo.getLogEntries(org.id!)),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading request logs');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        var logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return const Text('No request logs found');
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: logs.length,
          itemBuilder: (context, index) {
            var log = logs[index];
            return Tooltip(
                message: log.entry.requestID,
                child: ListTile(
                  title:
                      Text("${log.details.email} - ${log.entry.action.name}"),
                  subtitle: Text(
                      "${log.details.eventName} @ ${log.entry.timestamp.toIso8601String()}"),
                ));
          },
        );
      },
    );
    return Column(
      children: [
        const Heading("Request Logs"),
        const Text(
            "This shows the history of admin requests and actions taken on them"),
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: entries,
        ),
      ],
    );
  }
}
