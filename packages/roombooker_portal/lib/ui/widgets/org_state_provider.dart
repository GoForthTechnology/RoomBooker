import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/repos/org_repo.dart';
import 'package:roombooker_core/data/repos/user_repo.dart';
import 'package:roombooker_core/data/services/auth_service.dart';

class OrgState extends ChangeNotifier {
  final Organization org;
  // NOTE: This is just a hint that the user is an admin. It is not a guarantee.
  // The final check is done in the database.
  bool _currentUserIsAdmin;
  bool get currentUserIsAdmin => _currentUserIsAdmin;
  final AuthService authService;

  OrgState({
    required this.org,
    required bool currentUserIsAdmin,
    required this.authService,
  }) : _currentUserIsAdmin = currentUserIsAdmin;

  void updateAdminStatus(bool isAdmin) {
    if (_currentUserIsAdmin != isAdmin) {
      _currentUserIsAdmin = isAdmin;
      notifyListeners();
    }
  }
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
  OrgState? _resolvedState;
  StreamSubscription? _adminSub;
  bool _inviteCheckStarted = false;

  Future<bool> _currentUserIsAdmin(
    AuthService authService,
    UserRepo userRepo,
  ) async {
    var userID = authService.getCurrentUserID();
    if (userID == null) {
      return false;
    }
    var profile = await userRepo.getUser(userID);
    if (profile == null) {
      return false;
    }
    return profile.orgIDs.contains(widget.orgID);
  }

  String? _lastUserID;

  void _loadState() {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    var userRepo = Provider.of<UserRepo>(context, listen: false);
    var authService = Provider.of<AuthService>(context, listen: false);

    _resolvedState = null;
    _inviteCheckStarted = false;
    _future = () async {
      _statusController.add("Fetching organization details...");
      var org = await orgRepo.getOrg(widget.orgID).first;
      if (org == null) {
        _statusController.add("Organization not found.");
        return null;
      }

      _statusController.add("Checking admin permissions...");
      var isAdmin = await _currentUserIsAdmin(authService, userRepo);

      _statusController.add("Ready.");
      return OrgState(
        org: org,
        currentUserIsAdmin: isAdmin,
        authService: authService,
      );
    }();

    _subscribeToAdminStatus(orgRepo, authService);
  }

  void _subscribeToAdminStatus(OrgRepo orgRepo, AuthService authService) {
    _adminSub?.cancel();
    final uid = authService.getCurrentUserID();
    if (uid == null) return;
    _adminSub = orgRepo.activeAdmins(widget.orgID).listen((admins) {
      final isAdmin = admins.any((a) => a.id == uid);
      _resolvedState?.updateAdminStatus(isAdmin);
    });
  }

  Future<void> _maybeShowInviteDialog(OrgState orgState) async {
    final orgRepo = Provider.of<OrgRepo>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final hasInvite = await orgRepo.hasPendingInviteForOrg(widget.orgID);
    if (!mounted || !hasInvite) return;

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Invitation'),
        content: Text(
          'You have been invited to become an administrator of '
          '"${orgState.org.name}". Would you like to accept?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Decline'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (accepted == true) {
      try {
        await orgRepo.claimInviteForOrg(widget.orgID);
        if (!mounted) return;
        _resolvedState?.updateAdminStatus(true);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'You are now an admin of "${orgState.org.name}".',
            ),
          ),
        );
      } catch (e) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to accept invitation. Please try again.'),
          ),
        );
      }
    }
  }

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();
    _lastUserID =
        Provider.of<AuthService>(context, listen: false).getCurrentUserID();
    _loadState();
  }

  @override
  void dispose() {
    _adminSub?.cancel();
    _statusController.close();
    super.dispose();
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
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  StreamBuilder<String>(
                    stream: _statusController.stream,
                    initialData: "Initializing...",
                    builder: (context, statusSnapshot) {
                      return Text(
                        statusSnapshot.data ?? "",
                        style: const TextStyle(color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          log('Error loading organization state', error: snapshot.error);
          return Center(
            child: Text('Error loading organization: ${snapshot.error}'),
          );
        }
        final data = snapshot.data;
        if (!snapshot.hasData || data == null) {
          return const Center(child: Text('Organization not found'));
        }
        _resolvedState = data;
        if (!data.currentUserIsAdmin && !_inviteCheckStarted) {
          _inviteCheckStarted = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybeShowInviteDialog(data);
          });
        }
        return ChangeNotifierProvider.value(
          value: data,
          child: widget.child,
        );
      },
    );
  }
}
