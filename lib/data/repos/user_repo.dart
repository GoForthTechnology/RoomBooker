import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_booker/data/entities/user_profile.dart';

class UserRepo extends ChangeNotifier {
  final FirebaseFirestore _db;

  UserRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> addUser(User user) async {
    try {
      await _userRef(user.uid).set(UserProfile(orgIDs: []));
    } catch (e) {
      return Future.error(e);
    }
  }

  void addOrg(Transaction t, String userID, String orgID) async {
    var profileRef = _userRef(userID);
    /*var profile = await t.get(profileRef).then((s) => s.data());
    if (profile == null) {
      t.set(profileRef, UserProfile(orgIDs: [orgID]));
    } else {
      t.update(_db.collection("users").doc(userID), {
        'orgIDs': FieldValue.arrayUnion([orgID]),
      });
    }*/
    // TODO: Move this back into the transaction
    var profile = await profileRef.get().then((s) => s.data());
    if (profile == null) {
      profile = UserProfile(orgIDs: [orgID]);
    } else {
      if (profile.orgIDs.contains(orgID)) {
        return;
      }
      profile.orgIDs.add(orgID);
    }
    profileRef.set(profile);
  }

  void removeOrg(Transaction t, String userID, String orgID) async {
    var userRef = _db.collection('users').doc(userID);
    t.update(userRef, {
      'orgIDs': FieldValue.arrayRemove([orgID]),
    });
  }

  Stream<UserProfile?> streamUser(String uID) {
    return _userRef(uID).snapshots().map((s) => s.data());
  }

  Future<UserProfile?> getUser(String uID) {
    return _db.collection('users').doc(uID).get().then((s) {
      if (s.exists) {
        final data = s.data() as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      }
      return null;
    });
  }

  DocumentReference<UserProfile> _userRef(String uID) {
    return _db
        .collection('users')
        .doc(uID)
        .withConverter(
          fromFirestore: (snapshot, _) =>
              UserProfile.fromJson(snapshot.data()!),
          toFirestore: (profile, _) => profile.toJson(),
        );
  }
}
