import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/entities/booking_amendment.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_portal/ui/widgets/booking_list/amendment_diff_widget.dart';
import 'package:rxdart/rxdart.dart';

class PendingAmendments extends StatelessWidget {
  final BookingService service;
  final String orgID;

  const PendingAmendments({
    super.key,
    required this.orgID,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final bookingService =
        Provider.of<BookingService>(context, listen: false);

    return StreamBuilder<List<(Request, BookingAmendment)>>(
      stream: _amendmentStream(bookingService),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error loading amendments: ${snapshot.error}');
        }
        final pairs = snapshot.data ?? [];
        if (pairs.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pairs.length,
          itemBuilder: (context, index) {
            final (request, amendment) = pairs[index];
            return _AmendmentTile(
              orgID: orgID,
              request: request,
              amendment: amendment,
              bookingService: bookingService,
            );
          },
        );
      },
    );
  }

  Stream<List<(Request, BookingAmendment)>> _amendmentStream(
    BookingService bookingService,
  ) {
    return bookingService
        .listPendingAmendments(orgID)
        .switchMap((requests) {
          if (requests.isEmpty) {
            return Stream.value(<(Request, BookingAmendment)>[]);
          }
          final streams = requests.map((r) {
            return bookingService
                .getAmendment(orgID, r.id!)
                .map((a) => a == null ? null : (r, a));
          });
          return Rx.combineLatestList(streams).map(
            (list) => list.nonNulls.toList(),
          );
        });
  }
}

class _AmendmentTile extends StatelessWidget {
  final String orgID;
  final Request request;
  final BookingAmendment amendment;
  final BookingService bookingService;

  const _AmendmentTile({
    required this.orgID,
    required this.request,
    required this.amendment,
    required this.bookingService,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy h:mm a');
    final subtitle =
        '${request.roomName} — ${fmt.format(request.eventStartTime)}';

    return Card(
      color: Colors.amber.shade50,
      child: ListTile(
        leading: const Icon(Icons.edit_note, color: Colors.amber),
        title: Row(
          children: [
            Expanded(
              child: Text(
                amendment.proposedDetails.eventName.isNotEmpty
                    ? amendment.proposedDetails.eventName
                    : request.publicName ?? '(no title)',
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Edit Proposal',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '$subtitle\nProposed by ${amendment.proposedDetails.name}',
        ),
        isThreeLine: true,
        onTap: () => showAmendmentDiffDialog(
          context: context,
          orgID: orgID,
          currentRequest: request,
          amendment: amendment,
          bookingService: bookingService,
        ),
      ),
    );
  }
}
