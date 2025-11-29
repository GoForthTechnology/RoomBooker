import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/widgets/date_field.dart';
import 'package:room_booker/ui/widgets/edit_recurring_booking_dialog.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/repeat_bookings_selector.dart';
import 'package:room_booker/ui/widgets/room_dropdown_selector.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:room_booker/ui/widgets/simple_text_form_field.dart';
import 'package:room_booker/ui/widgets/time_field.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'logs_widget.dart';

class NewRequestPanel extends StatefulWidget {
  final String orgID;

  const NewRequestPanel({super.key, required this.orgID});

  @override
  State<StatefulWidget> createState() => NewRequestPanelState();
}

void closePanel(BuildContext context) {
  var panelState = Provider.of<RequestPanelSate>(context, listen: false);
  var requestState = Provider.of<RequestEditorState>(context, listen: false);
  var roomState = Provider.of<RoomState>(context, listen: false);

  requestState.clearAppointment();
  panelState.hidePanel(context);
  roomState.activateAll();
}

class NewRequestPanelState extends State<NewRequestPanel> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final eventNameController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactEmailController = TextEditingController();
  final contactPhoneController = TextEditingController();
  final messageController = TextEditingController();
  final idController = TextEditingController();

  void _updateControllers(RequestEditorState state) {
    eventNameController.text = state.eventname ?? "";
    contactNameController.text = state.contactName ?? "";
    contactEmailController.text = state.contactEmail ?? "";
    contactPhoneController.text = state.contactPhone ?? "";
    messageController.text = state.message ?? "";
    idController.text = state.requestID() ?? "";
  }

  @override
  Widget build(BuildContext context) {
    var editorState = Provider.of<RequestEditorState>(context, listen: false);
    _updateControllers(editorState);

    var orgState = Provider.of<OrgState>(context, listen: false);
    var localizations = MaterialLocalizations.of(context);
    var repo = Provider.of<BookingRepo>(context, listen: false);
    return Consumer3<RoomState, RequestEditorState, RequestPanelSate>(
      builder: (context, roomState, state, panelState, child) {
        var readOnly = state.readOnly();
        if (state.startTime == null) {
          // No idea why this is neccessary but without it there are a lot of NPEs
          // for the start and end time...
          return Container();
        }
        var formContents = Column(
          children: [
            AppBar(
              title: Text(state.pannelTitle()),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => closePanel(context),
                ),
              ],
              automaticallyImplyLeading: false,
            ),
            RoomDropdownSelector(
              readOnly: readOnly,
              orgID: widget.orgID,
              onChanged: (room) {
                if (room != null) {
                  state.updateRoomID(room.id!);
                }
              },
              initialRoomID: state._roomID,
            ),
            SimpleTextFormField(
              readOnly: readOnly,
              controller: eventNameController,
              labelText: "Event Name",
              validationMessage: "Please provide a name",
              onChanged: state.updateEventName,
            ),
            SwitchListTile(
              title: Text("Show name on parish calendar"),
              value: state.isPublicEvent,
              onChanged: readOnly ? null : state.updatePublicEvent,
            ),
            if (state.existingRequest?.ignoreOverlaps ?? false)
              SwitchListTile(
                title: Text("Ignore overlapping events"),
                value: state.isIgnoreOverlaps,
                onChanged: readOnly ? null : state.updateIgnoreOverlaps,
              ),
            DateField(
              readOnly: readOnly,
              labelText: 'Event Date',
              validationMessage: 'Please select a date',
              initialValue: state.startTime,
              onChanged: (newDate) {
                state.updateTimes(
                  DateTime(
                    newDate.year,
                    newDate.month,
                    newDate.day,
                    state.startTime!.hour,
                    state.startTime!.minute,
                  ),
                  DateTime(
                    newDate.year,
                    newDate.month,
                    newDate.day,
                    state.endTime!.hour,
                    state.endTime!.minute,
                  ),
                );
              },
            ),
            TimeField(
              readOnly: readOnly,
              labelText: 'Start Time',
              initialValue: TimeOfDay.fromDateTime(state.startTime!),
              localizations: localizations,
              maxTime: TimeOfDay.fromDateTime(state.endTime!),
              onChanged: (newTime) {
                var eventDuration = state.endTime!.difference(state.startTime!);
                var newStartTime = DateTime(
                  state.startTime!.year,
                  state.startTime!.month,
                  state.startTime!.day,
                  newTime.hour,
                  newTime.minute,
                );
                var newEndTime = newStartTime.add(eventDuration);
                state.updateTimes(newStartTime, newEndTime);
              },
            ),
            TimeField(
              readOnly: readOnly,
              labelText: 'End Time',
              minTime: TimeOfDay.fromDateTime(state.startTime!),
              initialValue: TimeOfDay.fromDateTime(state.endTime!),
              localizations: localizations,
              onChanged: (newTime) {
                var newEndTime = DateTime(
                  state.startTime!.year,
                  state.startTime!.month,
                  state.startTime!.day,
                  newTime.hour,
                  newTime.minute,
                );
                state.updateTimes(state.startTime!, newEndTime);
              },
            ),
            RepeatBookingsSelector(
              readOnly: readOnly,
              startTime: state.startTime!,
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
              onPatternChanged: (pattern, isCustom) {
                state.updateOffset(pattern.offset);
                state.updateInterval(pattern.period);
                state.updateFrequency(pattern.frequency, isCustom);
              },
              toggleDay: state.toggleWeekday,
              frequency: state.recurrancePattern.frequency,
            ),
            if (state.recurrancePattern.frequency != Frequency.never)
              DateField(
                initialValue: state.recurrancePattern.end,
                labelText: "End on or before",
                onChanged: (date) => state.updateEndDate(date),
                readOnly: readOnly,
                clearable: true,
              ),
            const Divider(),
            SimpleTextFormField(
              readOnly: readOnly,
              controller: contactNameController,
              labelText: "Your Name",
              validationMessage: "Please provide your name",
              onChanged: state.updateContactName,
            ),
            SimpleTextFormField(
              readOnly: readOnly,
              controller: contactEmailController,
              labelText: "Your Email",
              validationMessage: "Please provide your email",
              validationRegex: RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ),
              onChanged: state.updateContactEmail,
            ),
            SimpleTextFormField(
              readOnly: readOnly,
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
              readOnly: readOnly,
              controller: messageController,
              labelText: "Additional Info",
              onChanged: state.updateMessage,
            ),
            if (state.showID())
              SimpleTextFormField(
                controller: idController,
                readOnly: readOnly,
                labelText: "Request ID",
              ),
            if (state.showRequestLog())
              Consumer<OrgState>(
                builder: (context, orgState, child) => LogsWidget(
                  org: orgState.org,
                  requestID: state.requestID()!,
                  readOnly: readOnly,
                ),
              ),
            _getButtons(state, panelState, roomState, repo),
          ],
        );
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Form(key: _formKey, child: formContents),
          ),
        );
      },
    );
  }

  List<Widget> _buttonsForNewRequest(
    RequestEditorState state,
    RoomState roomState,
    BookingRepo repo,
    OrgState orgState,
  ) {
    if (orgState.currentUserIsAdmin()) {
      return [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              var request = state.getRequest(roomState)!;
              await repo.addBooking(
                widget.orgID,
                request,
                state.getPrivateDetails(),
              );
              if (context.mounted) {
                closePanel(context);
              } else {
                log("Context not mounted", error: Exception());
              }
              FirebaseAnalytics.instance.logEvent(
                name: "Booking Added",
                parameters: {"orgID": widget.orgID},
              );
            }
          },
          child: const Text("Add Booking"),
        ),
      ];
    }
    return [
      ElevatedButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            var request = state.getRequest(roomState)!;
            try {
              await repo.submitBookingRequest(
                widget.orgID,
                request,
                state.getPrivateDetails(),
              );
              if (context.mounted) {
                closePanel(context);
              } else {
                log("Context not mounted", error: Exception());
              }
              FirebaseAnalytics.instance.logEvent(
                name: "Request Submitted",
                parameters: {"orgID": widget.orgID},
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        },
        child: const Text("Submit Request"),
      ),
    ];
  }

  List<Widget> _buttonsForPendingRequest(
    RequestEditorState state,
    RequestPanelSate panelState,
    RoomState roomState,
    BookingRepo repo,
  ) {
    return [
      ElevatedButton(
        onPressed: () async {
          var request = state.getRequest(roomState)!;
          await repo.denyRequest(widget.orgID, request.id!);
          state.updateStatus(RequestStatus.denied);
          FirebaseAnalytics.instance.logEvent(
            name: "Booking Rejected",
            parameters: {"orgID": widget.orgID},
          );
        },
        child: const Text("Deny"),
      ),
      ElevatedButton(
        onPressed: () async {
          await repo.confirmRequest(
            widget.orgID,
            state.getRequest(roomState)!.id!,
          );
          state.updateStatus(RequestStatus.confirmed);
          FirebaseAnalytics.instance.logEvent(
            name: "Booking Approved",
            parameters: {"orgID": widget.orgID},
          );
        },
        child: const Text("Approve"),
      ),
    ];
  }

  List<Widget> _buttonsForConfirmedRequest(
    RequestEditorState state,
    RequestPanelSate panelState,
    RoomState roomState,
    BookingRepo repo,
  ) {
    var buttons = <Widget>[
      state.editingEnabled
          ? ElevatedButton(
              onPressed: () async {
                var messenger = ScaffoldMessenger.of(context);
                /*if (_formKey.currentState!.validate()) {
                  log("Invalid form, cannot save");
                  return;
                }*/
                try {
                  await repo.updateBooking(
                    widget.orgID,
                    state.existingRequest!,
                    state.getRequest(roomState)!,
                    state.getPrivateDetails(),
                    state.getStatus(),
                    () async => showDialog<RecurringBookingEditChoice>(
                      context: context,
                      builder: (context) => EditRecurringBookingDialog(),
                    ),
                  );
                  state.disableEditing();
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                } finally {
                  closePanel(context);
                }
              },
              child: Tooltip(
                message: "Save changes",
                child: const Text("Save"),
              ),
            )
          : ElevatedButton(
              onPressed: () {
                state.enableEditing();
              },
              child: Tooltip(
                message: "Edit the request",
                child: const Text("Edit"),
              ),
            ),
      ElevatedButton(
        onPressed: () async {
          var request = state.getRequest(roomState)!;
          await repo.revisitBookingRequest(widget.orgID, request);
          state.updateStatus(RequestStatus.pending);
        },
        child: Tooltip(
          message: "Reset request to pending",
          child: const Text("Revisit"),
        ),
      ),
      ElevatedButton(
        onPressed: _onDelete,
        child: Tooltip(
          message: "Delete the request",
          child: const Text("Delete"),
        ),
      ),
    ];
    if (state.recurrancePattern.frequency != Frequency.never &&
        state.recurrancePattern.end == null) {
      buttons.add(
        ElevatedButton(
          onPressed: () async {
            var request = state.getRequest(roomState);
            await repo.endBooking(widget.orgID, request!.id!, state.startTime!);
            state.updateEndDate(state.startTime);
            FirebaseAnalytics.instance.logEvent(
              name: "Series Cancelled",
              parameters: {"orgID": widget.orgID},
            );
          },
          child: const Text("End Series"),
        ),
      );
    }
    return buttons;
  }

  Widget _getButtons(
    RequestEditorState state,
    RequestPanelSate panelState,
    RoomState roomState,
    BookingRepo repo,
  ) {
    return Consumer<OrgState>(
      builder: (context, orgState, child) {
        var status = state.getStatus();
        List<Widget> buttons = [];
        if (state.isNewRequest()) {
          buttons = _buttonsForNewRequest(state, roomState, repo, orgState);
        } else {
          if (status == RequestStatus.pending) {
            buttons = _buttonsForPendingRequest(
              state,
              panelState,
              roomState,
              repo,
            );
          } else {
            buttons = _buttonsForConfirmedRequest(
              state,
              panelState,
              roomState,
              repo,
            );
          }
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: buttons,
        );
      },
    );
  }

  void _onDelete() async {
    var state = Provider.of<RequestEditorState>(context, listen: false);
    var repo = Provider.of<BookingRepo>(context, listen: false);
    var roomState = Provider.of<RoomState>(context, listen: false);

    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this request?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      var request = state.getRequest(roomState)!;
      await repo.deleteBooking(
        widget.orgID,
        request,
        () async => showDialog<RecurringBookingEditChoice>(
          context: context,
          builder: (context) => EditRecurringBookingDialog(),
        ),
      );
      state.clearAppointment();
      closePanel(context);
    }
  }
}

class RequestStateProvider extends StatelessWidget {
  final Organization org;
  final Widget Function(BuildContext context, Widget? child) builder;
  final bool enableAllRooms;
  final DateTime? requestStartTime;
  final Request? initialRequest;
  final PrivateRequestDetails? initialDetails;
  final bool isCurrentUserAdmin;

  RequestStateProvider({
    super.key,
    required this.builder,
    required OrgState orgState,
    required this.enableAllRooms,
    this.initialRequest,
    this.initialDetails,
    this.requestStartTime,
  }) : org = orgState.org,
       isCurrentUserAdmin = orgState.currentUserIsAdmin();

  @override
  Widget build(BuildContext context) {
    bool panelActive =
        (requestStartTime ?? initialRequest?.eventStartTime) != null;
    return RoomStateProvider(
      org: org,
      enableAllRooms: enableAllRooms,
      builder: (context, _) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: RequestPanelSate(panelActive, org.id!),
          ),
          ChangeNotifierProvider.value(
            value: RequestEditorState(
              startTime: requestStartTime,
              initialRequest: initialRequest,
              initialDetails: initialDetails,
              isCurrenetUserAdmin: isCurrentUserAdmin,
            ),
          ),
        ],
        builder: builder,
      ),
    );
  }
}

class RequestPanelSate extends ChangeNotifier {
  final String _orgID;
  bool _active;

  RequestPanelSate(this._active, this._orgID);

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

    SystemNavigator.routeInformationUpdated(uri: Uri(path: "/view/$_orgID"));
  }
}

class RequestEditorState extends ChangeNotifier {
  Request? _existingRequest;
  bool _editingEnabled = false;

  String _message = "";
  String? _eventName;
  String? _contactName;
  String? _contactEmail;
  String? _contactPhone;
  DateTime? _startTime;
  DateTime? _endTime;
  RecurrancePattern _recurrancePattern = RecurrancePattern.never();
  bool _customRecurrencePattern = false;
  String _roomID = "";
  bool _publicEvent = false;
  bool _ignoreOverlaps = false;
  final bool _isCurrenetUserAdmin;

  String? get roomID => _roomID;
  String? get eventname => _eventName;
  String? get contactName => _contactName;
  String? get contactEmail => _contactEmail;
  String? get contactPhone => _contactPhone;
  String? get message => _message;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  RecurrancePattern get recurrancePattern => _recurrancePattern;
  bool get isCustomRecurrencePattern => _customRecurrencePattern;
  bool get editingEnabled => _editingEnabled;
  bool get isPublicEvent => _publicEvent;
  bool get isIgnoreOverlaps => _ignoreOverlaps;

  Request? get existingRequest => _existingRequest;

  RequestEditorState({
    DateTime? startTime,
    Request? initialRequest,
    PrivateRequestDetails? initialDetails,
    required bool isCurrenetUserAdmin,
  }) : _isCurrenetUserAdmin = isCurrenetUserAdmin {
    if (startTime != null) {
      _startTime = roundToNearest15Minutes(startTime);
      _endTime = _startTime!.add(const Duration(hours: 1));
    }
    if (initialRequest != null && initialDetails != null) {
      showRequest(initialRequest, initialDetails, updateListeners: false);
    }
  }

  bool isNewRequest() {
    return _existingRequest == null;
  }

  void updatePublicEvent(bool value) {
    _publicEvent = value;
    notifyListeners();
  }

  void updateIgnoreOverlaps(bool value) {
    _ignoreOverlaps = value;
    notifyListeners();
  }

  void showRequest(
    Request request,
    PrivateRequestDetails details, {
    bool updateListeners = true,
  }) {
    _publicEvent = (request.publicName ?? "") != "";
    _ignoreOverlaps = request.ignoreOverlaps;
    _existingRequest = request;
    _startTime = request.eventStartTime;
    _endTime = request.eventEndTime;
    _recurrancePattern = request.recurrancePattern ?? RecurrancePattern.never();
    _contactEmail = details.email;
    _contactName = details.name;
    _contactPhone = details.phone;
    _eventName = request.publicName ?? details.eventName;
    _message = details.message;
    _roomID = request.roomID;

    if (updateListeners) notifyListeners();
  }

  void enableEditing() {
    if (_existingRequest == null) {
      log("Cannot enable editing for a new request");
      return;
    }
    _editingEnabled = true;
    notifyListeners();
  }

  void disableEditing() {
    _editingEnabled = false;
    notifyListeners();
  }

  String pannelTitle() {
    if (_existingRequest == null) {
      return "New Request";
    }
    if (_editingEnabled) {
      return "Edit Request";
    }
    return "Request Details";
  }

  bool showRequestLog() {
    return showID() && _isCurrenetUserAdmin;
  }

  bool showID() {
    return readOnly() && _existingRequest?.id != null;
  }

  String? requestID() {
    return _existingRequest?.id;
  }

  void updateRoomID(String roomID) {
    _roomID = roomID;
    notifyListeners();
  }

  void updateFrequency(Frequency frequency, bool isCustom) {
    _customRecurrencePattern = isCustom || frequency == Frequency.custom;
    var weekday = getWeekday(startTime!);
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

  void updateOffset(int? offset) {
    _recurrancePattern = _recurrancePattern.copyWith(offset: offset);
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
    return _existingRequest != null && !_editingEnabled;
  }

  void createRequest(DateTime startTime, DateTime endTime, Room room) {
    _startTime = startTime;
    _endTime = endTime;
    _roomID = room.id!;
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
    _startTime = roundToNearest15Minutes(startTime);
    _endTime = roundToNearest15Minutes(endTime);
    notifyListeners();
  }

  Request? getRequest(RoomState roomState) {
    var room = roomState.getRoom(_roomID);
    if (_startTime == null || _endTime == null || room == null) {
      return null;
    }
    return Request(
      id: _existingRequest?.id,
      publicName: _publicEvent ? _eventName : null,
      ignoreOverlaps: _ignoreOverlaps,
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
      name: _contactName ?? "",
      email: _contactEmail ?? "",
      phone: _contactPhone ?? "",
      eventName: _eventName ?? "",
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

DateTime roundToNearest15Minutes(DateTime time) {
  final int minute = time.minute;
  final int mod = minute % 15;
  int roundedMinute = mod < 8 ? minute - mod : minute + (15 - mod);
  int hour = time.hour;
  int day = time.day;
  int month = time.month;
  int year = time.year;

  // Handle overflow if roundedMinute == 60
  if (roundedMinute == 60) {
    roundedMinute = 0;
    hour += 1;
    if (hour == 24) {
      hour = 0;
      day += 1;
      // Handle month/year overflow
      if (day > DateTime(year, month + 1, 0).day) {
        day = 1;
        month += 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }
      }
    }
  }

  return DateTime(year, month, day, hour, roundedMinute);
}
