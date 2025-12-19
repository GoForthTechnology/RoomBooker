import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

abstract class AuthService {
  String? getCurrentUserID();
  String? getCurrentUserEmail();
  void logout();
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
  void logout() {
    FirebaseAuth.instance.signOut();
  }
}
