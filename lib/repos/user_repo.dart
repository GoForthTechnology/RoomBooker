import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_booker/entities/user_profile.dart';

class UserRepo extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRepo();

  Future<void> addUser(User user) async {
    try {
      await _userRef(user.uid).set(UserProfile(orgIDs: []));
    } catch (e) {
      return Future.error(e);
    }
  }

  void addOrg(Transaction t, String userID, String orgID) async {
    var userRef = _userRef(userID);
    var profile = await t.get(userRef).then((s) => s.data());
    if (profile == null) {
      t.set(userRef, UserProfile(orgIDs: [orgID]));
    } else {
      t.update(_db.collection("users").doc(userID), {
        'orgIDs': FieldValue.arrayUnion([orgID]),
      });
    }
  }

  void removeOrg(Transaction t, String userID, String orgID) async {
    var userRef = _db.collection('users').doc(userID);
    t.update(userRef, {
      'orgIDs': FieldValue.arrayRemove([orgID]),
    });
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
    return _db.collection('users').doc(uID).withConverter(
        fromFirestore: (snapshot, _) => UserProfile.fromJson(snapshot.data()!),
        toFirestore: (profile, _) => profile.toJson());
  }
}
