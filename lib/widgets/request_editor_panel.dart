import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/organization.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/entities/series.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/date_field.dart';
import 'package:room_booker/widgets/org_state_provider.dart';
import 'package:room_booker/widgets/repeat_bookings_selector.dart';
import 'package:room_booker/widgets/room_field.dart';
import 'package:room_booker/widgets/room_selector.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';
import 'package:room_booker/widgets/time_field.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

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
    var editorState = Provider.of<RequestEditorState>(context, listen: false);
    eventNameController.text = editorState.eventname ?? "";
    contactNameController.text = editorState.contactName ?? "";
    contactEmailController.text = editorState.contactEmail ?? "";
    contactPhoneController.text = editorState.contactPhone ?? "";
    messageController.text = editorState.message ?? "";

    return Consumer4<RoomState, RequestEditorState, RequestPanelSate, OrgRepo>(
        builder: (context, roomState, state, panelState, repo, child) {
      var formContents = Column(
        children: [
          AppBar(
            title: const Text("New Request"),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  panelState.hidePanel();
                  state.clearAppointment();
                },
              )
            ],
            automaticallyImplyLeading: false,
          ),
          RoomField(
            readOnly: state.readOnly(),
            orgID: widget.orgID,
            initialRoomID: roomState.enabledValue().id!,
            onChanged: (value) {
              state.updateRoom(value);
              roomState.setActiveRoom(value);
            },
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
                var newEndTime = newStartTime.add(eventDuration);
                state.updateTimes(newStartTime, newEndTime);
              }),
          TimeField(
              readOnly: state.readOnly(),
              labelText: 'End Time',
              initialValue: TimeOfDay.fromDateTime(state.endTime),
              onChanged: (newTime) {
                var newEndTime = DateTime(
                    state.startTime.year,
                    state.startTime.month,
                    state.startTime.day,
                    newTime.hour,
                    newTime.minute);
                state.updateTimes(state.startTime, newEndTime);
              }),
          RepeatBookingsSelector(
            readOnly: state.readOnly(),
            startTime: state.startTime,
            isCustom: state.isCustomRecurrencePattern,
            onIntervalChanged: state.updateInterval,
            pattern: state.recurrancePattern,
            onFrequencyChanged: (value) {
              if (value == Frequency.custom) {
                state.updateFrequency(Frequency.weekly, true);
              } else {
                state.updateFrequency(value, state.isCustomRecurrencePattern);
              }
            },
            onPatternChanged: (pattern) {
              state.updateFrequency(pattern.frequency, true);
              state.updateInterval(pattern.period);
            },
            toggleDay: state.toggleWeekday,
            frequency: state.recurrancePattern.frequency,
          ),
          if (state.recurrancePattern.frequency != Frequency.never)
            DateField(
              initialValue: state.recurrancePattern.end,
              labelText: "End on or before",
              onChanged: (date) => state.updateEndDate(date),
              readOnly: state.readOnly(),
              clearable: true,
            ),
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
          _getButton(state, panelState, repo),
        ],
      );
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Form(key: _formKey, child: formContents),
      );
    });
  }

  Widget _getButton(
      RequestEditorState state, RequestPanelSate panelState, OrgRepo repo) {
    return Consumer<OrgState>(builder: (context, orgState, child) {
      var status = state.getStatus();
      if (state.readOnly()) {
        if (!orgState.currentUserIsAdmin()) {
          return Container();
        }
        if (status == RequestStatus.pending) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  var request = state.getRequest()!;
                  await repo.denyRequest(widget.orgID, request.id!);
                  state.updateStatus(RequestStatus.denied);
                },
                child: const Text("Deny"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await repo.confirmRequest(
                      widget.orgID, state.getRequest()!.id!);
                  state.updateStatus(RequestStatus.confirmed);
                },
                child: const Text("Approve"),
              ),
            ],
          );
        }
        return ElevatedButton(
          onPressed: () async {
            var request = state.getRequest()!;
            await repo.revisitBookingRequest(widget.orgID, request);
            state.updateStatus(RequestStatus.pending);
          },
          child: const Text("Revisit"),
        );
      }
      if (orgState.currentUserIsAdmin()) {
        return ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              var request = state.getRequest()!;
              await repo.addBooking(
                  widget.orgID, request, state.getPrivateDetails());
              state.clearAppointment();
              panelState.hidePanel();
            }
          },
          child: const Text("Add Booking"),
        );
      }
      return ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            var request = state.getRequest()!;
            await repo.submitBookingRequest(
                widget.orgID, request, state.getPrivateDetails());
            state.clearAppointment();
            panelState.hidePanel();
          }
        },
        child: const Text("Submit Request"),
      );
    });
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
        builder: (context, roomState) => ChangeNotifierProvider.value(
            value: RequestEditorState(initialRoom: roomState.enabledValue()),
            child: ChangeNotifierProvider.value(
                value: RequestPanelSate(),
                child: ChangeNotifierProvider.value(
                    value: roomState, child: child))));
  }
}

class RequestPanelSate extends ChangeNotifier {
  bool _active = false;

  bool get active => _active;

  void showPanel() {
    _active = true;
    notifyListeners();
  }

  void hidePanel() {
    _active = false;
    notifyListeners();
  }
}

class RequestEditorState extends ChangeNotifier {
  Request? _existingRequest;

  String _message = "";
  String? _eventName;
  String? _contactName;
  String? _contactEmail;
  String? _contactPhone;
  String? _roomID;
  String? _roomName;
  DateTime? _startTime;
  DateTime? _endTime;
  RecurrancePattern _recurrancePattern = RecurrancePattern.never();
  bool _customRecurrencePattern = false;

  RequestEditorState({required Room initialRoom})
      : _roomID = initialRoom.id,
        _roomName = initialRoom.name;

  String? get roomID => _roomID;
  String? get roomName => _roomName;
  String? get eventname => _eventName;
  String? get contactName => _contactName;
  String? get contactEmail => _contactEmail;
  String? get contactPhone => _contactPhone;
  String? get message => _message;
  DateTime get startTime => _startTime!;
  DateTime get endTime => _endTime!;
  RecurrancePattern get recurrancePattern => _recurrancePattern;
  bool get isCustomRecurrencePattern => _customRecurrencePattern;

  void showRequest(Request request, PrivateRequestDetails details) {
    _existingRequest = request;
    _roomID = request.roomID;
    _roomName = request.roomName;
    _startTime = request.eventStartTime;
    _endTime = request.eventEndTime;
    _contactEmail = details.email;
    _contactName = details.name;
    _contactPhone = details.phone;
    _eventName = details.eventName;
    _message = details.message;
    notifyListeners();
  }

  void updateFrequency(Frequency frequency, bool isCustom) {
    _customRecurrencePattern = isCustom || frequency == Frequency.custom;
    var weekday = getWeekday(startTime);
    _recurrancePattern =
        _recurrancePattern.copyWith(frequency: frequency, weekday: {weekday});
    notifyListeners();
  }

  void updateInterval(int interval) {
    _recurrancePattern = _recurrancePattern.copyWith(period: interval);
    notifyListeners();
  }

  void updateEndDate(DateTime? endDate) {
    _recurrancePattern = _recurrancePattern.copyWith(end: endDate);
    notifyListeners();
  }

  void toggleWeekday(Weekday weekday) {
    if (_recurrancePattern.weekday?.contains(weekday) ?? false) {
      _recurrancePattern.weekday?.remove(weekday);
    } else {
      _recurrancePattern.weekday?.add(weekday);
    }
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

  void createRequest(DateTime startTime, DateTime endTime) {
    _startTime = startTime;
    _endTime = endTime;
    notifyListeners();
  }

  void clearAppointment() {
    _existingRequest = null;
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

  void updateRoom(Room? room) {
    _roomName = room?.name;
    _roomID = room?.id;
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
    _startTime = roundToNearest30Minutes(startTime);
    _endTime = roundToNearest30Minutes(endTime);
    notifyListeners();
  }

  Request? getRequest() {
    if (_startTime == null || _endTime == null || _roomID == null) {
      return null;
    }
    return Request(
      id: _existingRequest?.id,
      eventStartTime: _startTime!,
      eventEndTime: _endTime!,
      roomID: _roomID!,
      roomName: _roomName!,
      status: _existingRequest?.status ?? RequestStatus.pending,
      recurrancePattern: _recurrancePattern,
    );
  }

  RequestStatus getStatus() {
    return _existingRequest?.status ?? RequestStatus.pending;
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

  Series? getSeries() {
    if (_recurrancePattern.frequency == Frequency.never) {
      return null;
    }
    var request = getRequest();
    if (request == null) {
      return null;
    }
    return Series(
      request: request,
      pattern: _recurrancePattern,
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

DateTime roundToNearest30Minutes(DateTime time) {
  final int minute = time.minute;
  final int mod = minute % 30;
  final int roundedMinute = mod < 15 ? minute - mod : minute + (30 - mod);
  return DateTime(time.year, time.month, time.day, time.hour, roundedMinute);
}
