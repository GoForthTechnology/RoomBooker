import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/core/heading.dart';

class RequestLogsWidget extends StatefulWidget {
  final Organization org;

  const RequestLogsWidget({super.key, required this.org});

  @override
  State<RequestLogsWidget> createState() => _RequestLogsWidgetState();
}

class _RequestLogsWidgetState extends State<RequestLogsWidget> {
  static const recordsPerPageOptions = [5, 10, 20];
  int _recordsPerPage = 5;
  final List<RequestLogEntry> _lastEntries = [];

  RequestLogEntry? get _lastEntry =>
      _lastEntries.isNotEmpty ? _lastEntries.last : null;

  @override
  Widget build(BuildContext context) {
    var logRepo = Provider.of<LogRepo>(context, listen: false);
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    var entries = StreamBuilder(
      stream: bookingRepo.decorateLogs(
          widget.org.id!,
          logRepo.getLogEntries(widget.org.id!,
              limit: _recordsPerPage, startAfter: _lastEntry)),
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
        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              // Prevent scrolling to avoid conflicts with the parent scroll view
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                var log = logs[index];
                return Tooltip(
                    message: log.entry.requestID,
                    child: ListTile(
                      title: Text(
                          "${log.details.email} - ${log.entry.action.name}"),
                      subtitle: Text(
                          "${log.details.eventName} @ ${log.entry.timestamp.toIso8601String()}"),
                    ));
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Spacer(),
                IconButton(
                  onPressed: _lastEntry == null
                      ? null
                      : () => setState(() {
                            _lastEntries.removeLast();
                          }),
                  icon: Icon(Icons.arrow_left),
                ),
                DropdownButton<int>(
                  value: _recordsPerPage,
                  items: recordsPerPageOptions
                      .map((value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value per page'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _recordsPerPage = value;
                      });
                    }
                  },
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _lastEntries.add(logs.last.entry);
                  }),
                  icon: Icon(Icons.arrow_right),
                ),
              ],
            )
          ],
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
