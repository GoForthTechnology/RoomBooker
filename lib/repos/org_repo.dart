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
    var org = Organization(name: orgName, ownerID: user.uid, rooms: []);
    return _db.runTransaction((t) async {
      var orgRef = await _db.collection("orgs").add(org.toJson());
      _userRepo.addOrg(t, user.uid, orgRef.id);
      return orgRef.id;
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
}
