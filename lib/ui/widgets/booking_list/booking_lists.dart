import 'dart:developer';

import 'package:flutter/material.dart' hide Action;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_list_view_model.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

class BookingList extends StatelessWidget {
  final String orgID;
  final String emptyText;
  final List<RequestStatus> statusList;
  final bool Function(Request)? requestFilter;
  final List<RequestAction> actions;
  final List<Request>? overrideRequests;
  final Color? Function(Request)? backgroundColorFn;
  final List<RequestAction> Function(Request)? actionBuilder;

  const BookingList({
    super.key,
    required this.orgID,
    required this.actions,
    required this.statusList,
    required this.emptyText,
    this.requestFilter,
    this.backgroundColorFn,
    this.actionBuilder,
    this.overrideRequests,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomState>(
      builder: (context, roomState, child) {
        return ChangeNotifierProvider(
          create: (context) => BookingListViewModel(
            bookingRepo: Provider.of<BookingRepo>(context, listen: false),
            logRepo: Provider.of<LogRepo>(context, listen: false),
            orgID: orgID,
            statusList: statusList,
            roomState: roomState,
            filterViewModel: Provider.of<BookingFilterViewModel>(context, listen: false),
            requestFilter: requestFilter,
            overrideRequests: overrideRequests,
          ),
          child: Consumer<BookingListViewModel>(
            builder: (context, viewModel, child) {
              return StreamBuilder<List<RenderedRequest>>(
                stream: viewModel.renderedRequests,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    log(snapshot.error.toString(), error: snapshot.error);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${snapshot.error}')),
                      );
                    });
                    return const Placeholder();
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var renderedRequests = snapshot.data ?? [];
                  if (renderedRequests.isEmpty) {
                    return Text(emptyText);
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: renderedRequests.length,
                    itemBuilder: (context, index) {
                      var renderedRequest = renderedRequests[index];
                      List<RequestAction> actions = this.actions;
                      if (actionBuilder != null) {
                        actions = actionBuilder!(renderedRequest.request);
                      }
                      return BookingTile(
                        orgID: orgID,
                        request: renderedRequest.request,
                        details: renderedRequest.details,
                        actions: actions,
                        logEntries: renderedRequest.logEntries,
                        backgroundColorFn: backgroundColorFn,
                      );
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class RequestAction {
  final IconData icon;
  final String text;
  final Function(Request)? onClick;
  final String? disableText;

  RequestAction({
    required this.icon,
    required this.text,
    required this.onClick,
    this.disableText,
  });
}

class BookingTile extends StatelessWidget {
  final String orgID;
  final List<RequestAction> actions;
  final Request request;
  final PrivateRequestDetails details;
  final List<RequestLogEntry> logEntries;
  final Color? Function(Request)? backgroundColorFn;

  const BookingTile({
    super.key,
    required this.request,
    required this.actions,
    required this.details,
    required this.orgID,
    this.backgroundColorFn,
    required this.logEntries,
  });

  @override
  Widget build(BuildContext context) {
    var roomState = Provider.of<RoomState>(context, listen: false);
    Color? color;
    if (backgroundColorFn != null) {
      color = backgroundColorFn!(request);
    }
    return Card(
      elevation: 1,
      color: color,
      child: ExpansionTile(
        title: Text("${details.eventName} for ${details.name}"),
        subtitle: _subtitle(context),
        leading: _leading(roomState.color(request.roomID)),
        trailing: _trailing(),
        expandedAlignment: Alignment.topLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: request.id!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request ID copied to clipboard'),
                  ),
                );
              },
              child: Text(
                "Request ID: ${request.id}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Wrap(
            spacing: 16.0, // gap between adjacent chips
            runSpacing: 8.0, // gap between lines
            children: [
              _DetailTable(booking: request, details: details),
              _LogTable(logEntries: logEntries),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _trailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map((a) {
        Widget button = IconButton(
          icon: Icon(a.icon),
          onPressed: a.onClick == null ? null : () => a.onClick!(request),
        );
        button = Tooltip(message: a.text, child: button);
        if ((a.disableText ?? "") != "") {
          button = Tooltip(message: a.disableText!, child: button);
        }
        return button;
      }).toList(),
    );
  }

  Widget? _leading(Color color) {
    if (request.status == RequestStatus.pending) {
      return null;
    }
    return Icon(Icons.event, color: color);
  }

  Widget _subtitle(BuildContext context) {
    var startTimeStr = TimeOfDay.fromDateTime(
      request.eventStartTime,
    ).format(context);
    var endTimeStr = TimeOfDay.fromDateTime(
      request.eventEndTime,
    ).format(context);
    var subtitle =
        '${request.roomName} on ${_formatDate(request.eventStartTime)} from $startTimeStr to $endTimeStr';
    if (request.isRepeating()) {
      subtitle += ' (recurring ${request.recurrancePattern})';
    }
    return Text(subtitle);
  }
}

class _DetailTable extends StatelessWidget {
  final Request booking;
  final PrivateRequestDetails details;

  const _DetailTable({required this.booking, required this.details});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(200),
        children: [
          _bookingField('Phone', details.phone),
          _bookingField('Email', details.email),
          _bookingField('Message', details.message),
        ],
      ),
    );
  }
}

class _LogTable extends StatelessWidget {
  final List<RequestLogEntry> logEntries;

  const _LogTable({required this.logEntries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(200),
        children: _logRows(logEntries),
      ),
    );
  }
}

List<TableRow> _logRows(List<RequestLogEntry> logEntries) {
  logEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return logEntries.map(_bookingRow).toList();
}

TableRow _bookingRow(RequestLogEntry entry) {
  return TableRow(
    children: [
      TableCell(
        child: Text(
          "${entry.action.name.toUpperCase()} on ${_formatDate(entry.timestamp)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      TableCell(child: Text(entry.render())),
    ],
  );
}

TableRow _bookingField(String label, String value) {
  return TableRow(
    children: [
      TableCell(
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      TableCell(child: Text(value)),
    ],
  );
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
