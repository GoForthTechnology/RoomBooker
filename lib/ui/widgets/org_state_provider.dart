import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';

class OrgState extends ChangeNotifier {
  final Organization org;
  // NOTE: This is just a hint that the user is an admin. It is not a guarantee.
  // The final check is done in the database.
  final bool currentUserIsAdmin;
  final AuthService authService;

  OrgState({
    required this.org,
    required this.currentUserIsAdmin,
    required this.authService,
  });
}

class OrgStateProvider extends StatelessWidget {
  final String orgID;
  final Widget child;

  const OrgStateProvider({super.key, required this.orgID, required this.child});

  Future<bool> _currentUserIsAdmin(
    AuthService authService,
    UserRepo userRepo,
  ) async {
    var userID = authService.getCurrentUserID();
    if (userID == null) {
      return false; // not logged in
    }
    var profile = await userRepo.getUser(userID);
    if (profile == null) {
      return false; // user doesn't exist
    }
    return profile.orgIDs.contains(orgID);
  }

  @override
  Widget build(BuildContext context) {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    var userRepo = Provider.of<UserRepo>(context, listen: false);

    return Consumer<FirebaseAuthService>(
      builder: (context, authService, _) => FutureBuilder<OrgState?>(
        future: Future.delayed(Duration.zero, () async {
          var org = await orgRepo.getOrg(orgID).first;
          var isAdmin = await _currentUserIsAdmin(authService, userRepo);
          if (org == null) return null;
          return OrgState(
            org: org,
            currentUserIsAdmin: isAdmin,
            authService: authService,
          );
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            log('Error loading organization state', error: snapshot.error);
            return const Center(child: Text('Error loading organization'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Organization not found'));
          }
          return ChangeNotifierProvider(
            create: (_) => snapshot.data!,
            child: child,
          );
        },
      ),
    );
  }
}
