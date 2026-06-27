import 'package:flutter/material.dart';
import 'package:roombooker_core/data/entities/booking_amendment.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_portal/ui/widgets/request_editor/date_field.dart';
import 'package:roombooker_portal/ui/widgets/request_editor/time_field.dart';
import 'package:roombooker_portal/ui/widgets/room_dropdown_selector.dart';

Future<void> showProposeAmendmentDialog({
  required BuildContext context,
  required String orgID,
  required Request request,
  required BookingService bookingService,
}) async {
  final isRecurring = request.isRepeating();
  AmendmentScope? scope;

  if (isRecurring) {
    scope = await showDialog<AmendmentScope>(
      context: context,
      builder: (context) => _ScopePicker(requestId: request.id ?? ''),
    );
    if (scope == null || !context.mounted) return;
  } else {
    scope = AmendmentScope.thisInstance;
  }

  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (context) => _AmendmentFormDialog(
      orgID: orgID,
      request: request,
      scope: scope!,
      bookingService: bookingService,
    ),
  );
}

class _ScopePicker extends StatelessWidget {
  final String requestId;

  const _ScopePicker({required this.requestId});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Which events to change?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('This event only'),
            onTap: () =>
                Navigator.of(context).pop(AmendmentScope.thisInstance),
          ),
          ListTile(
            title: const Text('This and future events'),
            onTap: () =>
                Navigator.of(context).pop(AmendmentScope.thisAndFuture),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _AmendmentFormDialog extends StatefulWidget {
  final String orgID;
  final Request request;
  final AmendmentScope scope;
  final BookingService bookingService;

  const _AmendmentFormDialog({
    required this.orgID,
    required this.request,
    required this.scope,
    required this.bookingService,
  });

  @override
  State<_AmendmentFormDialog> createState() => _AmendmentFormDialogState();
}

class _AmendmentFormDialogState extends State<_AmendmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  late DateTime _startDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _roomID;
  late String _roomName;
  bool _isPublic = false;

  final _publicNameCtrl = TextEditingController();
  final _eventNameCtrl = TextEditingController();
  final _contactNameCtrl = TextEditingController();
  final _contactEmailCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _meetingUrlCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final r = widget.request;
    _startDate = r.eventStartTime;
    _startTime = TimeOfDay.fromDateTime(r.eventStartTime);
    _endTime = TimeOfDay.fromDateTime(r.eventEndTime);
    _roomID = r.roomID;
    _roomName = r.roomName;
    _isPublic = r.publicName != null;
    _publicNameCtrl.text = r.publicName ?? '';
  }

  @override
  void dispose() {
    _publicNameCtrl.dispose();
    _eventNameCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactEmailCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _meetingUrlCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final start = _combine(_startDate, _startTime);
      final end = _combine(_startDate, _endTime);
      if (!end.isAfter(start)) {
        setState(() {
          _error = 'End time must be after start time.';
          _submitting = false;
        });
        return;
      }
      final proposedRequest = widget.request.copyWith(
        eventStartTime: start,
        eventEndTime: end,
        roomID: _roomID,
        roomName: _roomName,
        publicName: _isPublic ? _publicNameCtrl.text : null,
      );
      final proposedDetails = PrivateRequestDetails(
        eventName: _eventNameCtrl.text,
        name: _contactNameCtrl.text,
        email: _contactEmailCtrl.text,
        phone: _contactPhoneCtrl.text,
        meetingUrl: _meetingUrlCtrl.text.isNotEmpty
            ? _meetingUrlCtrl.text
            : null,
        message: _messageCtrl.text,
      );
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: widget.scope,
        proposedAt: DateTime.now(),
        instanceStartDate: widget.scope == AmendmentScope.thisInstance
            ? widget.request.recurrenceInstanceStartDate ??
                widget.request.eventStartTime
            : null,
      );
      await widget.bookingService.submitAmendment(
        widget.orgID,
        widget.request,
        amendment,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.sizeOf(context).width < 650;
    return isSmall ? _buildFullscreen(context) : _buildDialog(context);
  }

  Widget _buildFullscreen(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Propose a Change'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          ),
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _submitButton(compact: true),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildFormContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('Propose a Change'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: _buildFormContent(context),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        _submitButton(compact: false),
      ],
    );
  }

  Widget _submitButton({required bool compact}) {
    return FilledButton(
      onPressed: _submitting ? null : _submit,
      child: _submitting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(compact ? 'Submit' : 'Submit Proposal'),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Text(
            'Booking Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DateField(
            labelText: 'Date',
            initialValue: _startDate,
            readOnly: false,
            onChanged: (d) => setState(() => _startDate = d),
          ),
          const SizedBox(height: 8),
          TimeField(
            labelText: 'Start Time',
            initialValue: _startTime,
            readOnly: false,
            localizations: localizations,
            onChanged: (t) => setState(() => _startTime = t),
          ),
          const SizedBox(height: 8),
          TimeField(
            labelText: 'End Time',
            initialValue: _endTime,
            readOnly: false,
            localizations: localizations,
            onChanged: (t) => setState(() => _endTime = t),
          ),
          const SizedBox(height: 8),
          RoomDropdownSelector(
            orgID: widget.orgID,
            readOnly: false,
            initialRoomID: _roomID,
            onChanged: (room) {
              if (room != null) {
                setState(() {
                  _roomID = room.id!;
                  _roomName = room.name;
                });
              }
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Public Event Name'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_isPublic)
            TextFormField(
              controller: _publicNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Public Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Required' : null,
            ),
          const SizedBox(height: 16),
          const Text(
            'Event Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _eventNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Event Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _meetingUrlCtrl,
            decoration: const InputDecoration(
              labelText: 'Meeting URL (optional)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _messageCtrl,
            decoration: const InputDecoration(
              labelText: 'Additional Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your Contact Details',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Required so the admin can verify this request is from you.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactNameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactEmailCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _contactPhoneCtrl,
            decoration: const InputDecoration(
              labelText: 'Your Phone',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }
}
