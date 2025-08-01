import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:rxdart/rxdart.dart';

enum RecurringBookingEditChoice {
  thisInstance,
  thisAndFuture,
  all,
}

class OrgRepo extends ChangeNotifier {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepo _userRepo;
  final RoomRepo _roomRepo;

  OrgRepo({required UserRepo userRepo, required RoomRepo roomRepo})
      : _userRepo = userRepo,
        _roomRepo = roomRepo;

  Future<void> enableGlobalBookings(String orgID) async {
    var roomID = await _roomRepo.addRoom(
        orgID,
        Room(
          name: "All Rooms",
        ));

    await _db.collection("orgs").doc(orgID).update({
      "globalRoomID": roomID,
    });
  }

  Future<String> addOrgForCurrentUser(String orgName) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    var org = Organization(
      name: orgName,
      ownerID: user.uid,
      acceptingAdminRequests: false,
      notificationSettings:
          NotificationSettings.defaultSettings(user.email ?? ""),
    );
    // TODO: add an initial room for the organization
    var orgID = await _db.runTransaction((t) async {
      var orgRef = await _db.collection("orgs").add(org.toJson());
      _userRepo.addOrg(t, user.uid, orgRef.id);
      return orgRef.id;
    });
    _analytics.logEvent(name: "AddOrg", parameters: {
      "orgID": orgID,
    });
    return orgID;
  }

  Future<void> updateNotificationSettings(
      String orgID, NotificationSettings settings) async {
    await _db.collection("orgs").doc(orgID).update({
      "notificationSettings": settings.toJson(),
    });
    _analytics.logEvent(
        name: "UpdateNotificationSettings",
        parameters: {"orgID": orgID, "settings": settings.toJson()});
  }

  Future<void> addAdminRequestForCurrentUser(String orgID) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    if (user.email == null) {
      return Future.error("User does not have an email address");
    }
    var entry = AdminEntry(email: user.email!, lastUpdated: DateTime.now());
    await _db.runTransaction((t) async {
      _userRepo.addOrg(t, user.uid, orgID);
      t.set(_adminRequestRef(orgID, user.uid), entry);
    });
    _analytics.logEvent(name: "AddAdminRequest", parameters: {
      "orgID": orgID,
      "userID": user.uid,
    });
  }

  Stream<List<AdminEntry>> adminRequests(String orgID) {
    return _adminRequestsRef(orgID)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Future<void> denyAdminRequest(String orgID, String userID) async {
    await _adminRequestRef(orgID, userID).delete();
    _analytics.logEvent(name: "DenyAdminRequest", parameters: {
      "orgID": orgID,
      "userID": userID,
    });
  }

  Future<void> approveAdminRequest(String orgID, String userID) async {
    await _db.runTransaction((t) async {
      var requestRef = _adminRequestRef(orgID, userID);
      var requestData = await t.get(requestRef);
      if (!requestData.exists) {
        return Future.error("Request not found");
      }
      var request = requestData.data();
      t.delete(requestRef);
      t.set(_activeAdminRef(orgID, userID), request!);
    });
    _analytics.logEvent(name: "ApproveAdminRequest", parameters: {
      "orgID": orgID,
      "userID": userID,
    });
  }

  Future<void> removeAdmin(String orgID, String userID) async {
    await _db.runTransaction((t) async {
      var adminRef = _activeAdminRef(orgID, userID);
      t.delete(adminRef);
      //_userRepo.removeOrg(t, userID, orgID);
    });
    _analytics.logEvent(name: "RemoveAdmin", parameters: {
      "orgID": orgID,
      "userID": userID,
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

  Future<void> publishOrg(String orgID) async {
    return _db.collection("orgs").doc(orgID).update({
      "publiclyVisible": true,
    });
  }

  Future<void> hideOrg(String orgID) async {
    return _db.collection("orgs").doc(orgID).update({
      "publiclyVisible": false,
    });
  }

  Future<void> removeOrg(String orgID) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    await _db.runTransaction((t) async {
      var orgRef = _db.collection("orgs").doc(orgID);
      var org = await orgRef.get();
      if (!org.exists) {
        return Future.error("Organization not found");
      }
      await orgRef.delete();
      _userRepo.removeOrg(t, user.uid, orgID);
    });
    _analytics.logEvent(name: "RemoveOrg", parameters: {
      "orgID": orgID,
    });
  }

  Stream<Organization?> getOrg(String orgID) async* {
    yield* _db.collection("orgs").doc(orgID).snapshots().map((s) {
      if (!s.exists) {
        return null;
      }
      var json = s.data()!;
      var org = Organization.fromJson(json).copyWith(id: s.id);
      return org;
    });
  }

  Stream<List<Organization>> getOrgs({bool excludeOwned = false}) async* {
    Set<String> ownedOrgs = {};
    var user = FirebaseAuth.instance.currentUser;
    if (excludeOwned && user != null) {
      var profile = await _userRepo.getUser(user.uid);
      ownedOrgs = Set.from(profile?.orgIDs ?? []);
    }
    yield* _db
        .collection("orgs")
        .where("publiclyVisible", isEqualTo: true)
        .withConverter(
          fromFirestore: (snapshot, _) =>
              Organization.fromJson(snapshot.data()!).copyWith(id: snapshot.id),
          toFirestore: (org, _) => org.toJson(),
        )
        .snapshots()
        .map((s) => s.docs
            .map((d) => d.data())
            .toList()
            .where((o) => !ownedOrgs.contains(o.id!))
            .toList());
  }

  Stream<List<Organization>> getOrgsForCurrentUser() async* {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log("foo");
      yield* Stream.value([]);
      return;
    }

    yield* _userRepo
        .streamUser(user.uid)
        .map((profile) {
          var orgIDs = profile?.orgIDs ?? [];
          var streams = orgIDs.map(getOrg).toList();
          return Rx.combineLatestList(streams).map(
              (orgs) => orgs.where((o) => o != null).map((o) => o!).toList());
        })
        .switchMap((s) => s)
        .startWith([]);
  }

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
}
