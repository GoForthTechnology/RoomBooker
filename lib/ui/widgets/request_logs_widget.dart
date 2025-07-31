import 'dart:developer';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/router.dart';

class RequestLogsWidget extends StatefulWidget {
  final Organization org;
  final String? requestID;
  final bool allowPagination;
  final bool showViewButton;
  final Widget Function(RequestLogEntry)? titleBuilder;
  final Widget Function(RequestLogEntry)? subtitleBuilder;

  const RequestLogsWidget(
      {super.key,
      required this.org,
      this.requestID,
      required this.allowPagination,
      this.titleBuilder,
      this.subtitleBuilder,
      this.showViewButton = true});

  @override
  State<RequestLogsWidget> createState() => _RequestLogsWidgetState();
}

class _RequestLogsWidgetState extends State<RequestLogsWidget> {
  static const recordsPerPageOptions = [5, 10, 20];
  int _recordsPerPage = 5;
  final List<RequestLogEntry> _lastEntries = [];
  List<DecoratedLogEntry>? _cachedLogs;

  RequestLogEntry? get _lastEntry =>
      _lastEntries.isNotEmpty ? _lastEntries.last : null;

  @override
  Widget build(BuildContext context) {
    var logRepo = Provider.of<LogRepo>(context, listen: false);
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);

    Set<String>? requestIDs;
    if (widget.requestID != null) {
      requestIDs = {widget.requestID!};
    }

    return StreamBuilder<List<DecoratedLogEntry>>(
      stream: bookingRepo.decorateLogs(
          widget.org.id!,
          logRepo.getLogEntries(
            widget.org.id!,
            limit: _recordsPerPage,
            startAfter: _lastEntry,
            requestIDs: requestIDs,
          )),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          log("Error loading request logs: ${snapshot.error.toString()}");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${snapshot.error}')),
            );
          });
          return const Text('Error loading request logs');
        }

        var isLoading = false;
        // Use cached data while loading, or update cache with new data
        List<DecoratedLogEntry> logs;
        if (snapshot.hasData) {
          logs = snapshot.data!;
          _cachedLogs = logs;
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          // Show cached data while loading
          logs = _cachedLogs ?? [];
          isLoading = true;
        } else {
          logs = [];
        }

        if (logs.isEmpty) {
          return const Text('No request logs found');
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(isLoading),
            children: [
              _logView(isLoading, logs),
              if (widget.allowPagination) _paginationControls(isLoading, logs),
            ],
          ),
        );
      },
    );
  }

  Widget _logView(bool isLoading, List<DecoratedLogEntry> logs) {
    return Stack(
      children: [
        Opacity(
          opacity: isLoading ? 0.6 : 1.0,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index];
              Widget? trailing;
              if (widget.showViewButton && log.entry.action != Action.delete) {
                trailing = TextButton(
                    onPressed: () {
                      AutoRouter.of(context).push(ViewBookingsRoute(
                          orgID: widget.org.id!,
                          requestID: log.entry.requestID));
                    },
                    child: Text("VIEW"));
              }
              Widget title = widget.titleBuilder != null
                  ? widget.titleBuilder!(log.entry)
                  : Text("${log.details.email} - ${log.entry.action.name}");
              Widget subtitle = widget.subtitleBuilder != null
                  ? widget.subtitleBuilder!(log.entry)
                  : Text(
                      "${log.details.eventName} @ ${log.entry.timestamp.toIso8601String()}");
              return Tooltip(
                  message: log.entry.requestID,
                  child: ListTile(
                    title: title,
                    subtitle: subtitle,
                    trailing: trailing,
                  ));
            },
          ),
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              alignment: Alignment.center,
              child: const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _paginationControls(bool isLoading, List<DecoratedLogEntry> logs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Spacer(),
        IconButton(
          onPressed: (_lastEntry == null || isLoading)
              ? null
              : () => setState(() {
                    _lastEntries.removeLast();
                  }),
          icon: const Icon(Icons.arrow_left),
        ),
        DropdownButton<int>(
          value: _recordsPerPage,
          items: recordsPerPageOptions
              .map((value) => DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value per page'),
                  ))
              .toList(),
          onChanged: isLoading
              ? null
              : (value) {
                  if (value != null) {
                    setState(() {
                      _recordsPerPage = value;
                      // Clear cache when changing page size
                      _cachedLogs = null;
                      _lastEntries.clear();
                    });
                  }
                },
        ),
        IconButton(
          onPressed: (isLoading || logs.isEmpty)
              ? null
              : () => setState(() {
                    _lastEntries.add(logs.last.entry);
                  }),
          icon: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }
}
