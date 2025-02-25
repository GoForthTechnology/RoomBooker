import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/date_field.dart';
import 'package:room_booker/widgets/org_state_provider.dart';
import 'package:room_booker/widgets/repeat_bookings_selector.dart';
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

  void _updateControllers(RequestEditorState state) {
    eventNameController.text = state.eventname ?? "";
    contactNameController.text = state.contactName ?? "";
    contactEmailController.text = state.contactEmail ?? "";
    contactPhoneController.text = state.contactPhone ?? "";
    messageController.text = state.message ?? "";
  }

  @override
  Widget build(BuildContext context) {
    var editorState = Provider.of<RequestEditorState>(context, listen: false);
    _updateControllers(editorState);

    var orgState = Provider.of<OrgState>(context, listen: false);
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
                  panelState.hidePanel(context);
                  state.clearAppointment();
                },
              )
            ],
            automaticallyImplyLeading: false,
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
            validationRegex:
                RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
            onChanged: state.updateContactEmail,
          ),
          SimpleTextFormField(
            readOnly: state.readOnly(),
            controller: contactPhoneController,
            labelText: "Your Phone Number",
            validationMessage: "Please provide your phone number",
            onChanged: state.updateContactPhone,
          ),
          if (orgState.currentUserIsAdmin())
            ElevatedButton(
              onPressed: () {
                state.useAdminContactInfo();
                _updateControllers(state);
              },
              child: Text("Use My Info"),
            ),
          const Divider(),
          SimpleTextFormField(
            readOnly: state.readOnly(),
            controller: messageController,
            labelText: "Additional Info",
            onChanged: state.updateMessage,
          ),
          _getButton(state, panelState, roomState, repo),
        ],
      );
      return SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(4),
        child: Form(key: _formKey, child: formContents),
      ));
    });
  }

  Widget _getButton(RequestEditorState state, RequestPanelSate panelState,
      RoomState roomState, OrgRepo repo) {
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
                  var request = state.getRequest(roomState)!;
                  await repo.denyRequest(widget.orgID, request.id!);
                  state.updateStatus(RequestStatus.denied);
                  FirebaseAnalytics.instance.logEvent(
                      name: "Booking Rejected",
                      parameters: {"orgID": widget.orgID});
                },
                child: const Text("Deny"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await repo.confirmRequest(
                      widget.orgID, state.getRequest(roomState)!.id!);
                  state.updateStatus(RequestStatus.confirmed);
                  FirebaseAnalytics.instance.logEvent(
                      name: "Booking Approved",
                      parameters: {"orgID": widget.orgID});
                },
                child: const Text("Approve"),
              ),
            ],
          );
        }
        var buttons = <Widget>[
          ElevatedButton(
            onPressed: () async {
              var request = state.getRequest(roomState)!;
              await repo.revisitBookingRequest(widget.orgID, request);
              state.updateStatus(RequestStatus.pending);
            },
            child: const Text("Revisit"),
          )
        ];
        if (state.recurrancePattern.frequency != Frequency.never &&
            state.recurrancePattern.end == null) {
          buttons.add(ElevatedButton(
            onPressed: () async {
              var request = state.getRequest(roomState);
              await repo.endBooking(
                  widget.orgID, request!.id!, state.startTime);
              state.updateEndDate(state.startTime);
              FirebaseAnalytics.instance.logEvent(
                  name: "Series Cancelled",
                  parameters: {"orgID": widget.orgID});
            },
            child: const Text("End Series"),
          ));
        }
        return Row(children: buttons);
      }
      if (orgState.currentUserIsAdmin()) {
        return ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              var request = state.getRequest(roomState)!;
              await repo.addBooking(
                  widget.orgID, request, state.getPrivateDetails());
              state.clearAppointment();
              panelState.hidePanel(context);
              FirebaseAnalytics.instance.logEvent(
                  name: "Booking Added", parameters: {"orgID": widget.orgID});
            }
          },
          child: const Text("Add Booking"),
        );
      }
      return ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            var request = state.getRequest(roomState)!;
            await repo.submitBookingRequest(
                widget.orgID, request, state.getPrivateDetails());
            state.clearAppointment();
            panelState.hidePanel(context);
            FirebaseAnalytics.instance.logEvent(
                name: "Request Submitted", parameters: {"orgID": widget.orgID});
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
  final bool enableAllRooms;

  const RequestStateProvider(
      {super.key,
      required this.child,
      required this.orgID,
      required this.enableAllRooms});

  @override
  Widget build(BuildContext context) {
    return RoomStateProvider(
        orgID: orgID,
        enableAllRooms: enableAllRooms,
        builder: (context, roomState) => ChangeNotifierProvider.value(
            value: RequestEditorState(),
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

  void hidePanel(BuildContext context) {
    if (_active) {
      _active = false;
      notifyListeners();
    } else {
      Navigator.of(context).pop();
    }
  }
}

class RequestEditorState extends ChangeNotifier {
  Request? _existingRequest;

  String _message = "";
  String? _eventName;
  String? _contactName;
  String? _contactEmail;
  String? _contactPhone;
  DateTime? _startTime;
  DateTime? _endTime;
  RecurrancePattern _recurrancePattern = RecurrancePattern.never();
  bool _customRecurrencePattern = false;

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
    _startTime = request.eventStartTime;
    _endTime = request.eventEndTime;
    _recurrancePattern = request.recurrancePattern ?? RecurrancePattern.never();
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
    var interval = _recurrancePattern.period;
    if (frequency != Frequency.never && interval == 0) {
      interval = 1;
    }
    _recurrancePattern = _recurrancePattern.copyWith(
      frequency: frequency,
      weekday: {weekday},
      period: interval,
    );
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
    _recurrancePattern = RecurrancePattern.never();
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

  void useAdminContactInfo() {
    _contactEmail = FirebaseAuth.instance.currentUser!.email!;
    _contactName = "Org Admin";
    _contactPhone = "n/a";
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

  Request? getRequest(RoomState roomState) {
    var room = roomState.enabledValue();
    if (_startTime == null || _endTime == null || room == null) {
      return null;
    }
    return Request(
      id: _existingRequest?.id,
      eventStartTime: _startTime!,
      eventEndTime: _endTime!,
      roomID: room.id!,
      roomName: room.name,
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
