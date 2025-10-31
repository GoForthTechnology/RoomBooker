import 'dart:async';

import 'package:flutter/material.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';

class JoinOrgViewModel extends ChangeNotifier {
  final OrgRepo _orgRepo;
  final AnalyticsService _analyticsService;
  final String _orgID;

  JoinOrgViewModel({
    required OrgRepo orgRepo,
    required AnalyticsService analyticsService,
    required String orgID,
  })  : _orgRepo = orgRepo,
        _analyticsService = analyticsService,
        _orgID = orgID {
    _logScreenView();
    _initializeStream();
  }

  late final Stream<Organization?> orgStream;

  void _logScreenView() {
    _analyticsService.logScreenView(
        screenName: "Join Organization", parameters: {"orgID": _orgID});
  }

  void _initializeStream() {
    orgStream = _orgRepo.getOrg(_orgID).map((org) {
      if (org == null) {
        _analyticsService.logEvent(name: 'Org_Not_Found');
      } else if (org.acceptingAdminRequests) {
        _analyticsService.logEvent(name: 'Org_Accepting_Members');
      } else {
        _analyticsService.logEvent(name: 'Org_Not_Accepting_Members');
      }
      return org;
    }).handleError((error) {
      _analyticsService.logEvent(name: 'Org_Load_Error');
      // The stream will re-throw the error for the StreamBuilder
      throw error;
    });
  }

  Future<void> joinOrganization() async {
    await _orgRepo.addAdminRequestForCurrentUser(_orgID);
    _analyticsService.logEvent(name: 'Join_Request_Submitted');
  }
}
