import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:room_booker/data/services/analytics_service.dart';
import 'package:room_booker/data/services/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/controller_extensions.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:rxdart/rxdart.dart';

class ActionResult {
  final bool success;
  final String message;
  final bool shouldCloseEditor;

  ActionResult(this.success, this.message, this.shouldCloseEditor);
}

class EditorAction {
  final String title;
  final Future<ActionResult> Function() onPressed;

  EditorAction(this.title, this.onPressed);
}

class EditorViewState {
  final bool showIgnoreOverlapsToggle;
  final bool showEventLog;
  final bool showID;
  final bool readOnly;
  final List<EditorAction> actions;

  EditorViewState(
    this.readOnly, {
    required this.showIgnoreOverlapsToggle,
    required this.showEventLog,
    required this.showID,
    required this.actions,
  });
}

class RequestEditorViewModel extends ChangeNotifier {
  final Future<RecurringBookingEditChoice?> Function() _choiceProvider;
  final String editorTitle;

  final BookingService _bookingService;
  final OrgState _orgState;
  final RoomState _roomState;
  final AnalyticsService _analyticsService;
  final AuthService _authService;

  final _initialDataSubject =
      BehaviorSubject<(Request?, PrivateRequestDetails?)>.seeded((null, null));
  final _editingEnabledSubject = BehaviorSubject<bool>.seeded(false);

  final _currentDataSubject =
      BehaviorSubject<(Request?, PrivateRequestDetails?)>.seeded((null, null));

  final eventNameContoller = TextEditingController(text: "");
  final phoneNumberController = TextEditingController(text: "");
  final contactNameController = TextEditingController(text: "");
  final contactEmailController = TextEditingController(text: "");
  final additionalInfoController = TextEditingController(text: "");
  final idController = TextEditingController(text: "");
  final _eventStartSubject = BehaviorSubject<DateTime?>();
  final _eventEndSubject = BehaviorSubject<DateTime?>();
  final _roomNameSubject = BehaviorSubject<String>.seeded("");
  final _roomIDSubject = BehaviorSubject<String>.seeded("");
  final _isPublicSubject = BehaviorSubject<bool>.seeded(false);
  final _ignoreOverlapsSubject = BehaviorSubject<bool>.seeded(false);

  late RepeatBookingsViewModel repeatBookingsViewModel;

  final formKey = GlobalKey<FormState>(); // Form key for validation

  final _closeSubject = BehaviorSubject<void>();
  final _subscriptions = <StreamSubscription>[];
  StreamSubscription? _currentDataSubscription;

  RequestEditorViewModel({
    required this.editorTitle,
    required AnalyticsService analyticsService,
    required AuthService authService,
    required BookingService bookingService,
    required OrgState orgState,
    required RoomState roomState,
    required Future<RecurringBookingEditChoice?> Function() choiceProvider,
  }) : _bookingService = bookingService,
       _analyticsService = analyticsService,
       _authService = authService,
       _roomState = roomState,
       _orgState = orgState,
       _choiceProvider = choiceProvider {
    _subscriptions.add(_closeSubject.listen((_) => _clearSubjects()));

    // Initialize with default/empty state. It will be re-initialized in _initializeSubjects.
    repeatBookingsViewModel = RepeatBookingsViewModel(
      startTime: DateTime.now(),
      readOnly: true,
    );

    _subscriptions.add(
      _editingEnabledSubject.listen((enabled) {
        repeatBookingsViewModel.setReadOnly(!enabled);
      }),
    );

    _subscriptions.add(
      _eventStartSubject.listen((startTime) {
        if (startTime != null) {
          repeatBookingsViewModel.updateStartTime(startTime);
        }
      }),
    );
  }

  void _clearSubjects() {
    _currentDataSubject.add((null, null));
    _initialDataSubject.add((null, null));
    _eventStartSubject.add(null);
    _eventEndSubject.add(null);
    _roomIDSubject.add("");
    _roomNameSubject.add("");
    _isPublicSubject.add(false);
    _ignoreOverlapsSubject.add(false);

    eventNameContoller.text = "";
    contactNameController.text = "";
    contactEmailController.text = "";
    phoneNumberController.text = "";
    additionalInfoController.text = "";

    // Reset VM to clean state
    repeatBookingsViewModel.dispose();
    repeatBookingsViewModel = RepeatBookingsViewModel(
      startTime: DateTime.now(),
      readOnly: true,
    );
  }

  void _initializeSubjects(Request? request, PrivateRequestDetails? details) {
    _initialDataSubject.add((request, details));

    idController.text = request?.id ?? "";
    _eventStartSubject.add(request?.eventStartTime);
    _eventEndSubject.add(request?.eventEndTime);
    _ignoreOverlapsSubject.add(request?.ignoreOverlaps ?? false);
    _isPublicSubject.add(request?.publicName != null);
    _roomIDSubject.add(request?.roomID ?? "");
    _roomNameSubject.add(request?.roomName ?? "");

    eventNameContoller.text = details?.eventName ?? "";
    contactNameController.text = details?.name ?? "";
    contactEmailController.text = details?.email ?? "";
    phoneNumberController.text = details?.phone ?? "";
    additionalInfoController.text = details?.message ?? "";

    // Re-initialize repeat view model with request data
    // Dispose old one if needed? Actually, better to just update it or create new one and replace.
    // Since RepeatBookingsSelector takes the VM instance, we should probably keep the instance stable if possible,
    // or ensure the UI rebuilds with the new instance. The UI is built in build() method so new instance is fine.
    // BUT, if we replace the instance, the listeners in constructor need to be re-attached?
    // No, the listeners in constructor are on subjects which we don't replace.
    // But we need to listen to the VM? No, we just pass it to the UI.
    // Wait, _requestStream needs the pattern from the VM.

    // Let's recreate it to be safe and clean.
    repeatBookingsViewModel.dispose();
    repeatBookingsViewModel = RepeatBookingsViewModel(
      startTime: request?.eventStartTime ?? DateTime.now(),
      initialPattern: request?.recurrancePattern,
      readOnly: true, // Will be updated by _editingEnabledSubject
    );
    // Important: If we replace the instance, we must ensure any downstream listeners are aware.
    // The _requestStream uses repeatBookingsViewModel.patternStream.
    // If we replace the VM, we break the stream connection in _requestStream unless we rebuild that stream too.
    // _requestStream is called once in _initializeCurrentDataSubscription.
    // _initializeCurrentDataSubscription is called AFTER _initializeSubjects.
    // So replacing the VM here is fine for the NEW subscription.
  }

  Stream<(Request?, PrivateRequestDetails?)> currentDataStream() =>
      _currentDataSubject.stream;

  Stream<EditorViewState> get viewStateStream => Rx.combineLatest2(
    _initialDataSubject.stream,
    _editingEnabledSubject.stream,
    (data, editingEnabled) {
      final initialRequest = data.$1;
      List<EditorAction> actions = [];
      if (initialRequest != null) {
        actions.addAll(_getActions(initialRequest));
      }
      return EditorViewState(
        !editingEnabled,
        showIgnoreOverlapsToggle:
            initialRequest?.id != null && _orgState.currentUserIsAdmin,
        showEventLog:
            initialRequest?.id != null && _orgState.currentUserIsAdmin,
        showID: initialRequest?.id != null,
        actions: actions,
      );
    },
  );

  void _initializeCurrentDataSubscription() {
    if (_currentDataSubscription != null) {
      throw Exception("Current data subscription already initialized!");
    }
    _currentDataSubscription = Rx.combineLatest2(
      _requestStream(),
      _detailsStream(),
      (request, details) => (request, details),
    ).listen((data) => _currentDataSubject.add(data));
  }

  void _cancelCurrentDataSubscription() {
    _currentDataSubscription?.cancel();
    _currentDataSubscription = null;
  }

  void initializeNewRequest(DateTime targetDate) {
    if (_roomState.enabledValues().isEmpty) {
      throw Exception("No rooms available to create a new request.");
    }
    var defaultRoom = _roomState.enabledValues().first;
    Request initialRequest = Request(
      eventStartTime: targetDate,
      eventEndTime: targetDate.add(Duration(hours: 1)),
      ignoreOverlaps: false,
      roomID: defaultRoom.id!,
      roomName: defaultRoom.name,
    );
    _initializeSubjects(initialRequest, null);
    _editingEnabledSubject.add(true);
    _initializeCurrentDataSubscription();
  }

  void initializeFromExistingRequest(
    Request existingRequest,
    PrivateRequestDetails existingDetails,
  ) {
    _initializeSubjects(existingRequest, existingDetails);
    _initializeCurrentDataSubscription();
  }

  String get roomID => _roomIDSubject.value;

  String get orgID => _orgState.org.id!;

  Stream<DateTime?> get eventStartStream => _eventStartSubject.stream;
  Stream<DateTime?> get eventEndStream => _eventEndSubject.stream;
  Stream<String> get roomIDStream => _roomIDSubject.stream;
  Stream<String> get roomNameStream => _roomNameSubject.stream;
  Stream<bool> get isPublicStream => _isPublicSubject.stream;
  Stream<bool> get ignoreOverlapsStream => _ignoreOverlapsSubject.stream;

  Stream<(DateTime, DateTime)> get eventTimeStream => Rx.combineLatest2(
    eventStartStream.where((d) => d != null).cast<DateTime>(),
    eventEndStream.where((d) => d != null).cast<DateTime>(),
    (start, end) => (start, end),
  );

  List<EditorAction> _getActions(Request initialRequest) {
    if (initialRequest.id == null) {
      return _getActionsForNewRequest();
    } else if (initialRequest.status == RequestStatus.pending) {
      return _getActiosnForPendingRequest(initialRequest);
    } else if (initialRequest.status == RequestStatus.confirmed) {
      return _getActionsForConfirmedRequest(initialRequest);
    }
    throw Exception("Unknown request status! ${initialRequest.status}");
  }

  List<EditorAction> _getActionsForNewRequest() {
    var actionTitle = _orgState.currentUserIsAdmin
        ? "Add Booking"
        : "Submit Request";
    return [
      EditorAction(actionTitle, () async {
        final success = await submitRequest();
        if (success) {
          _analyticsService.logEvent(
            name: "Booking Added",
            parameters: {
              "orgID": orgID,
              "isAdmin": _orgState.currentUserIsAdmin.toString(),
            },
          );
          var closeMessage = await closeEditor();
          if (closeMessage.isNotEmpty) {
            return ActionResult(
              false,
              "Could not close editor: $closeMessage",
              false,
            );
          }
          return ActionResult(true, "Successfully added booking.", true);
        }
        return ActionResult(false, "Failed to add booking.", false);
      }),
    ];
  }

  List<EditorAction> _getActiosnForPendingRequest(Request initialRequest) {
    return [
      EditorAction("Approve", () async {
        var orgID = _orgState.org.id!;
        await _bookingService.confirmRequest(orgID, initialRequest.id!);
        _analyticsService.logEvent(
          name: "Booking Approved",
          parameters: {"orgID": orgID},
        );
        var closeMessage = await closeEditor();
        if (closeMessage.isNotEmpty) {
          return ActionResult(
            false,
            "Could not close editor: $closeMessage",
            false,
          );
        }
        return ActionResult(true, "Booking approved.", true);
      }),
      EditorAction("Reject", () async {
        var orgID = _orgState.org.id!;
        await _bookingService.denyRequest(orgID, initialRequest.id!);
        _analyticsService.logEvent(
          name: "Booking Rejected",
          parameters: {"orgID": orgID},
        );
        var closeMessage = await closeEditor();
        if (closeMessage.isNotEmpty) {
          return ActionResult(
            false,
            "Could not close editor: $closeMessage",
            false,
          );
        }
        return ActionResult(true, "Booking rejected.", true);
      }),
    ];
  }

  List<EditorAction> _getActionsForConfirmedRequest(Request initialRequest) {
    List<EditorAction> actions = [];
    if (_editingEnabledSubject.value == false) {
      actions.add(
        EditorAction("Edit", () async {
          _editingEnabledSubject.add(true);
          return ActionResult(true, "Editing enabled.", false);
        }),
      );
    } else {
      actions.add(
        EditorAction("Save", () async {
          var currentData = _currentDataSubject.value;
          Request? request = currentData.$1;
          PrivateRequestDetails? details = currentData.$2;
          if (request == null) {
            return ActionResult(false, "Invalid request data.", false);
          }
          if (details == null) {
            return ActionResult(false, "Invalid details data.", false);
          }

          await _bookingService.updateBooking(
            orgID,
            initialRequest,
            request,
            details,
            initialRequest.status ?? RequestStatus.pending,
            _choiceProvider,
          );
          _analyticsService.logEvent(
            name: "Booking Updated",
            parameters: {"orgID": orgID},
          );
          closeEditor();
          return ActionResult(true, "Booking updated.", true);
        }),
      );
    }
    actions.add(
      EditorAction("Revisit", () async {
        await _bookingService.revisitBookingRequest(orgID, initialRequest);
        return ActionResult(true, "Booking request revisited.", true);
      }),
    );
    actions.add(
      EditorAction("Delete", () async {
        await _bookingService.deleteBooking(
          orgID,
          initialRequest,
          _choiceProvider,
        );
        _analyticsService.logEvent(
          name: "Booking Deleted",
          parameters: {"orgID": orgID},
        );
        var closeMessage = await closeEditor();
        if (closeMessage.isNotEmpty) {
          return ActionResult(
            false,
            "Could not close editor: $closeMessage",
            false,
          );
        }
        return ActionResult(true, "Booking deleted.", true);
      }),
    );
    if ((initialRequest.recurrancePattern?.frequency ?? Frequency.never) !=
            Frequency.never &&
        initialRequest.recurrancePattern?.end != null) {
      actions.add(
        EditorAction("End", () async {
          var endDate = await eventStartStream.first;
          if (endDate == null) {
            return ActionResult(false, "No end date selected!", false);
          }
          await _bookingService.endBooking(orgID, initialRequest.id!, endDate);
          _analyticsService.logEvent(
            name: "Recurring Booking Ended",
            parameters: {"orgID": orgID},
          );
          var closeMessage = await closeEditor();
          if (closeMessage.isNotEmpty) {
            return ActionResult(
              false,
              "Could not close editor: $closeMessage",
              false,
            );
          }
          return ActionResult(true, "Recurring booking ended.", true);
        }),
      );
    }
    return actions;
  }

  Future<String> closeEditor() async {
    /*print("Closing editor, checking for unsaved changes...");
    var request = await requestStream().first;
    var details = await detailsStream().first;

    var (initialRequest, initialDetails) = _initialDataSubject.value;

    if (request != initialRequest || details != initialDetails) {
      return "Unsaved changes will be lost. Are you sure you want to close?";
    }*/
    // All good, no changes.
    _cancelCurrentDataSubscription();
    _closeSubject.add(null);
    _editingEnabledSubject.add(false);
    return "";
  }

  Future<bool> submitRequest() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    var currentData = _currentDataSubject.value;
    Request? request = currentData.$1;
    PrivateRequestDetails? details = currentData.$2;
    if (request == null || details == null) {
      return false;
    }

    var orgID = _orgState.org.id!;
    if (_orgState.currentUserIsAdmin) {
      await _bookingService.addBooking(orgID, request, details);
    } else {
      await _bookingService.submitBookingRequest(orgID, request, details);
    }
    return true;
  }

  Stream<Request?> get initialRequestStream =>
      _initialDataSubject.stream.map((data) => data.$1);

  Stream<Request?> _requestStream() {
    return Rx.combineLatest9(
      _initialDataSubject.stream.map((data) => data.$1),
      eventStartStream,
      eventEndStream,
      roomIDStream,
      roomNameStream,
      isPublicStream,
      ignoreOverlapsStream,
      eventNameContoller.textStream,
      repeatBookingsViewModel.patternStream,
      (
        Request? initialRequest,
        DateTime? start,
        DateTime? end,
        roomID,
        roomName,
        isPublic,
        ignoreOverlaps,
        eventName,
        pattern,
      ) {
        if (initialRequest == null) {
          return null;
        }
        if (start == null || end == null) {
          return null;
        }
        return Request(
          id: initialRequest.id,
          status: initialRequest.status,
          recurrancePattern: pattern,
          recurranceOverrides: initialRequest.recurranceOverrides,
          eventStartTime: start,
          eventEndTime: end,
          roomID: roomID,
          roomName: roomName,
          publicName: isPublic ? eventName : null,
          ignoreOverlaps: ignoreOverlaps,
        );
      },
    );
  }

  Stream<PrivateRequestDetails> _detailsStream() {
    return Rx.combineLatest5(
      eventNameContoller.textStream,
      contactNameController.textStream,
      contactEmailController.textStream,
      phoneNumberController.textStream,
      additionalInfoController.textStream,
      (eventName, name, email, phone, additionalInfo) {
        return PrivateRequestDetails(
          name: name,
          email: email,
          phone: phone,
          eventName: eventName,
          message: additionalInfo,
        );
      },
    );
  }

  void useAdminContactInfo() {
    final adminEmail = _authService.getCurrentUserEmail() ?? "";
    contactNameController.text = "Org Admin";
    contactEmailController.text = adminEmail;
    phoneNumberController.text = "n/a";
  }

  void updateEventStart(DateTime newStart) {
    _eventStartSubject.add(newStart);
  }

  void updateEventEnd(DateTime newEnd) {
    _eventEndSubject.add(newEnd);
  }

  void updateRoom(Room newRoom) {
    _roomIDSubject.add(newRoom.id!);
    _roomNameSubject.add(newRoom.name);
  }

  void updateIsPublic(bool isPublic) {
    _isPublicSubject.add(isPublic);
  }

  void updateIgnoreOverlaps(bool ignoreOverlaps) {
    _ignoreOverlapsSubject.add(ignoreOverlaps);
  }

  void updateEventName(String newName) {
    eventNameContoller.text = newName;
  }

  void updateContactName(String newName) {
    contactNameController.text = newName;
  }

  void updateContactEmail(String newEmail) {
    contactEmailController.text = newEmail;
  }

  void updateContactPhone(String newPhone) {
    phoneNumberController.text = newPhone;
  }

  void updateAdditionalInfo(String newInfo) {
    additionalInfoController.text = newInfo;
  }

  @override
  void dispose() {
    _eventStartSubject.close();
    _eventEndSubject.close();
    _roomIDSubject.close();
    _roomNameSubject.close();
    _isPublicSubject.close();
    _ignoreOverlapsSubject.close();
    _closeSubject.close();
    _initialDataSubject.close();
    _editingEnabledSubject.close();
    _currentDataSubject.close();
    repeatBookingsViewModel.dispose();
    for (var s in _subscriptions) {
      s.cancel();
    }
    _currentDataSubscription?.cancel();
    eventNameContoller.dispose();
    phoneNumberController.dispose();
    contactNameController.dispose();
    contactEmailController.dispose();
    additionalInfoController.dispose();
    idController.dispose();
    super.dispose();
  }
}
