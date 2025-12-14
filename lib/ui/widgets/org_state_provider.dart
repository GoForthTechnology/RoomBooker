import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';

class OrgState extends ChangeNotifier {
  final Organization org;
  final Map<String, AdminEntry> admins;
  final AuthService authService;

  OrgState({
    required this.org,
    required this.admins,
    required this.authService,
  });

  bool currentUserIsAdmin() {
    var userID = authService.getCurrentUserID();
    if (userID == null) {
      return false; // not logged in
    }
    if (userID == org.ownerID) {
      return true; // owner is always an admin
    }
    return admins.containsKey(userID);
  }
}

class OrgStateProvider extends StatelessWidget {
  final String orgID;
  final Widget child;

  const OrgStateProvider({super.key, required this.orgID, required this.child});

  @override
  Widget build(BuildContext context) {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    var authService = Provider.of<FirebaseAuthService>(context, listen: false);

    return FutureBuilder<OrgState?>(
      future: Future.delayed(Duration.zero, () async {
        var org = await orgRepo.getOrg(orgID).first;
        var admins = await orgRepo.activeAdmins(orgID).first;
        if (org == null) return null;
        return OrgState(
          org: org,
          admins: {for (var a in admins) a.id!: a},
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
    );
  }
}
