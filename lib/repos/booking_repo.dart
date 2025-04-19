import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:rxdart/rxdart.dart';

typedef RecurringBookingEditChoiceProvider = Future<RecurringBookingEditChoice?>
    Function();

class BookingRepo extends ChangeNotifier {
  BookingRepo({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance,
        _analytics = FirebaseAnalytics.instance;

  final FirebaseFirestore _db;
  final FirebaseAnalytics _analytics;

  Future<void> submitBookingRequest(String orgID, Request request,
      PrivateRequestDetails privateDetails) async {
    await _db.runTransaction((t) async {
      var requestRef = _pendingBookingsRef(orgID).doc();
      t.set(requestRef, request);
      var privateDetailsRef = _privateRequestDetailsRef(orgID, requestRef.id);
      t.set(privateDetailsRef, privateDetails);
    });
    _analytics.logEvent(name: "SubmitBookingRequest", parameters: {
      "orgID": orgID,
      "requestID": request.id ?? "",
    });
  }

  Future<void> updateBooking(
    String orgID,
    Request request,
    PrivateRequestDetails privateDetails,
    RequestStatus status,
    RecurringBookingEditChoiceProvider choiceProvider,
  ) async {
    await _db.runTransaction((t) async {
      switch (status) {
        case RequestStatus.pending:
          var requestRef = _pendingBookingsRef(orgID).doc(request.id);
          t.set(requestRef, request);
          break;
        case RequestStatus.confirmed:
          await _updateConfirmedBooking(
              t, request, privateDetails, orgID, choiceProvider);
          break;
        case RequestStatus.unknown:
        case RequestStatus.denied:
          throw UnimplementedError();
      }
      var privateDetailsRef = _privateRequestDetailsRef(orgID, request.id!);
      t.set(privateDetailsRef, privateDetails);
    });
    _analytics.logEvent(name: "UpdateBooking", parameters: {
      "orgID": orgID,
      "requestID": request.id ?? "",
    });
  }

  Future<void> addBooking(String orgID, Request request,
      PrivateRequestDetails privateDetails) async {
    await _db.runTransaction((t) async {
      _addBooking(orgID, request, privateDetails, t);
    });
    _analytics.logEvent(name: "AddBooking", parameters: {
      "orgID": orgID,
      "requestID": request.id ?? "",
    });
  }

  void _addBooking(String orgID, Request request,
      PrivateRequestDetails privateDetails, Transaction t) {
    var requestRef = _confirmedRequestsRef(orgID).doc();
    t.set(requestRef, request);
    var privateDetailsRef = _privateRequestDetailsRef(orgID, requestRef.id);
    t.set(privateDetailsRef, privateDetails);
  }

  Future<void> endBooking(String orgID, String requestID, DateTime end) async {
    var trimmedEnd = DateTime(end.year, end.month, end.day, 0, 0);
    await _confirmedRequestsRef(orgID).doc(requestID).update({
      "recurrancePattern.end": trimmedEnd.toString(),
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
    switch (choice) {
      case RecurringBookingEditChoice.all:
        return _db.runTransaction((t) async {
          _deleteBooking(orgID, request.id!, t);
        });
      case RecurringBookingEditChoice.thisAndFuture:
        return endBooking(orgID, request.id!, request.eventStartTime);
      case RecurringBookingEditChoice.thisInstance:
        var originalRequestRef = _confirmedRequestsRef(orgID).doc(request.id!);
        var snapshot = await originalRequestRef.get();
        var originalBooking = snapshot.data();
        var udpatedBooking =
            _deleteRecurrance(originalBooking!, request.eventEndTime);
        return originalRequestRef.set(udpatedBooking);
      case null:
        throw UnimplementedError();
    }
  }

  void _deleteBooking(String orgID, String requestID, Transaction t) {
    var requestRef = _confirmedRequestsRef(orgID).doc(requestID);
    var privateDetailsRef = _privateRequestDetailsRef(orgID, requestID);
    t.delete(requestRef);
    t.delete(privateDetailsRef);
  }

  Stream<Request?> getRequest(String orgID, String requestID) {
    return _confirmedRequestsRef(orgID)
        .doc(requestID)
        .snapshots()
        .map((s) => s.data())
        .flatMap((request) {
      if (request != null) {
        return Stream.value(request);
      }
      return _pendingBookingsRef(orgID)
          .doc(requestID)
          .snapshots()
          .map((s) => s.data());
    });
  }

  Stream<PrivateRequestDetails?> getRequestDetails(
      String orgID, String requestID) {
    return _privateRequestDetailsRef(orgID, requestID)
        .snapshots()
        .map((s) => s.data());
  }

  Stream<List<Request>> listRequests(
      {required String orgID,
      required DateTime startTime,
      required DateTime endTime,
      Set<RequestStatus>? includeStatuses,
      Set<String>? includeRoomIDs}) {
    List<Query<Request>> queries = [];
    var hasConfirmed = includeStatuses == null ||
        includeStatuses.contains(RequestStatus.confirmed);
    final frequencyPath = FieldPath(["recurrancePattern", "frequency"]);
    if (hasConfirmed) {
      queries.add(_confirmedRequestsRef(orgID)
          .where(frequencyPath, isEqualTo: "never"));
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
        .map((q) => q.where("eventStartTime",
            isGreaterThanOrEqualTo: startTime.toString()))
        .toList();
    queries = queries
        .map((q) =>
            q.where("eventEndTime", isLessThanOrEqualTo: endTime.toString()))
        .toList();
    // Add this one after the queries that are bound to the current time window
    if (hasConfirmed) {
      final endPath = FieldPath(["recurrancePattern", "end"]);
      queries.add(_confirmedRequestsRef(orgID)
          .where(frequencyPath, isNotEqualTo: "never")
          .where(Filter.or(
            Filter(endPath, isNull: true),
            Filter(endPath, isLessThan: endTime.toString()),
          )));
    }
    if (includeRoomIDs != null) {
      queries = queries
          .map((q) => q.where("roomID", whereIn: includeRoomIDs))
          .toList();
    }
    var streams = queries
        .map((q) =>
            q.snapshots().map((s) => s.docs.map((d) => d.data()).toList()))
        .map((s) => s);
    return Rx.combineLatestList(streams).map((listOfLists) {
      return listOfLists.flattenedToList;
    }).startWith([]);
  }

  Stream<List<BlackoutWindow>> listBlackoutWindows(String orgID) =>
      Future.value([
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
      ]).asStream();

  Future<void> confirmRequest(String orgID, String requestID) async {
    var requestRef = _pendingBookingsRef(orgID).doc(requestID);
    var confirmedRef = _confirmedRequestsRef(orgID).doc(requestID);
    return _db.runTransaction((t) async {
      var request = await t.get(requestRef);
      var data = request.data();
      if (data == null) {
        return;
      }
      t.set(confirmedRef, data);
      t.delete(requestRef);
    }).then((value) => _analytics.logEvent(name: "ConfirmRequest", parameters: {
          "orgID": orgID,
          "requestID": requestID,
        }));
  }

  Future<void> denyRequest(String orgID, String requestID) {
    var requestRef = _pendingBookingsRef(orgID).doc(requestID);
    var deniedRef = _deniedRequestsRef(orgID).doc(requestID);
    return _db.runTransaction((t) async {
      var request = await t.get(requestRef);
      var data = request.data();
      if (data == null) {
        return;
      }
      t.set(deniedRef, data);
      t.delete(requestRef);
    }).then((value) => _analytics.logEvent(name: "DenyRequest", parameters: {
          "orgID": orgID,
          "requestID": requestID,
        }));
  }

  Future<void> revisitBookingRequest(String orgID, Request request) async {
    var requestRef = _pendingBookingsRef(orgID).doc(request.id);
    var oldRef = request.status == RequestStatus.confirmed
        ? _confirmedRequestsRef(orgID).doc(request.id)
        : _deniedRequestsRef(orgID).doc(request.id);
    return _db.runTransaction((t) async {
      var request = await t.get(oldRef);
      var data = request.data();
      if (data == null) {
        throw "Request not found!";
      }
      t.set(requestRef, data);
      t.delete(oldRef);
    }).then((value) => _analytics.logEvent(
        name: "RevisitRequest",
        parameters: {"orgID": orgID, "requestID": request.id ?? ""}));
  }

  Future<void> _updateConfirmedBooking(
      Transaction t,
      Request request,
      PrivateRequestDetails privateDetails,
      String orgID,
      RecurringBookingEditChoiceProvider choiceProvider) async {
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
            end: _stripTime(request.eventEndTime).subtract(Duration(days: 1)));
        var updatedOrignalRequest =
            originalBooking.copyWith(recurrancePattern: updatedPattern);
        t.set(originalRequestRef, updatedOrignalRequest);

        // Start a new Recurring booking with the new request
        var newRequest = request.copyWith(id: null);
        _addBooking(orgID, newRequest, privateDetails, t);
        break;
      case RecurringBookingEditChoice.all:
        var newBooking = request.copyWith(
          eventStartTime: originalBooking.eventEndTime,
          eventEndTime: originalBooking.eventEndTime,
        );
        t.set(originalRequestRef, newBooking);
        break;
    }
  }

  DocumentReference<PrivateRequestDetails> _privateRequestDetailsRef(
      String orgID, String requestID) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection("request-details")
        .doc(requestID)
        .withConverter(
          fromFirestore: (snapshot, _) =>
              PrivateRequestDetails.fromJson(snapshot.data()!)
                  .copyWith(id: snapshot.id),
          toFirestore: (details, _) => details.toJson(),
        );
  }

  CollectionReference<Request> _pendingBookingsRef(String orgID) {
    return _bookingCollectionRef(
        orgID, "pending-requests", RequestStatus.pending);
  }

  CollectionReference<Request> _deniedRequestsRef(String orgID) {
    return _bookingCollectionRef(
        orgID, "denied-requests", RequestStatus.denied);
  }

  CollectionReference<Request> _confirmedRequestsRef(String orgID) {
    return _bookingCollectionRef(
        orgID, "confirmed-requests", RequestStatus.confirmed);
  }

  CollectionReference<Request> _bookingCollectionRef(
      String orgID, String collectionName, RequestStatus status) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection(collectionName)
        .withConverter(
          fromFirestore: (snapshot, _) => Request.fromJson(snapshot.data()!)
              .copyWith(id: snapshot.id)
              .copyWith(status: status),
          toFirestore: (request, _) => request.toJson(),
        );
  }
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
