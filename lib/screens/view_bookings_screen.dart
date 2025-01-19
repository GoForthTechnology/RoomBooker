import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/widgets/current_bookings_calendar.dart';
import 'package:room_booker/widgets/request_editor_panel.dart';
import 'package:room_booker/widgets/room_selector.dart';

@RoutePage()
class ViewBookingsScreen extends StatelessWidget {
  final String orgID;

  const ViewBookingsScreen(
      {super.key, @PathParam('orgID') required this.orgID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: const Text("Room Bookings for Church of the Resurrection"),
            actions: _actions(context)),
        body: RequestStateProvider(
          orgID: orgID,
          child: Consumer<RequestPanelSate>(
            builder: (context, requestPanelState, child) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: Column(
                    children: [
                      const RoomSelector(),
                      Expanded(child: _buildCalendar(context)),
                    ],
                  ),
                ),
                if (requestPanelState.active)
                  Flexible(
                    flex: 1,
                    child: SingleChildScrollView(
                        child: NewRequestPanel(
                      orgID: orgID,
                    )),
                  )
              ],
            ),
          ),
        ));
  }

  Widget _buildCalendar(BuildContext context) {
    var requestEditorState =
        Provider.of<RequestEditorState>(context, listen: false);
    var requestPanelState =
        Provider.of<RequestPanelSate>(context, listen: false);
    return CurrentBookingsCalendar(
      orgID: orgID,
      onTap: (details) {
        requestPanelState.showPanel();
        requestEditorState.createRequest(
            details.date!, details.date!.add(const Duration(hours: 1)));
      },
      onTapRequest: (request) async {
        if (FirebaseAuth.instance.currentUser == null) {
          return;
        }
        var details = await Provider.of<OrgRepo>(context, listen: false)
            .getRequestDetails(orgID, request.id!)
            .first;
        if (details == null) {
          return;
        }
        requestPanelState.showPanel();
        requestEditorState.showRequest(request, details);
      },
    );
  }

  List<Widget> _actions(BuildContext context) {
    if (FirebaseAuth.instance.currentUser != null) {
      return [
        Tooltip(
          message: "Review Bookings",
          child: IconButton(
            icon: const Icon(Icons.approval_rounded),
            onPressed: () =>
                AutoRouter.of(context).push(ReviewBookingsRoute(orgID: orgID)),
          ),
        ),
        Tooltip(
          message: "Logout",
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              var router = AutoRouter.of(context);
              await FirebaseAuth.instance.signOut();
              router.replace(ViewBookingsRoute(orgID: orgID));
            },
          ),
        ),
      ];
    }
    return [
      Tooltip(
        message: "Login",
        child: IconButton(
          icon: const Icon(Icons.login),
          onPressed: () =>
              AutoRouter.of(context).push(LoginRoute(orgID: orgID)),
        ),
      )
    ];
  }
}
