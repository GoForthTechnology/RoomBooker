import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:rxdart/rxdart.dart';

class BookingSearchContext extends ChangeNotifier {
  String searchQuery = "";

  BookingSearchContext();

  void updateQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }
}

class RenderedRequest {
  final Request request;
  final PrivateRequestDetails details;

  RenderedRequest({required this.request, required this.details});
}

class BookingList extends StatelessWidget {
  final String orgID;
  final String emptyText;
  final List<RequestStatus> statusList;
  final bool Function(Request)? requestFilter;
  final List<RequestAction> actions;
  final List<Request>? overrideRequests;
  final Color? Function(Request)? backgroundColorFn;
  final List<RequestAction> Function(Request)? actionBuilder;

  const BookingList(
      {super.key,
      required this.orgID,
      required this.actions,
      required this.statusList,
      required this.emptyText,
      this.requestFilter,
      this.backgroundColorFn,
      this.actionBuilder,
      this.overrideRequests});

  Stream<List<RenderedRequest>> _renderedRequests(
      BookingRepo bookingRepo, String orgID, List<Request> requests) {
    return Rx.combineLatest(
        requests.map(
            (request) => bookingRepo.getRequestDetails(orgID, request.id!)),
        (detailsList) {
      var renderedRequests = List<RenderedRequest>.generate(
        detailsList.length,
        (index) {
          var details = detailsList[index];
          if (details == null) {
            log("No details found for request ${requests[index].id}");
            details = PrivateRequestDetails(
              name: "Unknown",
              email: "Unknown",
              phone: "Unknown",
              eventName: "Unknown",
            );
          }
          return RenderedRequest(
            request: requests[index],
            details: details,
          );
        },
      );
      renderedRequests.sort((a, b) => a.request.eventStartTime.compareTo(
            b.request.eventStartTime,
          ));
      return renderedRequests;
    });
  }

  @override
  Widget build(BuildContext context) {
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    return Consumer<RoomState>(builder: (context, roomState, child) {
      Stream<List<Request>> requestStream;
      if (overrideRequests != null) {
        requestStream = Stream.value(overrideRequests!);
      } else {
        requestStream = bookingRepo
            .listRequests(
                orgID: orgID,
                startTime: DateTime.now(),
                endTime: DateTime.now().add(const Duration(days: 365)),
                includeRoomIDs:
                    roomState.enabledValues().map((r) => r.id!).toSet(),
                includeStatuses: Set.from(statusList))
            .map((requests) =>
                requests.where(requestFilter ?? (r) => true).toList());
      }
      return StreamBuilder(
        stream: requestStream,
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
          return Consumer<BookingSearchContext>(
              builder: (context, searchContext, child) => StreamBuilder(
                    stream: _renderedRequests(
                        bookingRepo, orgID, snapshot.data ?? []),
                    builder: (context, detailsSnapshot) {
                      if (detailsSnapshot.hasError) {
                        log(detailsSnapshot.error.toString(),
                            error: detailsSnapshot.error);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Error: ${detailsSnapshot.error}')),
                          );
                        });
                        return const Placeholder();
                      }
                      var renderedRequests = detailsSnapshot.data ?? [];
                      if (renderedRequests.isEmpty) {
                        return Text(emptyText);
                      }
                      renderedRequests = renderedRequests
                          .where((r) =>
                              r.details.eventName.toLowerCase().contains(
                                  searchContext.searchQuery.toLowerCase()) ||
                              r.request.roomName.toLowerCase().contains(
                                  searchContext.searchQuery.toLowerCase()))
                          .toList();
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
                            backgroundColorFn: backgroundColorFn,
                          );
                        },
                      );
                    },
                  ));
        },
      );
    });
  }
}

class RequestAction {
  final String text;
  final Function(Request)? onClick;
  final String? disableText;

  RequestAction({required this.text, required this.onClick, this.disableText});
}

class BookingTile extends StatelessWidget {
  final String orgID;
  final List<RequestAction> actions;
  final Request request;
  final PrivateRequestDetails details;
  final Color? Function(Request)? backgroundColorFn;

  const BookingTile({
    super.key,
    required this.request,
    required this.actions,
    required this.details,
    required this.orgID,
    this.backgroundColorFn,
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
                )),
          ),
          _detailTable(request, details),
        ],
      ),
    );
  }

  Widget? _trailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions.map(
        (a) {
          Widget button = ElevatedButton(
              onPressed: a.onClick == null ? null : () => a.onClick!(request),
              child: Text(a.text));
          if ((a.disableText ?? "") != "") {
            button = Tooltip(
              message: a.disableText!,
              child: button,
            );
          }
          return button;
        },
      ).toList(),
    );
  }

  Widget? _leading(Color color) {
    if (request.status == RequestStatus.pending) {
      return null;
    }
    return Icon(
      Icons.event,
      color: color,
    );
  }

  Widget _subtitle(BuildContext context) {
    var startTimeStr =
        TimeOfDay.fromDateTime(request.eventStartTime).format(context);
    var endTimeStr =
        TimeOfDay.fromDateTime(request.eventEndTime).format(context);
    var subtitle =
        '${request.roomName} on ${_formatDate(request.eventStartTime)} from $startTimeStr to $endTimeStr';
    if (request.isRepeating()) {
      subtitle += ' (recurring ${request.recurrancePattern})';
    }
    return Text(subtitle);
  }
}

Widget _detailTable(Request booking, PrivateRequestDetails details) {
  return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(200),
        children: [
          _bookingField('Phone', details.phone),
          _bookingField('Email', details.email),
          _bookingField('Message', details.message),
        ],
      ));
}

TableRow _bookingField(String label, String value) {
  return TableRow(children: [
    TableCell(
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
    TableCell(
      child: Text(value),
    ),
  ]);
}

String _formatDate(DateTime dateTime) {
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
