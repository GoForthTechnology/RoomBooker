import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:rxdart/rxdart.dart';

class RenderedRequest {
  final Request request;
  final PrivateRequestDetails details;
  final List<RequestLogEntry> logEntries;

  RenderedRequest({
    required this.request,
    required this.details,
    required this.logEntries,
  });
}

class BookingListViewModel extends ChangeNotifier {
  final BookingRepo _bookingRepo;
  final LogRepo _logRepo;
  final String _orgID;
  final List<RequestStatus> _statusList;
  final bool Function(Request)? _requestFilter;
  final List<Request>? _overrideRequests;
  final RoomState _roomState;

  late Stream<List<RenderedRequest>> renderedRequests;

  BookingListViewModel({
    required BookingRepo bookingRepo,
    required LogRepo logRepo,
    required String orgID,
    required List<RequestStatus> statusList,
    required RoomState roomState,
    bool Function(Request)? requestFilter,
    List<Request>? overrideRequests,
  }) : _bookingRepo = bookingRepo,
       _logRepo = logRepo,
       _orgID = orgID,
       _statusList = statusList,
       _requestFilter = requestFilter,
       _overrideRequests = overrideRequests,
       _roomState = roomState {
    _initializeStream();
  }

  void _initializeStream() {
    Stream<List<Request>> requestStream;
    if (_overrideRequests != null) {
      requestStream = Stream.value(_overrideRequests);
    } else {
      requestStream = _bookingRepo
          .listRequests(
            orgID: _orgID,
            startTime: DateTime.now(),
            endTime: DateTime.now().add(const Duration(days: 365)),
            includeRoomIDs: _roomState
                .enabledValues()
                .map((r) => r.id!)
                .toSet(),
            includeStatuses: Set.from(_statusList),
          )
          .map(
            (requests) =>
                requests.where(_requestFilter ?? (r) => true).toList(),
          );
    }

    renderedRequests = requestStream.switchMap((requests) {
      if (requests.isEmpty) {
        return Stream.value([]);
      }
      return _renderedRequests(_bookingRepo, _logRepo, _orgID, requests);
    });
  }

  Stream<List<RenderedRequest>> _renderedRequests(
    BookingRepo bookingRepo,
    LogRepo logRepo,
    String orgID,
    List<Request> requests,
  ) {
    var detailStream = Rx.combineLatest(
      requests.map(
        (request) => bookingRepo.getRequestDetails(orgID, request.id!),
      ),
      (l) => l,
    );
    var logEntryStream = Rx.combineLatest(
      requests.map(
        (request) => logRepo.getLogEntries(orgID, requestIDs: {request.id!}),
      ),
      (l) => l,
    ).map((lofl) => lofl.expand((l) => l).toList());
    return Rx.combineLatest2(detailStream, logEntryStream, (
      detailsList,
      logEntries,
    ) {
      Map<String, List<RequestLogEntry>> logEntryIndex = {};
      for (var logEntry in logEntries) {
        logEntryIndex.putIfAbsent(logEntry.requestID, () => []);
        logEntryIndex[logEntry.requestID]!.add(logEntry);
      }
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
            logEntries: logEntryIndex[details.id!] ?? [],
          );
        },
      );
      renderedRequests.sort(
        (a, b) => a.request.eventStartTime.compareTo(b.request.eventStartTime),
      );
      return renderedRequests;
    });
  }
}
