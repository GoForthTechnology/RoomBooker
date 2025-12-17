import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/router.dart';

class NavigationEvent {
  final PageRouteInfo route;
  final bool replace;

  NavigationEvent(this.route, {this.replace = false});
}

class LandingViewModel extends ChangeNotifier {
  final FirebaseAuth _auth;
  final PreferencesRepo _prefsRepo;
  final OrgRepo _orgRepo;
  final AnalyticsService _analyticsService;

  LandingViewModel({
    required FirebaseAuth auth,
    required PreferencesRepo prefsRepo,
    required OrgRepo orgRepo,
    required AnalyticsService analyticsService,
  }) : _auth = auth,
       _prefsRepo = prefsRepo,
       _orgRepo = orgRepo,
       _analyticsService = analyticsService {
    _isLoggedIn = _auth.currentUser != null;
    _authSubscription = _auth.authStateChanges().listen((user) {
      _isLoggedIn = user != null;
      notifyListeners();
    });
  }

  late final StreamSubscription _authSubscription;
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  Stream<List<Organization>> get ownedOrgsStream =>
      _isLoggedIn ? _orgRepo.getOrgsForCurrentUser() : const Stream.empty();
  Stream<List<Organization>> get otherOrgsStream =>
      _orgRepo.getOrgs(excludeOwned: _isLoggedIn);

  final StreamController<NavigationEvent> _navigationController =
      StreamController();
  Stream<NavigationEvent> get navigationEvents => _navigationController.stream;

  bool _isRedirecting = false;

  void init() {
    _analyticsService.logEvent(
      name: 'screen_view',
      parameters: {'screen_name': 'Landing'},
    );
    _handleInitialNavigation();
  }

  void _handleInitialNavigation() {
    _redirectIfNecessary(_prefsRepo);
  }

  void _redirectIfNecessary(PreferencesRepo prefsRepo) {
    final orgId = prefsRepo.lastOpenedOrgId;
    if (orgId != null) {
      _isRedirecting = true;
      _navigationController.add(
        NavigationEvent(ViewBookingsRoute(orgID: orgId), replace: true),
      );
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> onOrgTapped(String orgId, String viewName) async {
    _prefsRepo.setLastOpenedOrgId(orgId);
    _navigationController.add(
      NavigationEvent(
        ViewBookingsRoute(orgID: orgId, view: viewName),
        replace: true,
      ),
    );
  }

  Future<void> createOrg(String name, String roomName) async {
    await _orgRepo.addOrgForCurrentUser(name, roomName);
  }

  void navigateToLogin() {
    _navigationController.add(NavigationEvent(LoginRoute()));
  }

  bool get shouldShowRedirecting => _isRedirecting;

  @override
  void dispose() {
    _authSubscription.cancel();
    _navigationController.close();
    super.dispose();
  }
}
