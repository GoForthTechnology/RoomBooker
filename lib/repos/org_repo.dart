import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/user_repo.dart';
import 'package:rxdart/rxdart.dart';

class Org {
  final String name;

  Org({required this.name});
}

class OrgRepo extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserRepo _userRepo;

  OrgRepo({required UserRepo userRepo}) : _userRepo = userRepo;

  Future<String> addOrgForCurrentUser(String orgName) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.error("User not logged in!");
    }
    var org = Organization(user.uid, name: orgName);
    return _db.runTransaction((t) async {
      var orgRef = await _db.collection("orgs").add(org.toJson());
      _userRepo.addOrg(t, user.uid, orgRef.id);
      return orgRef.id;
    });
  }

  Stream<Organization?> getOrg(String orgID) async* {
    print("foo: $orgID");
    yield* _db.collection("orgs").doc(orgID).snapshots().map((s) {
      if (!s.exists) {
        print("baz");
        return null;
      }
      print("bar");
      return Organization.fromJson(s.data()!);
    });
  }

  Stream<List<Organization>> getOrgsForCurrentUser() async* {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      yield* Stream.error("User not logged in");
    }

    yield* _userRepo.getUser(user!.uid).flatMap((profile) {
      var orgIDs = profile?.orgIDs ?? [];
      print("Found ${orgIDs.length} orgs");
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
