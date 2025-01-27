import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/repos/org_repo.dart';

class OrgState extends ChangeNotifier {
  final Organization org;

  OrgState({required this.org});

  bool currentUserIsAdmin() {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false; // not logged in
    }
    return org.ownerID == user.uid;
  }
}

class OrgStateProvider extends StatelessWidget {
  final String orgID;
  final Widget child;

  const OrgStateProvider({super.key, required this.orgID, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Organization?>(
      future: Provider.of<OrgRepo>(context, listen: false).getOrg(orgID).first,
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
          create: (_) => OrgState(org: snapshot.data!),
          child: child,
        );
      },
    );
  }
}
