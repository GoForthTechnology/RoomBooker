import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';
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
    return FutureBuilder<OrgState?>(
      future: Rx.combineLatest2(
          orgRepo.getOrg(orgID), orgRepo.activeAdmins(orgID), (org, admins) {
        if (org == null) {
          return null;
        }
        return OrgState(org: org, admins: {for (var a in admins) a.id!: a});
      }).first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
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
