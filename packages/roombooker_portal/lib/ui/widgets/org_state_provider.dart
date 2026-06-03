import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/services/auth_service.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/repos/org_repo.dart';
import 'package:roombooker_core/data/repos/user_repo.dart';

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

class OrgStateProvider extends StatefulWidget {
  final String orgID;
  final Widget child;

  const OrgStateProvider({super.key, required this.orgID, required this.child});

  @override
  State<OrgStateProvider> createState() => _OrgStateProviderState();
}

class _OrgStateProviderState extends State<OrgStateProvider> {
  Future<OrgState?>? _future;

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
    return profile.orgIDs.contains(widget.orgID);
  }

  String? _lastUserID;

  void _loadState() {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    var userRepo = Provider.of<UserRepo>(context, listen: false);
    var authService = Provider.of<AuthService>(context, listen: false);

    _future = Future.delayed(Duration.zero, () async {
      var org = await orgRepo.getOrg(widget.orgID).first;
      var isAdmin = await _currentUserIsAdmin(authService, userRepo);
      if (org == null) return null;
      return OrgState(
        org: org,
        currentUserIsAdmin: isAdmin,
        authService: authService,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _lastUserID = Provider.of<AuthService>(context, listen: false).getCurrentUserID();
    _loadState();
  }

  @override
  void didUpdateWidget(OrgStateProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orgID != widget.orgID) {
      _loadState();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var authService = Provider.of<AuthService>(context, listen: true);
    var currentUserID = authService.getCurrentUserID();
    if (_lastUserID != currentUserID) {
      _lastUserID = currentUserID;
      _loadState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrgState?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold();
        }
        if (snapshot.hasError) {
          log('Error loading organization state', error: snapshot.error);
          return const Center(child: Text('Error loading organization'));
        }
        final data = snapshot.data;
        if (!snapshot.hasData || data == null) {
          return const Center(child: Text('Organization not found'));
        }
        return ChangeNotifierProvider.value(
          value: data,
          child: widget.child,
        );
      },
    );
  }
}
