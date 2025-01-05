import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:room_booker/entities/user_profile.dart';

class UserRepo extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRepo();

  Future<void> addUser(User user) async {
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(UserProfile(orgIDs: []).toJson());
    } catch (e) {
      return Future.error(e);
    }
  }

  void addOrg(Transaction t, String userID, String orgID) async {
    var userRef = _db.collection('users').doc(userID);
    t.update(userRef, {
      'orgIDs': FieldValue.arrayUnion([orgID]),
    });
  }

  void removeOrg(Transaction t, String userID, String orgID) async {
    var userRef = _db.collection('users').doc(userID);
    t.update(userRef, {
      'orgIDs': FieldValue.arrayRemove([orgID]),
    });
  }

  Stream<UserProfile?> getUser(String uID) async* {
    yield* _db.collection('users').doc(uID).snapshots().map((s) {
      if (s.exists) {
        final data = s.data() as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      }
      return null;
    });
  }
}
