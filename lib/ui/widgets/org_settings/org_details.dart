import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:rxdart/rxdart.dart';

class OrgDetails extends ChangeNotifier {
  final int numPendingRequests;
  final int numConflictingRequests;
  final int numAdminRequests;

  OrgDetails(
      {required this.numPendingRequests,
      required this.numConflictingRequests,
      required this.numAdminRequests});
}

class OrgDetailsProvider extends StatelessWidget {
  final String orgID;
  final Function(BuildContext, OrgDetails?) builder;
  const OrgDetailsProvider(
      {super.key, required this.orgID, required this.builder});

  @override
  Widget build(BuildContext context) {
    var orgRepo = Provider.of<OrgRepo>(context, listen: false);
    var bookingRepo = Provider.of<BookingRepo>(context, listen: false);
    return StreamBuilder(
      stream: Rx.combineLatest3(
          bookingRepo.listRequests(
              orgID: orgID,
              startTime: DateTime.now(),
              endTime: DateTime.now().add(Duration(days: 365)),
              includeStatuses: {RequestStatus.pending}),
          orgRepo.adminRequests(orgID),
          bookingRepo.findOverlappingBookings(
              orgID, DateTime.now(), DateTime.now().add(Duration(days: 365))),
          (pendingRequests, adminRequests, overlaps) => OrgDetails(
              numPendingRequests: pendingRequests.length,
              numConflictingRequests: overlaps.length,
              numAdminRequests: adminRequests.length)),
      builder: (context, snapshot) {
        return builder(context, snapshot.data);
      },
    );
  }
}
