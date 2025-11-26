import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

abstract class AuthService {
  String? getCurrentUserID();
  String? getCurrentUserEmail();
}

class FirebaseAuthService extends ChangeNotifier implements AuthService {
  @override
  String? getCurrentUserEmail() {
    return FirebaseAuth.instance.currentUser?.email;
  }

  @override
  String? getCurrentUserID() {
    return FirebaseAuth.instance.currentUser?.uid;
  }
}
