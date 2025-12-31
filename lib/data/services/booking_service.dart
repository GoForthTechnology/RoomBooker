import 'dart:async';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:room_booker/data/entities/blackout_window.dart';
import 'package:room_booker/data/entities/organization.dart';

class BookingService {
  final BookingRepo _bookingRepo;

  BookingService({required BookingRepo bookingRepo})
    : _bookingRepo = bookingRepo;

  Stream<List<Request>> getRequestsStream({
    required String orgID,
    required bool isAdmin,
    required DateTime start,
    required DateTime end,
    Set<RequestStatus>? includeStatuses,
    Set<String>? includeRoomIDs,
  }) {
    return _bookingRepo
        .listRequests(
          orgID: orgID,
          startTime: start,
          endTime: end,
          includeStatuses:
              includeStatuses ??
              {RequestStatus.pending, RequestStatus.confirmed},
          includeRoomIDs: includeRoomIDs,
        )
        .switchMap((requests) {
          // 1. Expand recurring requests into instances within the window
          final expandedRequests = <Request>[];
          for (var request in requests) {
            final instances = request.expand(
              start,
              end,
              includeRequestDate: true,
            );
            expandedRequests.addAll(instances);
          }

          if (expandedRequests.isEmpty) {
            return Stream.value(<Request>[]);
          }

          // 2. Fetch private details if user is admin
          if (!isAdmin) {
            return Stream.value(expandedRequests);
          }

          // Fetch details for the *original* request IDs (not the expanded instance IDs which might be null or same)
          // Actually request.expand returns copies. The 'id' field is still the original request ID.
          final uniqueRequestIds = expandedRequests
              .map((r) => r.id)
              .whereType<String>()
              .toSet();

          // If no IDs (e.g. all new local requests?), just return.
          if (uniqueRequestIds.isEmpty) {
            return Stream.value(expandedRequests);
          }

          final detailStreams = uniqueRequestIds
              .map((id) => _bookingRepo.getRequestDetails(orgID, id))
              .toList();

          return Rx.combineLatestList(detailStreams).map((detailsList) {
            final span = Sentry.getSpan()?.startChild(
              'enrich_requests',
              description:
                  'Enriching ${expandedRequests.length} requests with details',
            );

            try {
              final detailsMap = <String, PrivateRequestDetails>{};
              for (var d in detailsList) {
                if (d?.id != null) {
                  detailsMap[d!.id!] = d;
                }
              }

              return expandedRequests.map((request) {
                if (request.id == null) return request;
                final details = detailsMap[request.id];
                if (details != null) {
                  String? subject = request.publicName;
                  if (subject == null || subject.isEmpty) {
                    // If public name is empty, use private event name marked as Private
                    // Or just use the private name?
                    // CalendarViewModel logic:
                    // if (subject == null && details != null) { subject = "${details.eventName} (Private)"; }
                    // But wait, ViewBookingsViewModel Print logic:
                    // if (details != null && details.eventName.isNotEmpty) { return r.copyWith(publicName: details.eventName); }

                    // Let's standardise on showing the real name if admin.
                    // If it was private, the publicName is null/empty.
                    subject = "${details.eventName} (Private)";
                  }
                  return request.copyWith(publicName: subject);
                }
                return request;
              }).toList();
            } catch (e) {
              span?.status = const SpanStatus.internalError();
              rethrow;
            } finally {
              span?.finish();
            }
          });
        });
  }

  // Domain Logic - Validation
  void validateRequest(Request request) {
    if (request.eventEndTime.isBefore(request.eventStartTime)) {
      throw ArgumentError("Event end time cannot be before event start time");
    }
  }

  // Domain Logic - Overlaps
  Stream<List<OverlapPair>> findOverlappingBookings({
    required String orgID,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return getRequestsStream(
      orgID: orgID,
      isAdmin:
          true, // Internal overlap checks should probably see everything? Or at least expanding matches repo behavior
      start: startTime,
      end: endTime,
      includeStatuses: {RequestStatus.confirmed},
    ).map((requests) {
      var overlaps = <OverlapPair>[];
      // Group requests by roomID
      var requestsByRoom = <String, List<Request>>{};
      for (var request in requests) {
        if (request.ignoreOverlaps) {
          continue;
        }
        // Requests are already expanded by getRequestsStream if we use it?
        // Wait, getRequestsStream expands. Repo.findOverlappingBookings calls listRequests then explicitly expands.
        // If we use getRequestsStream, they are already expanded.
        requestsByRoom.putIfAbsent(request.roomID, () => []).add(request);
      }
      for (var roomID in requestsByRoom.keys) {
        overlaps.addAll(_findOverlapsForList(requestsByRoom[roomID]!));
      }
      return overlaps;
    });
  }

  List<OverlapPair> _findOverlapsForList(List<Request> requests) {
    var overlaps = <OverlapPair>[];
    requests.sort((a, b) => a.eventStartTime.compareTo(b.eventStartTime));
    for (var i = 0; i < requests.length; i++) {
      var l = requests[i];
      for (var j = i + 1; j < requests.length; j++) {
        var r = requests[j];
        if (r.eventStartTime.isAfter(l.eventEndTime)) {
          break;
        }
        if (_doRequestsOverlap(l, r)) {
          overlaps.add(OverlapPair(l, r));
        }
      }
    }
    return overlaps;
  }

  bool _doRequestsOverlap(Request a, Request b) {
    if (a.roomID != b.roomID) return false;
    if (!a.eventStartTime.isBefore(b.eventEndTime) ||
        !b.eventStartTime.isBefore(a.eventEndTime)) {
      return false;
    }
    return true;
  }

  // Pass-through Write Methods to BookingRepo
  Future<void> submitBookingRequest(
    String orgID,
    Request request,
    PrivateRequestDetails privateDetails,
  ) {
    validateRequest(request);
    return _bookingRepo.submitBookingRequest(orgID, request, privateDetails);
  }

  Future<void> updateBooking(
    String orgID,
    Request originalRequest,
    Request updatedRequest,
    PrivateRequestDetails privateDetails,
    RequestStatus status,
    RecurringBookingEditChoiceProvider choiceProvider,
  ) {
    validateRequest(updatedRequest);
    return _bookingRepo.updateBooking(
      orgID,
      originalRequest,
      updatedRequest,
      privateDetails,
      status,
      choiceProvider,
    );
  }

  Future<void> addBooking(
    String orgID,
    Request request,
    PrivateRequestDetails privateDetails,
  ) {
    validateRequest(request);
    return _bookingRepo.addBooking(orgID, request, privateDetails);
  }

  Future<void> endBooking(String orgID, String requestID, DateTime end) {
    return _bookingRepo.endBooking(orgID, requestID, end);
  }

  Future<void> ignoreOverlaps(String orgID, String requestID) {
    return _bookingRepo.ignoreOverlaps(orgID, requestID);
  }

  Future<void> confirmRequest(String orgID, String requestID) {
    return _bookingRepo.confirmRequest(orgID, requestID);
  }

  Future<void> denyRequest(String orgID, String requestID) {
    return _bookingRepo.denyRequest(orgID, requestID);
  }

  Future<void> revisitBookingRequest(String orgID, Request request) {
    return _bookingRepo.revisitBookingRequest(orgID, request);
  }

  Stream<List<DecoratedLogEntry>> decorateLogs(
    String orgID,
    Stream<List<RequestLogEntry>> logStream,
  ) {
    return _bookingRepo.decorateLogs(orgID, logStream);
  }

  Future<void> deleteBooking(
    String orgID,
    Request request,
    RecurringBookingEditChoiceProvider choiceProvider,
  ) {
    return _bookingRepo.deleteBooking(orgID, request, choiceProvider);
  }

  final List<BlackoutWindow> _defaultBlackoutWindows = [
    BlackoutWindow(
      start: DateTime(2023, 1, 1, 0, 0),
      end: DateTime(2023, 1, 1, 5, 59),
      recurrenceRule: 'FREQ=DAILY',
      reason: "Too Early",
    ),
    BlackoutWindow(
      start: DateTime(2023, 1, 1, 22, 0),
      end: DateTime(2023, 1, 1, 23, 59),
      recurrenceRule: 'FREQ=DAILY',
      reason: "Too Late",
    ),
  ];

  Stream<List<BlackoutWindow>> listBlackoutWindows(
    Organization org,
    DateTime startTime,
    DateTime endTime,
  ) {
    Set<String>? roomIDs;
    if (org.globalRoomID != null) {
      roomIDs = {org.globalRoomID!};
    }
    return listRequests(
      orgID: org.id!,
      startTime: startTime,
      endTime: endTime,
      includeStatuses: {RequestStatus.confirmed},
      includeRoomIDs: roomIDs,
    ).map((requests) {
      var windows = requests
          .where((r) => r.roomID == org.globalRoomID)
          .map((r) => BlackoutWindow.fromRequest(r))
          .toList();
      windows.addAll(_defaultBlackoutWindows);
      return windows;
    });
  }

  // Pass-through Read Methods
  Stream<List<Request>> listRequests({
    required String orgID,
    required DateTime startTime,
    required DateTime endTime,
    Set<RequestStatus>? includeStatuses,
    Set<String>? includeRoomIDs,
  }) {
    return _bookingRepo.listRequests(
      orgID: orgID,
      startTime: startTime,
      endTime: endTime,
      includeStatuses: includeStatuses,
      includeRoomIDs: includeRoomIDs,
    );
  }

  Stream<PrivateRequestDetails?> getRequestDetails(
    String orgID,
    String requestID,
  ) {
    return _bookingRepo.getRequestDetails(orgID, requestID);
  }

  Stream<Request?> getRequest(String orgID, String requestID) {
    return _bookingRepo.getRequest(orgID, requestID);
  }
}

class OverlapPair {
  final Request first;
  final Request second;

  OverlapPair(this.first, this.second);

  @override
  String toString() {
    return "OverlapPair(first: ${first.id}, second: ${second.id})";
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverlapPair &&
          runtimeType == other.runtimeType &&
          first == other.first &&
          second == other.second;

  @override
  int get hashCode => first.hashCode ^ second.hashCode;
}
