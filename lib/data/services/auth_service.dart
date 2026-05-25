import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

abstract class AuthService extends ChangeNotifier {
  String? getCurrentUserID();
  String? getCurrentUserEmail();
  Future<void> logout();
  Future<void> deleteAccount(
    Future<void> Function(String uid, String email) deleteData,
  );
}

class FirebaseAuthService extends ChangeNotifier implements AuthService {
  FirebaseAuthService() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      notifyListeners();
    });
  }

  @override
  String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  @override
  String? getCurrentUserID() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<void> deleteAccount(
    Future<void> Function(String uid, String email) deleteData,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final email = user.email ?? "";

    await deleteData(uid, email);
    await user.delete();
    await FirebaseAuth.instance.signOut();
  }
}
