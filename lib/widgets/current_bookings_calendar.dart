import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/entities/request.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/widgets/date_field.dart';
import 'package:room_booker/widgets/room_field.dart';
import 'package:room_booker/widgets/room_selector.dart';
import 'package:room_booker/widgets/simple_text_form_field.dart';
import 'package:room_booker/widgets/streaming_calendar.dart';
import 'package:room_booker/widgets/time_field.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CurrentBookingsCalendar extends StatelessWidget {
  final String orgID;

  const CurrentBookingsCalendar({super.key, required this.orgID});

  @override
  Widget build(BuildContext context) {
    return RoomStateProvider(
        orgID: orgID,
        child: RequestStateProvider(
          child: Consumer<NewRequestState>(
            builder: (context, newRequestState, child) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 3,
                  child: Column(
                    children: [
                      const RoomSelector(),
                      Expanded(
                          child: Calendar(
                        orgID: orgID,
                        onTap: (details) {
                          newRequestState.showPanel(details.date!,
                              details.date!.add(const Duration(hours: 1)));
                        },
                      )),
                    ],
                  ),
                ),
                if (newRequestState.active)
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
}

class RequestStateProvider extends StatelessWidget {
  final Widget child;

  const RequestStateProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomState>(
        builder: (context, roomState, child) => ChangeNotifierProvider.value(
              value:
                  NewRequestState(initialRoom: roomState.enabledValues().first),
              child: this.child,
            ));
  }
}

class NewRequestState extends ChangeNotifier {
  bool _active = false;
  String _message = "";
  String? _eventName;
  String? _contactName;
  String? _contactEmail;
  String? _contactPhone;
  String? _room;
  DateTime? _startTime;
  DateTime? _endTime;

  NewRequestState({required String initialRoom}) : _room = initialRoom;

  String? get room => _room;
  String? get eventname => _eventName;
  String? get contactName => _contactName;
  String? get contactEmail => _contactEmail;
  String? get contactPhone => _contactPhone;
  String? get message => _message;
  bool get active => _active;
  DateTime get startTime => _startTime!;
  DateTime get endTime => _endTime!;

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

  Request getRequest() {
    return Request(
      eventName: _eventName!,
      eventStartTime: _startTime!,
      eventEndTime: _endTime!,
      selectedRoom: _room!,
      name: _contactName!,
      email: _contactEmail!,
      phone: _contactPhone!,
      message: _message,
      status: RequestStatus.pending,
    );
  }

  Appointment? getAppointment(Color color) {
    if (_startTime == null || _endTime == null) {
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

class NewRequestPanel extends StatefulWidget {
  final String orgID;

  const NewRequestPanel({super.key, required this.orgID});

  @override
  State<StatefulWidget> createState() => NewRequestPanelState();
}

class NewRequestPanelState extends State<NewRequestPanel> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  var eventNameController = TextEditingController();
  var contactNameController = TextEditingController();
  var contactEmailController = TextEditingController();
  var contactPhoneController = TextEditingController();
  var messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer2<NewRequestState, OrgRepo>(
        builder: (context, state, repo, child) {
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
            orgID: widget.orgID,
            initialValue: state.room!,
            onChanged: state.updateRoom,
          ),
          SimpleTextFormField(
              controller: eventNameController,
              labelText: "Event Name",
              validationMessage: "Please provide a name",
              onChanged: state.updateEventName),
          DateField(
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
              labelText: 'End Time',
              initialValue: TimeOfDay.fromDateTime(state.endTime),
              onChanged: (newTime) {}),
          const Divider(),
          SimpleTextFormField(
            controller: contactNameController,
            labelText: "Your Name",
            validationMessage: "Please provide your name",
            onChanged: state.updateContactName,
          ),
          SimpleTextFormField(
            controller: contactEmailController,
            labelText: "Your Email",
            validationMessage: "Please provide your email",
            onChanged: state.updateContactEmail,
          ),
          SimpleTextFormField(
            controller: contactPhoneController,
            labelText: "Your Phone Number",
            validationMessage: "Please provide your phone number",
            onChanged: state.updateContactPhone,
          ),
          const Divider(),
          SimpleTextFormField(
            controller: messageController,
            labelText: "Additional Info",
            onChanged: state.updateMessage,
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                await repo.addBookingRequest(widget.orgID, state.getRequest());
                state.clearAppointment();
              }
            },
            child: const Text("Submit"),
          ),
        ],
      );
      return Padding(
        padding: const EdgeInsets.all(4),
        child: Form(key: _formKey, child: formContents),
      );
    });
  }
}

class Calendar extends StatelessWidget {
  final String orgID;
  final Function(CalendarTapDetails) onTap;

  const Calendar({super.key, required this.orgID, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer3<OrgRepo, RoomState, NewRequestState>(
        builder: (context, repo, roomState, newRequestState, child) =>
            StreamingCalendar(
              view: CalendarView.week,
              stateStream: Rx.combineLatest3(
                  repo.listBookings(orgID,
                      includeRooms: roomState.enabledValues()),
                  repo.listRequests(orgID,
                      includeStatuses: [RequestStatus.pending]),
                  repo.listBlackoutWindows(orgID),
                  (bookings, pendingRequests, blackoutWindows) {
                var appointments = bookings
                    .map((b) => Appointment(
                          subject: "Booked",
                          startTime: b.startTime,
                          endTime: b.endTime,
                          color: roomState.color(b.roomID),
                        ))
                    .toList();
                appointments.addAll(pendingRequests.map((r) => Appointment(
                      subject: "Requested",
                      startTime: r.eventStartTime,
                      endTime: r.eventEndTime,
                      color: roomState.color(r.selectedRoom).withAlpha(125),
                    )));
                var color =
                    roomState.color(newRequestState.room ?? "").withAlpha(200);
                var newAppointment = newRequestState.getAppointment(color);
                if (newAppointment != null) {
                  appointments.add(newAppointment);
                }
                return CalendarState(
                    appointments: appointments,
                    blackoutWindows: blackoutWindows);
              }),
              showNavigationArrow: true,
              showDatePickerButton: true,
              showTodayButton: true,
              onTap: onTap,
              allowAppointmentResize: true,
              onAppointmentResizeEnd: (details) => newRequestState.updateTimes(
                  details.startTime, details.endTime),
            ));
  }
}
