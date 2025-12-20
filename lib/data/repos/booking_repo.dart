import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/entities/blackout_window.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/logging_service.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:rxdart/rxdart.dart';

typedef RecurringBookingEditChoiceProvider =
    Future<RecurringBookingEditChoice?> Function();

class BookingRepo extends ChangeNotifier {
  BookingRepo({
    required this.logRepo,
    required AnalyticsService analytics,
    required LoggingService logging,
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance,
       _analytics = analytics,
       _logging = logging {
    _detailsCache = DetailCache(
      (orgID, requestID) => _loadRequestDetails(orgID, requestID),
    );
  }

  final FirebaseFirestore _db;
  final AnalyticsService _analytics;
  final LoggingService _logging;
  final LogRepo logRepo;
  late final DetailCache _detailsCache;

  Future<void> _log(
    String orgID,
    String requestID,
    String eventName,
    Action action, {
    Request? before,
    Request? after,
  }) async {
    try {
      await logRepo.addLogEntry(
        orgID: orgID,
        requestID: requestID,
        timestamp: DateTime.now(),
        action: action,
        before: before,
        after: after,
      );
      _analytics.logEvent(
        name: eventName,
        parameters: {"orgID": orgID, "requestID": requestID},
      );
    } catch (e, s) {
      log(
        "Error logging event $eventName for orgID: $orgID, requestID: $requestID",
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  void validateRequest(Request request) {
    if (request.eventEndTime.isBefore(request.eventStartTime)) {
      throw ArgumentError("Event end time cannot be before event start time");
    }
  }

  Future<void> submitBookingRequest(
    String orgID,
    Request request,
    PrivateRequestDetails privateDetails,
  ) async {
    validateRequest(request);
    var id = await _db.runTransaction((t) async {
      var requestRef = _pendingBookingsRef(orgID).doc();
      t.set(requestRef, request);
      var privateDetailsRef = _privateRequestDetailsRef(orgID, requestRef.id);
      t.set(privateDetailsRef, privateDetails);
      return requestRef.id;
    });
    await _log(orgID, id, "SubmitBookingRequest", Action.create);
  }

  Future<void> updateBooking(
    String orgID,
    Request originalRequest,
    Request updatedRequest,
    PrivateRequestDetails privateDetails,
    RequestStatus status,
    RecurringBookingEditChoiceProvider choiceProvider,
  ) async {
    validateRequest(updatedRequest);
    await _db.runTransaction((t) async {
      try {
        switch (status) {
          case RequestStatus.pending:
            var requestRef = _pendingBookingsRef(orgID).doc(updatedRequest.id);
            t.set(requestRef, updatedRequest);
            break;
          case RequestStatus.confirmed:
            await _updateConfirmedBooking(
              t,
              updatedRequest,
              privateDetails,
              orgID,
              choiceProvider,
            );
            break;
          case RequestStatus.unknown:
          case RequestStatus.denied:
            throw UnimplementedError();
        }
        var privateDetailsRef = _privateRequestDetailsRef(
          orgID,

          updatedRequest.id!,
        );
        t.set(privateDetailsRef, privateDetails);
      } catch (e, s) {
        log("Error updating booking", error: e, stackTrace: s);
        rethrow;
      }
    });
    await _log(
      orgID,
      updatedRequest.id!,
      "UpdateBooking",
      Action.update,
      before: originalRequest,
      after: updatedRequest,
    );
  }

  Future<void> addBooking(
    String orgID,
    Request request,
    PrivateRequestDetails privateDetails,
  ) async {
    validateRequest(request);
    var id = await _db.runTransaction((t) async {
      return _addBooking(orgID, request, privateDetails, t);
    });
    await _log(orgID, id, "AddBooking", Action.create);
  }

  String _addBooking(
    String orgID,
    Request request,
    PrivateRequestDetails privateDetails,
    Transaction t,
  ) {
    var requestRef = _confirmedRequestsRef(orgID).doc();
    t.set(requestRef, request);
    var privateDetailsRef = _privateRequestDetailsRef(orgID, requestRef.id);
    t.set(privateDetailsRef, privateDetails);
    return requestRef.id;
  }

  Future<void> endBooking(String orgID, String requestID, DateTime end) async {
    var trimmedEnd = DateTime(end.year, end.month, end.day, 0, 0);
    await _confirmedRequestsRef(
      orgID,
    ).doc(requestID).update({"recurrancePattern.end": trimmedEnd.toString()});
    await _log(orgID, requestID, "EndRecurring", Action.endRecurring);
  }

  Future<void> ignoreOverlaps(String orgID, String requestID) async {
    await _confirmedRequestsRef(
      orgID,
    ).doc(requestID).update({"ignoreOverlaps": true});
    await _log(orgID, requestID, "IgnoreOverlaps", Action.ignoreOverlaps);
  }

  Stream<List<DecoratedLogEntry>> decorateLogs(
    String orgID,
    Stream<List<RequestLogEntry>> logStream,
  ) {
    return logStream.asyncMap((logEntries) async {
      var requests = await Future.wait(
        logEntries.map((e) async {
          Request? request;
          try {
            request = await getRequest(orgID, e.requestID).first;
          } catch (exception) {
            throw Exception(
              "Error fetching request for log entry ${e.id}: $exception",
            );
          }
          if (request == null) {
            return null;
          }
          PrivateRequestDetails? details;
          try {
            details = await getRequestDetails(orgID, e.requestID).first;
          } catch (exception) {
            throw Exception(
              "Error fetching request details for log entry ${e.id}: $exception",
            );
          }
          if (details == null) {
            return null;
          }
          return DecoratedLogEntry(details, entry: e, request: request);
        }),
      );
      return requests.nonNulls.toList();
    });
  }

  Future<void> deleteBooking(
    String orgID,
    Request request,
    RecurringBookingEditChoiceProvider choiceProvider,
  ) async {
    var recurrenceFrequency =
        request.recurrancePattern?.frequency ?? Frequency.never;
    if (recurrenceFrequency == Frequency.never) {
      return _db.runTransaction((t) async {
        _deleteBooking(orgID, request.id!, t);
      });
    }
    var choice = await choiceProvider();
    try {
      switch (choice) {
        case RecurringBookingEditChoice.all:
          return _db.runTransaction((t) async {
            _deleteBooking(orgID, request.id!, t);
          });
        case RecurringBookingEditChoice.thisAndFuture:
          return endBooking(orgID, request.id!, request.eventStartTime);
        case RecurringBookingEditChoice.thisInstance:
          var originalRequestRef = _confirmedRequestsRef(
            orgID,
          ).doc(request.id!);
          var snapshot = await originalRequestRef.get();
          var originalBooking = snapshot.data();
          var udpatedBooking = _deleteRecurrance(
            originalBooking!,
            request.eventEndTime,
          );
          return originalRequestRef.set(udpatedBooking);
        case null:
          throw UnimplementedError();
      }
    } finally {
      await _log(orgID, request.id!, "DeleteBooking", Action.delete);
    }
  }

  void _deleteBooking(String orgID, String requestID, Transaction t) {
    var requestRef = _confirmedRequestsRef(orgID).doc(requestID);
    var privateDetailsRef = _privateRequestDetailsRef(orgID, requestID);
    t.delete(requestRef);
    t.delete(privateDetailsRef);
  }

  Stream<Request?> getRequest(String orgID, String requestID) {
    if (orgID.isEmpty) {
      return Stream.error("Org ID cannot be empty.");
    }
    if (requestID.isEmpty) {
      return Stream.error("Request ID cannot be empty.");
    }
    _logging.debug("Getting request: $requestID");
    return _confirmedRequestsRef(
      orgID,
    ).doc(requestID).snapshots().map((s) => s.data()).flatMap((request) {
      if (request != null) {
        return Stream.value(request);
      }
      return _pendingBookingsRef(
        orgID,
      ).doc(requestID).snapshots().map((s) => s.data());
    });
  }

  Stream<PrivateRequestDetails?> getRequestDetails(
    String orgID,
    String requestID,
  ) {
    return _detailsCache.get(orgID, requestID);
  }

  Stream<PrivateRequestDetails?> _loadRequestDetails(
    String orgID,
    String requestID,
  ) {
    return _privateRequestDetailsRef(
      orgID,
      requestID,
    ).snapshots().map((s) => s.data());
  }

  bool _hasTimeComponent(DateTime dt) {
    return dt.minute != 0 || dt.second != 0 || dt.hour != 0;
  }

  DateTime _removeTimeComponent(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  Stream<List<Request>> listRequests({
    required String orgID,
    required DateTime startTime,
    required DateTime endTime,
    Set<RequestStatus>? includeStatuses,
    Set<String>? includeRoomIDs,
  }) {
    if (_hasTimeComponent(startTime)) {
      startTime = _removeTimeComponent(startTime);
    }
    if (_hasTimeComponent(endTime)) {
      endTime = _removeTimeComponent(endTime);
    }
    List<Query<Request>> queries = [];
    var hasConfirmed =
        includeStatuses == null ||
        includeStatuses.contains(RequestStatus.confirmed);
    final frequencyPath = "recurrancePattern.frequency";
    if (hasConfirmed) {
      queries.add(
        _confirmedRequestsRef(orgID).where(frequencyPath, isEqualTo: "never"),
      );
    }
    if (includeStatuses == null ||
        includeStatuses.contains(RequestStatus.pending)) {
      queries.add(_pendingBookingsRef(orgID));
    }
    if (includeStatuses == null ||
        includeStatuses.contains(RequestStatus.denied)) {
      queries.add(_deniedRequestsRef(orgID));
    }
    queries = queries
        .map(
          (q) => q.where(
            "eventStartTime",
            isGreaterThanOrEqualTo: startTime.toIso8601String(),
          ),
        )
        .toList();
    // BEGIN spooky hack to get around DST shennanigans...
    var endDateStr = endTime.add(Duration(hours: 1)).toIso8601String();
    // END spooky hack that should not be necessary...
    queries = queries
        .map((q) => q.where("eventEndTime", isLessThanOrEqualTo: endDateStr))
        .toList();
    // Add this one after the queries that are bound to the current time window
    if (hasConfirmed) {
      final endPath = "recurrancePattern.end";
      queries.add(
        _confirmedRequestsRef(orgID)
            .where(frequencyPath, isNotEqualTo: "never")
            .where(
              Filter.or(
                Filter(endPath, isNull: true),
                Filter(
                  endPath,
                  isGreaterThanOrEqualTo: startTime.toIso8601String(),
                ),
              ),
            ),
      );
    }
    if (includeRoomIDs != null) {
      queries = queries
          .map((q) => q.where("roomID", whereIn: includeRoomIDs))
          .toList();
    }
    var streams = queries
        .map(
          (q) => q.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
        )
        .map((s) => s);
    return Rx.combineLatestList(streams)
        .map((listOfLists) {
          return listOfLists.flattenedToList;
        })
        .startWith([]);
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

  Future<void> confirmRequest(String orgID, String requestID) async {
    var requestRef = _pendingBookingsRef(orgID).doc(requestID);
    var confirmedRef = _confirmedRequestsRef(orgID).doc(requestID);
    await _db.runTransaction((t) async {
      var request = await t.get(requestRef);
      var data = request.data();
      if (data == null) {
        return;
      }
      t.set(confirmedRef, data);
      t.delete(requestRef);
    });
    await _log(orgID, requestID, "ConfirmRequest", Action.approve);
  }

  Future<void> denyRequest(String orgID, String requestID) async {
    var requestRef = _pendingBookingsRef(orgID).doc(requestID);
    var deniedRef = _deniedRequestsRef(orgID).doc(requestID);
    await _db.runTransaction((t) async {
      var request = await t.get(requestRef);
      var data = request.data();
      if (data == null) {
        return;
      }
      t.set(deniedRef, data);
      t.delete(requestRef);
    });
    await _log(orgID, requestID, "DenyRequest", Action.reject);
  }

  Future<void> revisitBookingRequest(String orgID, Request request) async {
    var requestRef = _pendingBookingsRef(orgID).doc(request.id);
    var oldRef = request.status == RequestStatus.confirmed
        ? _confirmedRequestsRef(orgID).doc(request.id)
        : _deniedRequestsRef(orgID).doc(request.id);
    await _db.runTransaction((t) async {
      var request = await t.get(oldRef);
      var data = request.data();
      if (data == null) {
        throw "Request not found!";
      }
      t.set(requestRef, data);
      t.delete(oldRef);
    });
    await _log(orgID, request.id!, "RevisitRequest", Action.revisit);
  }

  Future<void> _updateConfirmedBooking(
    Transaction t,
    Request request,
    PrivateRequestDetails privateDetails,
    String orgID,
    RecurringBookingEditChoiceProvider choiceProvider,
  ) async {
    var recurrenceFrequency =
        request.recurrancePattern?.frequency ?? Frequency.never;
    if (recurrenceFrequency == Frequency.never) {
      var requestRef = _confirmedRequestsRef(orgID).doc(request.id);
      t.set(requestRef, request);
      return;
    }
    var choice = await choiceProvider();
    if (choice == null) {
      return;
    }
    var originalRequestRef = _confirmedRequestsRef(orgID).doc(request.id);
    var snapshot = await t.get(originalRequestRef);
    if (!snapshot.exists) {
      return;
    }
    var originalBooking = snapshot.data()!;
    switch (choice) {
      case RecurringBookingEditChoice.thisInstance:
        var updatedRequest = _overrideRecurrance(originalBooking, request);
        t.set(originalRequestRef, updatedRequest);
        break;
      case RecurringBookingEditChoice.thisAndFuture:
        // End the orginal booking starting with the request start time
        var updatedPattern = originalBooking.recurrancePattern!.copyWith(
          end: _stripTime(request.eventEndTime).subtract(Duration(days: 1)),
        );
        var updatedOrignalRequest = originalBooking.copyWith(
          recurrancePattern: updatedPattern,
        );
        t.set(originalRequestRef, updatedOrignalRequest);

        // Start a new Recurring booking with the new request
        var newRequest = request.copyWith(id: null);
        _addBooking(orgID, newRequest, privateDetails, t);
        break;
      case RecurringBookingEditChoice.all:
        var newBooking = request.copyWith(
          eventStartTime: originalBooking.eventStartTime,
          eventEndTime: originalBooking.eventEndTime,
        );
        t.set(originalRequestRef, newBooking);
        break;
    }
  }

  DocumentReference<PrivateRequestDetails> _privateRequestDetailsRef(
    String orgID,
    String requestID,
  ) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection("request-details")
        .doc(requestID)
        .withConverter(
          fromFirestore: (snapshot, _) => PrivateRequestDetails.fromJson(
            snapshot.data()!,
          ).copyWith(id: snapshot.id),
          toFirestore: (details, _) => details.toJson(),
        );
  }

  CollectionReference<Request> _pendingBookingsRef(String orgID) {
    return _bookingCollectionRef(
      orgID,
      "pending-requests",
      RequestStatus.pending,
    );
  }

  CollectionReference<Request> _deniedRequestsRef(String orgID) {
    return _bookingCollectionRef(
      orgID,
      "denied-requests",
      RequestStatus.denied,
    );
  }

  CollectionReference<Request> _confirmedRequestsRef(String orgID) {
    return _bookingCollectionRef(
      orgID,
      "confirmed-requests",
      RequestStatus.confirmed,
    );
  }

  CollectionReference<Request> _bookingCollectionRef(
    String orgID,
    String collectionName,
    RequestStatus status,
  ) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection(collectionName)
        .withConverter(
          fromFirestore: (snapshot, _) => Request.fromJson(
            snapshot.data()!,
          ).copyWith(id: snapshot.id).copyWith(status: status),
          toFirestore: (request, _) => request.toJson(),
        );
  }

  Stream<List<OverlapPair>> findOverlappingBookings(
    String orgID,
    DateTime startTime,
    DateTime endTime,
  ) {
    return listRequests(
      orgID: orgID,
      startTime: startTime,
      endTime: endTime,
      includeStatuses: {RequestStatus.confirmed},
    ).map((requests) {
      var overlaps = <OverlapPair>[];
      // Group requests by roomID
      var requestsByRoom = <String, List<Request>>{};
      for (var request in requests) {
        if (request.ignoreOverlaps) {
          continue;
        }
        requestsByRoom
            .putIfAbsent(request.roomID, () => [])
            .addAll(request.expand(startTime, endTime));
      }
      for (var roomID in requestsByRoom.keys) {
        overlaps.addAll(findOverlaps(requestsByRoom[roomID]!));
      }
      return overlaps;
    });
  }
}

List<OverlapPair> findOverlaps(List<Request> requests) {
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

DateTime _stripTime(DateTime dt) {
  return DateTime(dt.year, dt.month, dt.day);
}

Request _deleteRecurrance(Request request, DateTime day) {
  var overrides = request.recurranceOverrides ?? {};
  overrides[_stripTime(day)] = null;
  return request.copyWith(recurranceOverrides: overrides);
}

Request _overrideRecurrance(Request request, Request override) {
  var overrides = request.recurranceOverrides ?? {};
  overrides[_stripTime(override.eventStartTime)] = override;
  return request.copyWith(recurranceOverrides: overrides);
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

class DetailCache {
  final Map<String, Subject<PrivateRequestDetails>> _cache = {};
  final Set<StreamSubscription> _subs = {};
  final Stream<PrivateRequestDetails?> Function(String, String) _loader;

  DetailCache(this._loader);

  Stream<PrivateRequestDetails?> get(String orgID, String requestID) async* {
    var cachedValue = _cache[requestID];
    if (cachedValue != null) {
      yield* cachedValue.stream;
    } else {
      var subject = BehaviorSubject<PrivateRequestDetails>();
      _cache[requestID] = subject;
      try {
        _subs.add(
          _loader(orgID, requestID).listen((event) {
            if (event != null) subject.add(event);
          }),
        );
      } catch (e, s) {
        log(
          "Error loading details for $orgID, $requestID",
          error: e,
          stackTrace: s,
        );
        subject.addError(e);
      }
      yield* subject.stream;
    }
  }
}
