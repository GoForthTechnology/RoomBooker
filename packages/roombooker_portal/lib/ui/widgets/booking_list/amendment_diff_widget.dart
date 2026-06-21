import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:roombooker_core/data/entities/booking_amendment.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/services/booking_service.dart';

class AmendmentDiffWidget extends StatelessWidget {
  final String orgID;
  final Request currentRequest;
  final BookingAmendment amendment;
  final BookingService bookingService;

  const AmendmentDiffWidget({
    super.key,
    required this.orgID,
    required this.currentRequest,
    required this.amendment,
    required this.bookingService,
  });

  @override
  Widget build(BuildContext context) {
    final proposed = amendment.proposedRequest;
    final proposedDetails = amendment.proposedDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Proposed by',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text('${proposedDetails.name} — ${proposedDetails.email}'),
        Text(proposedDetails.phone),
        if (amendment.scope == AmendmentScope.thisAndFuture)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Scope: This and future events',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        if (amendment.scope == AmendmentScope.thisInstance)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Scope: This event only',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Proposed Changes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(100),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
          },
          border: TableBorder.all(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
          children: [
            _headerRow(),
            ..._diffRows(currentRequest, proposed),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'If you did not request this change, reject it and contact '
            'the original booker to verify.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () async {
                await bookingService.rejectAmendment(
                  orgID,
                  currentRequest.id!,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Reject'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                await bookingService.applyAmendment(
                  orgID,
                  currentRequest,
                  amendment,
                );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Apply Amendment'),
            ),
          ],
        ),
      ],
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: Colors.grey.shade100),
      children: const [
        Padding(
          padding: EdgeInsets.all(6),
          child: Text('Field', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(6),
          child:
              Text('Current', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: EdgeInsets.all(6),
          child:
              Text('Proposed', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  List<TableRow> _diffRows(Request current, Request proposed) {
    final rows = <TableRow>[];
    final fmt = DateFormat('MMM d, yyyy h:mm a');

    void addRow(String field, String cur, String prop) {
      final changed = cur != prop;
      rows.add(
        TableRow(
          decoration: changed
              ? BoxDecoration(color: Colors.amber.shade50)
              : null,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(field),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                cur,
                style: changed
                    ? const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                prop,
                style: changed
                    ? const TextStyle(color: Colors.green)
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    addRow(
      'Start',
      fmt.format(current.eventStartTime),
      fmt.format(proposed.eventStartTime),
    );
    addRow(
      'End',
      fmt.format(current.eventEndTime),
      fmt.format(proposed.eventEndTime),
    );
    addRow('Room', current.roomName, proposed.roomName);
    addRow(
      'Public Name',
      current.publicName ?? '(none)',
      proposed.publicName ?? '(none)',
    );
    addRow(
      'Event Name',
      '(private)',
      amendment.proposedDetails.eventName,
    );
    addRow(
      'Meeting URL',
      '(private)',
      amendment.proposedDetails.meetingUrl ?? '(none)',
    );
    addRow(
      'Message',
      '(private)',
      amendment.proposedDetails.message,
    );

    return rows;
  }
}

Future<void> showAmendmentDiffDialog({
  required BuildContext context,
  required String orgID,
  required Request currentRequest,
  required BookingAmendment amendment,
  required BookingService bookingService,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Proposal'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: AmendmentDiffWidget(
            orgID: orgID,
            currentRequest: currentRequest,
            amendment: amendment,
            bookingService: bookingService,
          ),
        ),
      ),
    ),
  );
}
