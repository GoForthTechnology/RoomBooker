import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/date_field.dart';
import 'package:room_booker/widgets/room_field.dart';
import 'package:room_booker/widgets/room_selector.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';
import 'package:room_booker/widgets/time_field.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class RequestEditorState extends ChangeNotifier {
  Request? _existingRequest;

  bool _active = false;
  String _message = "";
  String? _eventName;
  String? _contactName;
  String? _contactEmail;
  String? _contactPhone;
  String? _room;
  DateTime? _startTime;
  DateTime? _endTime;

  RequestEditorState({required String initialRoom}) : _room = initialRoom;

  String? get room => _room;
  String? get eventname => _eventName;
  String? get contactName => _contactName;
  String? get contactEmail => _contactEmail;
  String? get contactPhone => _contactPhone;
  String? get message => _message;
  bool get active => _active;
  DateTime get startTime => _startTime!;
  DateTime get endTime => _endTime!;

  void showRequest(Request request, PrivateRequestDetails details) {
    _active = true;
    _existingRequest = request;
    _room = request.selectedRoom;
    _startTime = request.eventStartTime;
    _endTime = request.eventEndTime;
    _contactEmail = details.email;
    _contactName = details.name;
    _contactPhone = details.phone;
    _eventName = details.eventName;
    _message = details.message;
    notifyListeners();
  }

  void updateStatus(RequestStatus status) {
    if (_existingRequest != null) {
      _existingRequest = _existingRequest!.copyWith(status: status);
      notifyListeners();
    }
  }

  bool readOnly() {
    return _existingRequest != null;
  }

  void showPanel(DateTime startTime, DateTime endTime) {
    _active = true;
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }

  void clearAppointment() {
    _active = false;
    _eventName = null;
    _startTime = null;
    _endTime = null;
    _contactEmail = null;
    _contactPhone = null;
    _contactName = null;
    _eventName = null;
    _message = "";
    notifyListeners();
  }

  void updateRoom(String? room) {
    _room = room;
    notifyListeners();
  }

  void updateEventName(String name) {
    _eventName = name;
    notifyListeners();
  }

  void updateContactName(String name) {
    _contactName = name;
    notifyListeners();
  }

  void updateContactEmail(String email) {
    _contactEmail = email;
    notifyListeners();
  }

  void updateContactPhone(String phone) {
    _contactPhone = phone;
    notifyListeners();
  }

  void updateMessage(String message) {
    _message = message;
    notifyListeners();
  }

  void updateTimes(DateTime startTime, DateTime endTime) {
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }

  void updateStartTime(TimeOfDay time) {
    _startTime = DateTime(_startTime!.year, _startTime!.month, _startTime!.day,
        time.hour, time.minute);
    notifyListeners();
  }

  Request? getRequest() {
    if (_startTime == null || _endTime == null || _room == null) {
      return null;
    }
    return Request(
      id: _existingRequest?.id,
      eventStartTime: _startTime!,
      eventEndTime: _endTime!,
      selectedRoom: _room!,
      status: _existingRequest?.status ?? RequestStatus.pending,
    );
  }

  PrivateRequestDetails getPrivateDetails() {
    return PrivateRequestDetails(
      name: _contactName!,
      email: _contactEmail!,
      phone: _contactPhone!,
      eventName: _eventName!,
      message: _message,
    );
  }

  Appointment? getAppointment(Color color) {
    if (_existingRequest != null || _startTime == null || _endTime == null) {
      return null;
    }
    return Appointment(
      subject: _eventName ?? "New Request",
      startTime: _startTime!,
      endTime: _endTime!,
      color: color,
    );
  }
}

class RequestStateProvider extends StatelessWidget {
  final String orgID;
  final Widget child;

  const RequestStateProvider(
      {super.key, required this.child, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return RoomStateProvider(
        orgID: orgID,
        child: Consumer<RoomState>(
            builder: (context, roomState, child) =>
                ChangeNotifierProvider.value(
                  value: RequestEditorState(
                      initialRoom: roomState.enabledValues().first),
                  child: this.child,
                )));
  }
}

class NewRequestPanel extends StatefulWidget {
  final String orgID;

  const NewRequestPanel({super.key, required this.orgID});

  @override
  State<StatefulWidget> createState() => NewRequestPanelState();
}

class NewRequestPanelState extends State<NewRequestPanel> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final eventNameController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactEmailController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer2<RequestEditorState, OrgRepo>(
        builder: (context, state, repo, child) {
      eventNameController.text = state.eventname ?? "";
      var formContents = Column(
        children: [
          AppBar(
            title: const Text("New Request"),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  state.clearAppointment();
                },
              )
            ],
            automaticallyImplyLeading: false,
          ),
          RoomField(
            readOnly: state.readOnly(),
            orgID: widget.orgID,
            initialValue: state.room!,
            onChanged: state.updateRoom,
          ),
          SimpleTextFormField(
              readOnly: state.readOnly(),
              controller: eventNameController,
              labelText: "Event Name",
              validationMessage: "Please provide a name",
              onChanged: state.updateEventName),
          DateField(
            readOnly: state.readOnly(),
            labelText: 'Event Date',
            validationMessage: 'Please select a date',
            initialValue: state.startTime,
            onChanged: (newDate) {
              state.updateTimes(
                  DateTime(newDate.year, newDate.month, newDate.day,
                      state.startTime.hour, state.startTime.minute),
                  DateTime(newDate.year, newDate.month, newDate.day,
                      state.endTime.hour, state.endTime.minute));
            },
          ),
          TimeField(
              readOnly: state.readOnly(),
              labelText: 'Start Time',
              initialValue: TimeOfDay.fromDateTime(state.startTime),
              onChanged: (newTime) {
                var eventDuration = state.endTime.difference(state.startTime);
                var newStartTime = DateTime(
                    state.startTime.year,
                    state.startTime.month,
                    state.startTime.day,
                    newTime.hour,
                    newTime.minute);
                state.updateTimes(
                    newStartTime, newStartTime.add(eventDuration));
              }),
          TimeField(
              readOnly: state.readOnly(),
              labelText: 'End Time',
              initialValue: TimeOfDay.fromDateTime(state.endTime),
              onChanged: (newTime) {}),
          const Divider(),
          SimpleTextFormField(
            readOnly: state.readOnly(),
            controller: contactNameController,
            labelText: "Your Name",
            validationMessage: "Please provide your name",
            onChanged: state.updateContactName,
          ),
          SimpleTextFormField(
            readOnly: state.readOnly(),
            controller: contactEmailController,
            labelText: "Your Email",
            validationMessage: "Please provide your email",
            onChanged: state.updateContactEmail,
          ),
          SimpleTextFormField(
            readOnly: state.readOnly(),
            controller: contactPhoneController,
            labelText: "Your Phone Number",
            validationMessage: "Please provide your phone number",
            onChanged: state.updateContactPhone,
          ),
          const Divider(),
          SimpleTextFormField(
            readOnly: state.readOnly(),
            controller: messageController,
            labelText: "Additional Info",
            onChanged: state.updateMessage,
          ),
          getButton(state, repo),
        ],
      );
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Form(key: _formKey, child: formContents),
      );
    });
  }

  Widget getButton(RequestEditorState state, OrgRepo repo) {
    var request = state.getRequest()!;
    if (state.readOnly()) {
      if (request.status == RequestStatus.pending) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await repo.denyRequest(widget.orgID, request.id!);
                state.updateStatus(RequestStatus.denied);
              },
              child: const Text("Deny"),
            ),
            ElevatedButton(
              onPressed: () async {
                await repo.confirmRequest(widget.orgID, state.getRequest()!);
                state.updateStatus(RequestStatus.confirmed);
              },
              child: const Text("Approve"),
            ),
          ],
        );
      }
      return ElevatedButton(
        onPressed: () async {
          await repo.revisitBookingRequest(widget.orgID, request.id!);
          state.updateStatus(RequestStatus.pending);
        },
        child: const Text("Revisit"),
      );
    }
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          await repo.addBookingRequest(
              widget.orgID, request, state.getPrivateDetails());
          state.clearAppointment();
        }
      },
      child: const Text("Submit"),
    );
  }
}
