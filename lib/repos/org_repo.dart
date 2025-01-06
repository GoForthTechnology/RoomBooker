import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/entities/organization.dart';
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
      rooms: [],
      acceptingAdminRequests: false,
    );
    return _db.runTransaction((t) async {
      var orgRef = await _db.collection("orgs").add(org.toJson());
      _userRepo.addOrg(t, user.uid, orgRef.id);
      return orgRef.id;
    });
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
    return _adminRequestRef(orgID, user.uid).set(entry.toJson());
  }

  Stream<List<AdminEntry>> adminRequests(String orgID) {
    return _adminRequestsRef(orgID).snapshots().map((s) {
      return s.docs.map((d) {
        return AdminEntry.fromJson(d.data()).copyWith(id: d.id);
      }).toList();
    });
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
      var request =
          AdminEntry.fromJson(requestData.data()!).copyWith(id: requestData.id);
      t.delete(requestRef);
      t.set(_activeAdminRef(orgID, userID), request.toJson());
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
    return _activeAdminsRef(orgID).snapshots().map((s) {
      if (s.docs.isEmpty) {
        return [];
      }
      return s.docs.map((d) {
        return AdminEntry.fromJson(d.data()).copyWith(id: d.id);
      }).toList();
    });
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

  Future<void> addRoom(String orgID, String roomName) async {
    return _db.runTransaction((t) async {
      var orgRef = _db.collection("orgs").doc(orgID);
      var org = await orgRef.get();
      if (!org.exists) {
        return Future.error("Organization not found");
      }
      var data = org.data()!;
      var rooms = data["rooms"] as List<dynamic>? ?? [];
      rooms.add({"name": roomName});
      await orgRef.update({"rooms": rooms});
    });
  }

  Future<void> removeRoom(String orgID, String roomName) async {
    _db.runTransaction((t) async {
      var orgRef = _db.collection("orgs").doc(orgID);
      var org = await orgRef.get();
      if (!org.exists) {
        return Future.error("Organization not found");
      }
      var data = org.data()!;
      var rooms = data["rooms"] as List<dynamic>? ?? [];
      rooms.removeWhere((r) => r["name"] == roomName);
      await orgRef.update({"rooms": rooms});
    });
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

    yield* _userRepo.getUser(user!.uid).flatMap((profile) {
      var orgIDs = profile?.orgIDs ?? [];
      var streams = orgIDs.map(getOrg).toList();
      if (streams.isEmpty) {
        List<Organization> empty = [];
        return Stream.value(empty);
      }
      return Rx.combineLatestList(streams)
          .map((orgs) => orgs.where((o) => o != null).map((o) => o!).toList());
    });
  }

  DocumentReference<Map<String, dynamic>> _adminRequestRef(
      String orgID, String userID) {
    return _adminRequestsRef(orgID).doc(userID);
  }

  CollectionReference<Map<String, dynamic>> _adminRequestsRef(String orgID) {
    return _db.collection("orgs").doc(orgID).collection("admin-requests");
  }

  CollectionReference<Map<String, dynamic>> _activeAdminsRef(String orgID) {
    return _db.collection("orgs").doc(orgID).collection("active-admins");
  }

  DocumentReference<Map<String, dynamic>> _activeAdminRef(
      String orgID, String userID) {
    return _activeAdminsRef(orgID).doc(userID);
  }
}
