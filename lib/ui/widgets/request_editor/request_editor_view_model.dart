import 'package:flutter/cupertino.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/controller_extensions.dart';
import 'package:rxdart/rxdart.dart';

class EditorAction {
  final String title;
  final Future<String> Function() onPressed;

  EditorAction(this.title, this.onPressed);
}

class RequestEditorViewModel extends ChangeNotifier {
  final BookingRepo _bookingRepo;
  final AnalyticsService _analyticsService;
  final AuthService _authService;
  final formKey = GlobalKey<FormState>(); // Form key for validation

  final OrgState _orgState;
  final Request initialRequest;
  final PrivateRequestDetails? _initialDetails;

  final String editorTitle;
  final eventNameContoller = TextEditingController();
  final phoneNumberController = TextEditingController();
  final contactNameController = TextEditingController();
  final contactEmailController = TextEditingController();
  final additionalInfoController = TextEditingController();
  final idController = TextEditingController();
  final _eventStartSubject = BehaviorSubject<DateTime>();
  final _eventEndSubject = BehaviorSubject<DateTime>();
  final _roomSubject = BehaviorSubject<Room>();

  final _isPublicSubject = BehaviorSubject<bool>();
  final _ignoreOverlapsSubject = BehaviorSubject<bool>();

  final Future<RecurringBookingEditChoice?> Function() _choiceProvider;

  bool readOnly;

  RequestEditorViewModel(
    this.readOnly,
    this.editorTitle,
    this.initialRequest,
    AnalyticsService analyticsService,
    AuthService authService,
    BookingRepo bookingRepo,
    OrgState orgState,
    PrivateRequestDetails? initialDetails,
    Future<RecurringBookingEditChoice?> Function() choiceProvider,
  ) : _bookingRepo = bookingRepo,
      _analyticsService = analyticsService,
      _authService = authService,
      _orgState = orgState,
      _initialDetails = initialDetails,
      _choiceProvider = choiceProvider {
    contactNameController.text = initialDetails?.name ?? "";
    contactEmailController.text = initialDetails?.email ?? "";
    phoneNumberController.text = initialDetails?.phone ?? "";
    eventNameContoller.text = initialDetails?.eventName ?? "";
    additionalInfoController.text = initialDetails?.message ?? "";
    _eventStartSubject.add(initialRequest.eventStartTime);
    _eventEndSubject.add(initialRequest.eventEndTime);
    _isPublicSubject.add(initialRequest.publicName != null);
    _ignoreOverlapsSubject.add(initialRequest.ignoreOverlaps);
    idController.text = initialRequest.id ?? "";
  }

  void toggleEditing() {
    readOnly = !readOnly;
    notifyListeners();
  }

  String get orgID => _orgState.org.id!;

  Stream<DateTime> get eventStartStream => _eventStartSubject.stream;
  Stream<DateTime> get eventEndStream => _eventEndSubject.stream;
  Stream<Room> get roomStream => _roomSubject.stream;
  Stream<bool> get isPublicStream => _isPublicSubject.stream;
  Stream<bool> get ignoreOverlapsStream => _ignoreOverlapsSubject.stream;

  List<EditorAction> getActions() {
    if (initialRequest.id == null) {
      return _getActionsForNewRequest();
    } else if (initialRequest.status == RequestStatus.pending) {
      return _getActiosnForPendingRequest();
    } else if (initialRequest.status == RequestStatus.confirmed) {
      return _getActionsForConfirmedRequest();
    }
    return [];
  }

  List<EditorAction> _getActionsForNewRequest() {
    var actionTitle = _orgState.currentUserIsAdmin()
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
              "isAdmin": _orgState.currentUserIsAdmin(),
            },
          );
          var closeMessage = await closeEditor();
          if (closeMessage.isNotEmpty) {
            return "Could not close editor: $closeMessage";
          }
          return "Successfully added booking.";
        }
        return "Failed to add booking.";
      }),
    ];
  }

  List<EditorAction> _getActiosnForPendingRequest() {
    return [
      EditorAction("Approve", () async {
        var orgID = _orgState.org.id!;
        await _bookingRepo.confirmRequest(orgID, initialRequest.id!);
        _analyticsService.logEvent(
          name: "Booking Approved",
          parameters: {"orgID": orgID},
        );
        var closeMessage = await closeEditor();
        if (closeMessage.isNotEmpty) {
          return "Could not close editor: $closeMessage";
        }
        return "Booking approved.";
      }),
      EditorAction("Reject", () async {
        var orgID = _orgState.org.id!;
        await _bookingRepo.denyRequest(orgID, initialRequest.id!);
        _analyticsService.logEvent(
          name: "Booking Rejected",
          parameters: {"orgID": orgID},
        );
        var closeMessage = await closeEditor();
        if (closeMessage.isNotEmpty) {
          return "Could not close editor: $closeMessage";
        }
        return "Booking rejected.";
      }),
    ];
  }

  List<EditorAction> _getActionsForConfirmedRequest() {
    List<EditorAction> actions = [];
    if (readOnly) {
      actions.add(
        EditorAction("Edit", () async {
          toggleEditing();
          return "";
        }),
      );
    } else {
      actions.add(
        EditorAction("Save", () async {
          var request = await requestStream().first;
          var details = await detailsStream().first;

          await _bookingRepo.updateBooking(
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
          toggleEditing();
          return "Booking updated.";
        }),
      );
    }
    actions.add(
      EditorAction("Revisit", () async {
        await _bookingRepo.revisitBookingRequest(orgID, initialRequest);
        return "Booking request revisited.";
      }),
    );
    actions.add(
      EditorAction("Delete", () async {
        await _bookingRepo.deleteBooking(
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
          return "Could not close editor: $closeMessage";
        }
        return "Booking deleted.";
      }),
    );
    if ((initialRequest.recurrancePattern?.frequency ?? Frequency.never) !=
            Frequency.never &&
        initialRequest.recurrancePattern?.end != null) {
      actions.add(
        EditorAction("End", () async {
          var endDate = await eventStartStream.first;
          await _bookingRepo.endBooking(orgID, initialRequest.id!, endDate);
          _analyticsService.logEvent(
            name: "Recurring Booking Ended",
            parameters: {"orgID": orgID},
          );
          var closeMessage = await closeEditor();
          if (closeMessage.isNotEmpty) {
            return "Could not close editor: $closeMessage";
          }
          return "Recurring booking ended.";
        }),
      );
    }
    return actions;
  }

  Future<String> closeEditor() async {
    var request = await requestStream().first;
    var details = await detailsStream().first;

    if (request != initialRequest || details != _initialDetails) {
      return "Unsaved changes will be lost. Are you sure you want to close?";
    }
    // All good, no changes.
    return "";
  }

  Future<bool> submitRequest() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    final request = await requestStream().first;
    final details = await detailsStream().first;
    var orgID = _orgState.org.id!;
    if (_orgState.currentUserIsAdmin()) {
      await _bookingRepo.addBooking(orgID, request, details);
    } else {
      await _bookingRepo.submitBookingRequest(orgID, request, details);
    }
    return true;
  }

  Stream<Request> requestStream() {
    return Rx.combineLatest6(
      eventStartStream,
      eventEndStream,
      roomStream,
      isPublicStream,
      ignoreOverlapsStream,
      eventNameContoller.textStream,
      (
        DateTime start,
        DateTime end,
        room,
        isPublic,
        ignoreOverlaps,
        eventName,
      ) {
        return Request(
          eventStartTime: start,
          eventEndTime: end,
          roomID: room.id!,
          roomName: room.name,
          publicName: isPublic ? eventName : null,
          ignoreOverlaps: ignoreOverlaps,
        );
      },
    );
  }

  Stream<PrivateRequestDetails> detailsStream() {
    return Rx.combineLatest5(
      eventNameContoller.textStream.warnOnStall(3, "EventName"),
      contactNameController.textStream.warnOnStall(3, "ContactName"),
      contactEmailController.textStream.warnOnStall(3, "ContactEmail"),
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

  bool showIgnoreOverlapsToggle() {
    return initialRequest.id != null && _orgState.currentUserIsAdmin();
  }

  bool showEventLog() {
    return initialRequest.id != null && _orgState.currentUserIsAdmin();
  }

  bool showID() {
    return initialRequest.id != null;
  }

  void useAdminContactInfo() {
    final adminEmail = _authService.getCurrentUserEmail() ?? "";
    updateContactName("Org Admin");
    updateContactEmail(adminEmail);
    updateContactPhone("n/a");
  }

  void updateEventStart(DateTime newStart) {
    _eventStartSubject.add(newStart);
  }

  void updateEventEnd(DateTime newEnd) {
    _eventEndSubject.add(newEnd);
  }

  void updateRoom(Room newRoom) {
    _roomSubject.add(newRoom);
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
    _roomSubject.close();
    _isPublicSubject.close();
    super.dispose();
  }
}

extension _StreamDoOnErrorExtension<T> on Stream<T> {
  Stream<T> warnOnStall(int stallSeconds, String streamName) {
    return timeout(Duration(seconds: 3)).doOnError((error, stackTrace) {
      print("Stream $streamName stalled: $error, $stackTrace");
    });
  }
}
