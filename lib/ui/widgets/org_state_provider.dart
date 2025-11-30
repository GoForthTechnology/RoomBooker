import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:rxdart/rxdart.dart';

class OrgState extends ChangeNotifier {
  final Organization org;
  final Map<String, AdminEntry> admins;

  OrgState({required this.org, required this.admins});

  bool currentUserIsAdmin() {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false; // not logged in
    }
    if (user.uid == org.ownerID) {
      return true; // owner is always an admin
    }
    return admins.containsKey(user.uid);
  }
}

class OrgStateProvider extends StatelessWidget {
  final String orgID;
  final Widget child;

  const OrgStateProvider({super.key, required this.orgID, required this.child});

  @override
  Widget build(BuildContext context) {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    // TEMPORARY DEBUG: Bypass Rx.combineLatest2
    /*
    return FutureBuilder<OrgState?>(
      future: Rx.combineLatest2(
        orgRepo.getOrg(orgID),
        orgRepo.activeAdmins(orgID),
        (org, admins) {
          print("DEBUG: combineLatest2 called with org: $org, admins: $admins");
          if (org == null) {
            return null;
          }
          return OrgState(org: org, admins: {for (var a in admins) a.id!: a});
        },
      ).first,
      */
    return FutureBuilder<OrgState?>(
      future: Future.delayed(Duration.zero, () async {
        var org = await orgRepo.getOrg(orgID).first;
        var admins = await orgRepo.activeAdmins(orgID).first;
        if (org == null) return null;
        return OrgState(org: org, admins: {for (var a in admins) a.id!: a});
      }),
      builder: (context, snapshot) {
        print(
          "DEBUG: FutureBuilder snapshot: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, error: ${snapshot.error}",
        );
        if (snapshot.hasData) {
          print("DEBUG: FutureBuilder has data: ${snapshot.data}");
        }
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
