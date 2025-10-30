import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/screens/join_org_view.dart';
import 'package:room_booker/ui/screens/join_org_viewmodel.dart';

@RoutePage()
class JoinOrgScreen extends StatelessWidget {
  final String orgID;

  const JoinOrgScreen({super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => JoinOrgViewModel(
        orgRepo: context.read<OrgRepo>(),
        analyticsService: context.read<AnalyticsService>(),
        orgID: orgID,
      ),
      child: const JoinOrgScreenView(),
    );
  }
}

class JoinOrgScreenView extends StatelessWidget {
  const JoinOrgScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Organization'),
      ),
      body: Consumer<JoinOrgViewModel>(
        builder: (context, viewModel, child) {
          return StreamBuilder(
            stream: viewModel.orgStream,
            builder: (context, snapshot) {
              return JoinOrgView(
                snapshot: snapshot,
                onJoin: () async {
                  await viewModel.joinOrganization();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Request has been submitted')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
