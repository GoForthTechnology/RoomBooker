import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/entities/blackout_window.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/user_repo.dart';
import 'package:rxdart/rxdart.dart';

class OrgRepo extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepo _userRepo;

  OrgRepo({required UserRepo userRepo}) : _userRepo = userRepo;

  Future<String> addOrgForCurrentUser(String orgName) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    var org = Organization(
      name: orgName,
      ownerID: user.uid,
      acceptingAdminRequests: false,
    );
    var orgID = await _db.runTransaction((t) async {
      var orgRef = await _db.collection("orgs").add(org.toJson());
      _userRepo.addOrg(t, user.uid, orgRef.id);
      return orgRef.id;
    });
    return orgID;
  }

  Future<void> addAdminRequestForCurrentUser(String orgID) {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    if (user.email == null) {
      return Future.error("User does not have an email address");
    }
    var entry = AdminEntry(email: user.email!, lastUpdated: DateTime.now());
    return _adminRequestRef(orgID, user.uid).set(entry);
  }

  Stream<List<AdminEntry>> adminRequests(String orgID) {
    return _adminRequestsRef(orgID)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> denyAdminRequest(String orgID, String userID) {
    return _adminRequestRef(orgID, userID).delete();
  }

  Future<void> approveAdminRequest(String orgID, String userID) {
    return _db.runTransaction((t) async {
      var requestRef = _adminRequestRef(orgID, userID);
      var requestData = await t.get(requestRef);
      if (!requestData.exists) {
        return Future.error("Request not found");
      }
      var request = requestData.data();
      t.delete(requestRef);
      t.set(_activeAdminRef(orgID, userID), request);
      _userRepo.addOrg(t, userID, orgID);
    });
  }

  Future<void> removeAdmin(String orgID, String userID) {
    return _db.runTransaction((t) async {
      var adminRef = _activeAdminRef(orgID, userID);
      t.delete(adminRef);
      _userRepo.removeOrg(t, userID, orgID);
    });
  }

  Stream<List<AdminEntry>> activeAdmins(String orgID) {
    return _activeAdminsRef(orgID)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> enableAdminRequests(String orgID) async {
    return _db.collection("orgs").doc(orgID).update({
      "acceptingAdminRequests": true,
    });
  }

  Future<void> disableAdminRequests(String orgID) async {
    return _db.collection("orgs").doc(orgID).update({
      "acceptingAdminRequests": false,
    });
  }

  Stream<List<Room>> listRooms(String orgID) {
    return _roomsRef(orgID)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> addRoom(String orgID, Room room) async {
    await _roomsRef(orgID).add(room);
  }

  Future<void> removeRoom(String orgID, String roomID) async {
    await _roomRef(orgID, roomID).delete();
  }

  Future<void> removeOrg(String orgID) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    return _db.runTransaction((t) async {
      var orgRef = _db.collection("orgs").doc(orgID);
      var org = await orgRef.get();
      if (!org.exists) {
        return Future.error("Organization not found");
      }
      await orgRef.delete();
      _userRepo.removeOrg(t, user.uid, orgID);
    });
  }

  Stream<Organization?> getOrg(String orgID) async* {
    yield* _db.collection("orgs").doc(orgID).snapshots().map((s) {
      if (!s.exists) {
        return null;
      }
      return Organization.fromJson(s.data()!).copyWith(id: s.id);
    });
  }

  Stream<List<Organization>> getOrgsForCurrentUser() async* {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield* Stream.error("User not logged in");
    }

    yield* _userRepo
        .streamUser(user!.uid)
        .map((profile) {
          var orgIDs = profile.orgIDs;
          var streams = orgIDs.map(getOrg).toList();
          return Rx.combineLatestList(streams).map(
              (orgs) => orgs.where((o) => o != null).map((o) => o!).toList());
        })
        .switchMap((s) => s)
        .startWith([]);
  }

  Future<void> addBookingRequest(String orgID, Request request,
      PrivateRequestDetails privateDetails) async {
    await _db.runTransaction((t) async {
      var requestRef = _bookingRequestsRef(orgID).doc();
      t.set(requestRef, request);
      var privateDetailsRef = _privateRequestDetailsRef(orgID, requestRef.id);
      t.set(privateDetailsRef, privateDetails);
    });
  }

  Future<void> revisitBookingRequest(String orgID, String requestID) async {
    var requestRef = _bookingRequestRef(orgID, requestID);
    await requestRef.update({"status": RequestStatus.pending.name});
  }

  Stream<Request?> getRequest(String orgID, String requestID) {
    return _bookingRequestRef(orgID, requestID)
        .snapshots()
        .map((s) => s.data());
  }

  Stream<PrivateRequestDetails?> getRequestDetails(
      String orgID, String requestID) {
    return _privateRequestDetailsRef(orgID, requestID)
        .snapshots()
        .map((s) => s.data());
  }

  Stream<List<Request>> listRequests(String orgID,
      {List<RequestStatus>? includeStatuses, Set<String>? includeRoomIDs}) {
    Query<Request> query = _bookingRequestsRef(orgID);
    if (includeStatuses != null) {
      query = query.where("status",
          whereIn: includeStatuses.map((s) => s.name).toList());
    }
    if (includeRoomIDs != null) {
      query = query.where("roomID", whereIn: includeRoomIDs);
    }
    return query.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> confirmRequest(String orgID, Request request) async {
    var requestRef = _bookingRequestRef(orgID, request.id!);
    await requestRef.update({"status": RequestStatus.confirmed.name});
  }

  Future<void> denyRequest(String orgID, String requestID) {
    var requestRef = _bookingRequestRef(orgID, requestID);
    return requestRef.update({"status": RequestStatus.denied.name});
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

  DocumentReference<AdminEntry> _adminRequestRef(String orgID, String userID) {
    return _adminRequestsRef(orgID).doc(userID);
  }

  CollectionReference<AdminEntry> _adminRequestsRef(String orgID) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection("admin-requests")
        .withConverter(
          fromFirestore: (snapshot, _) =>
              AdminEntry.fromJson(snapshot.data()!).copyWith(id: snapshot.id),
          toFirestore: (entry, _) => entry.toJson(),
        );
  }

  DocumentReference<AdminEntry> _activeAdminRef(String orgID, String userID) {
    return _activeAdminsRef(orgID).doc(userID);
  }

  CollectionReference<AdminEntry> _activeAdminsRef(String orgID) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection("active-admins")
        .withConverter(
          fromFirestore: (snapshot, _) =>
              AdminEntry.fromJson(snapshot.data()!).copyWith(id: snapshot.id),
          toFirestore: (entry, _) => entry.toJson(),
        );
  }

  DocumentReference<Request> _bookingRequestRef(
      String orgID, String requestID) {
    return _bookingRequestsRef(orgID).doc(requestID);
  }

  DocumentReference<PrivateRequestDetails> _privateRequestDetailsRef(
      String orgID, String requestID) {
    return _bookingRequestsRef(orgID)
        .doc(requestID)
        .collection("private")
        .doc("details")
        .withConverter(
          fromFirestore: (snapshot, _) =>
              PrivateRequestDetails.fromJson(snapshot.data()!),
          toFirestore: (details, _) => details.toJson(),
        );
  }

  CollectionReference<Request> _bookingRequestsRef(String orgID) {
    return _db
        .collection("orgs")
        .doc(orgID)
        .collection("booking-requests")
        .withConverter(
          fromFirestore: (snapshot, _) =>
              Request.fromJson(snapshot.data()!).copyWith(id: snapshot.id),
          toFirestore: (request, _) => request.toJson(),
        );
  }

  DocumentReference<Room> _roomRef(String orgID, String bookingID) {
    return _roomsRef(orgID).doc(bookingID);
  }

  CollectionReference<Room> _roomsRef(String orgID) {
    return _db.collection("orgs").doc(orgID).collection("rooms").withConverter(
          fromFirestore: (snapshot, _) =>
              Room.fromJson(snapshot.data()!).copyWith(id: snapshot.id),
          toFirestore: (request, _) => request.toJson(),
        );
  }
}
