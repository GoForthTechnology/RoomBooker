import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roombooker_core/data/services/auth_service.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/repos/org_repo.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_core/data/repos/booking_repo.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_portal/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:roombooker_portal/ui/widgets/booking_calendar/view_model.dart';
import 'package:roombooker_core/data/repos/room_repo.dart';
import 'package:roombooker_portal/ui/widgets/org_state_provider.dart';
import 'package:roombooker_portal/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockBookingService extends Mock implements BookingService {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockAuthService extends Mock implements AuthService {}

class MockOrgState extends Mock implements OrgState {}

class MockStackRouter extends Mock implements StackRouter {}

class MockCalendarViewModel extends Mock implements CalendarViewModel {}

class MockRequestEditorViewModel extends Mock
    implements RequestEditorViewModel {}

class MockOrganization extends Mock implements Organization {}

class MockBuildContext extends Mock implements BuildContext {}

class FakeCalendarDataSource extends Fake implements CalendarDataSource {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

// Fakes
class FakeRequest extends Fake implements Request {}

class FakePrivateRequestDetails extends Fake implements PrivateRequestDetails {}

class FakeViewBookingsRoute extends Fake implements ViewBookingsRoute {}

void main() {
  late MockBookingService mockBookingService;
  late MockRoomRepo mockRoomRepo;
  late MockAuthService mockAuthService;
  late MockOrgState mockOrgState;
  late MockStackRouter mockStackRouter;
  late MockCalendarViewModel mockCalendarViewModel;
  late MockRequestEditorViewModel mockRequestEditorViewModel;
  late MockOrganization mockOrganization;
  late MockBuildContext mockContext;

  late StreamController<DateTapDetails> dateTapController;
  late StreamController<Request> requestTapController;
  late StreamController<Request?> initialRequestController;
  late StreamController<CalendarViewState> calendarViewStateController;
  late StreamController<DragDetails> dragEndController;
  late StreamController<ResizeDetails> resizeEndController;

  setUpAll(() {
    registerFallbackValue(Stream<(Request?, PrivateRequestDetails?)>.empty());
    registerFallbackValue(Request(
      eventStartTime: DateTime(2020),
      eventEndTime: DateTime(2020),
      roomID: 'fallback_room',
      roomName: 'fallback_room_name',
    ));
    registerFallbackValue(PrivateRequestDetails(
      eventName: '',
      name: '',
      email: '',
      phone: '',
    ));
    registerFallbackValue(FakeViewBookingsRoute());
    registerFallbackValue(
      ViewBookingsRoute(orgID: 'test', createRequest: false),
    );
    registerFallbackValue(Uri());
    registerFallbackValue(RequestStatus.pending);
    registerFallbackValue(() async => RecurringBookingEditChoice.thisInstance);
  });

  setUp(() {
    mockBookingService = MockBookingService();
    mockRoomRepo = MockRoomRepo();
    mockAuthService = MockAuthService();
    mockOrgState = MockOrgState();
    mockStackRouter = MockStackRouter();
    mockCalendarViewModel = MockCalendarViewModel();
    mockRequestEditorViewModel = MockRequestEditorViewModel();
    mockOrganization = MockOrganization();
    mockContext = MockBuildContext();

    dateTapController = StreamController<DateTapDetails>.broadcast();
    requestTapController = StreamController<Request>.broadcast();
    initialRequestController = StreamController<Request?>.broadcast();
    calendarViewStateController =
        StreamController<CalendarViewState>.broadcast();
    dragEndController = StreamController<DragDetails>.broadcast();
    resizeEndController = StreamController<ResizeDetails>.broadcast();

    when(
      () => mockCalendarViewModel.dateTapStream,
    ).thenAnswer((_) => dateTapController.stream);
    when(
      () => mockCalendarViewModel.requestTapStream,
    ).thenAnswer((_) => requestTapController.stream);
    when(
      () => mockCalendarViewModel.dragEndStream,
    ).thenAnswer((_) => dragEndController.stream);
    when(
      () => mockCalendarViewModel.resizeEndStream,
    ).thenAnswer((_) => resizeEndController.stream);
    when(
      () => mockRequestEditorViewModel.initialRequestStream,
    ).thenAnswer((_) => initialRequestController.stream);
    when(
      () => mockRequestEditorViewModel.currentDataStream(),
    ).thenAnswer((_) => const Stream.empty());
    when(
      () => mockCalendarViewModel.calendarViewState(),
    ).thenAnswer((_) => calendarViewStateController.stream);
    when(
      () => mockCalendarViewModel.registerNewAppointmentStream(any()),
    ).thenReturn(null);

    when(() => mockRequestEditorViewModel.isRescheduling).thenReturn(false);
    when(() => mockRequestEditorViewModel.choiceProvider).thenReturn(() async => null);

    when(() => mockOrgState.org).thenReturn(mockOrganization);
    when(() => mockOrganization.id).thenReturn('test_org_id');
  });

  ViewBookingsViewModel createViewModel({
    bool readOnlyMode = false,
    bool createRequest = false,
    bool showPrivateBookings = true,
    String? existingRequestID,
    Function(Request)? showRequestDialog,
    Function()? showEditorAsDialog,
    Function(String)? showSnackBar,
    Function(Uri)? updateUri,
    Size? size,
    Future<DateTime?> Function(DateTime, DateTime, DateTime)? pickDate,
    Future<TimeOfDay?> Function(DateTime)? pickTime,
  }) {
    return ViewBookingsViewModel(
      bookingService: mockBookingService,
      roomRepo: mockRoomRepo,
      authService: mockAuthService,
      orgState: mockOrgState,
      router: mockStackRouter,
      sizeProvider: () => size ?? const Size(1000, 800),
      calendarViewModel: mockCalendarViewModel,
      requestEditorViewModel: mockRequestEditorViewModel,
      existingRequestID: existingRequestID,
      showRoomSelector: true,
      createRequest: createRequest,
      readOnlyMode: readOnlyMode,
      showPrivateBookings: showPrivateBookings,
      showRequestDialog: showRequestDialog ?? (_) {},
      showEditorAsDialog: showEditorAsDialog ?? () {},
      showSnackBar: showSnackBar ?? (_) {},
      updateUri: updateUri ?? (_) {},
      pickDate:
          pickDate ?? (initial, first, last) async => DateTime(2023, 10, 27),
      pickTime:
          pickTime ?? (date) async => const TimeOfDay(hour: 10, minute: 0),
    );
  }

  CalendarViewState createViewState({
    DateTime? currentDate,
    CalendarView view = CalendarView.week,
  }) {
    return CalendarViewState(
      allowAppointmentResize: false,
      allowDragAndDrop: false,
      dataSource: FakeCalendarDataSource(),
      appointments: [],
      specialRegions: [],
      currentView: view,
      currentDate: currentDate ?? DateTime.now(),
    );
  }

  group('onTapBooking', () {
    final request = Request(
      id: 'req-1',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      roomID: 'room-1',
      roomName: 'Room 1',
    );
    final details = PrivateRequestDetails(
      eventName: 'Meeting',
      name: 'User',
      email: 'user@example.com',
      phone: '123',
    );

    test('readOnlyMode calls showRequestDialog', () async {
      var dialogCalled = false;
      createViewModel(
        createRequest: false,
        readOnlyMode: true,
        showRequestDialog: (r) {
          expect(r, request);
          dialogCalled = true;
        },
      );

      requestTapController.add(request);
      await Future.delayed(Duration.zero);

      expect(dialogCalled, true);
      verifyZeroInteractions(mockBookingService);
    });

    test('!readOnlyMode loads details and initializes editor', () async {
      createViewModel(createRequest: false, readOnlyMode: false);

      when(() => mockOrgState.currentUserIsAdmin).thenReturn(true);
      when(
        () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).thenAnswer((_) {});

      requestTapController.add(request);

      await untilCalled(
        () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
      );
      verify(
        () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
      ).called(1);

      await untilCalled(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      );
      verify(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).called(1);
    });

    test('!readOnlyMode small view shows editor as dialog', () async {
      var showEditorCalled = false;
      createViewModel(
        createRequest: false,
        readOnlyMode: false,
        size: const Size(500, 800), // Small width
        showEditorAsDialog: () => showEditorCalled = true,
      );

      when(() => mockOrgState.currentUserIsAdmin).thenReturn(true);

      when(
        () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).thenAnswer((_) {});

      requestTapController.add(request);
      await untilCalled(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      );

      expect(showEditorCalled, true);
    });

    test('!readOnlyMode but !isAdmin calls showRequestDialog', () async {
      var dialogCalled = false;
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);

      createViewModel(
        createRequest: false,
        readOnlyMode: false,
        showRequestDialog: (r) {
          expect(r, request);
          dialogCalled = true;
        },
      );

      requestTapController.add(request);
      await Future.delayed(Duration.zero);

      expect(dialogCalled, true);
      verifyZeroInteractions(mockBookingService);
    });
  });

  group('onTapDate', () {
    test('loadNewRequest is called when createRequest is true', () async {
      final viewModel = createViewModel(createRequest: true);
      expect(viewModel, isNotNull); // Use viewModel
      final targetDate = DateTime(2023, 10, 27);

      verify(
        () => mockCalendarViewModel.registerNewAppointmentStream(any()),
      ).called(1);

      when(
        () => mockRequestEditorViewModel.initializeNewRequest(targetDate),
      ).thenAnswer((_) async {});

      dateTapController.add(
        DateTapDetails(date: targetDate, view: CalendarView.day),
      );
      await Future.delayed(Duration.zero);

      verify(
        () => mockRequestEditorViewModel.initializeNewRequest(targetDate),
      ).called(1);
    });

    test('Month view triggers navigation to Day view', () async {
      createViewModel(createRequest: false);
      final targetDate = DateTime(2023, 10, 27);

      dateTapController.add(
        DateTapDetails(date: targetDate, view: CalendarView.month),
      );
      await Future.delayed(Duration.zero);

      verify(() => mockCalendarViewModel.focusDate(targetDate)).called(1);
      verifyNever(() => mockStackRouter.push(any()));
    });

    test('ReadOnlyMode ignores date taps', () async {
      createViewModel(createRequest: true, readOnlyMode: true);
      final targetDate = DateTime(2023, 10, 27);

      dateTapController.add(
        DateTapDetails(date: targetDate, view: CalendarView.day),
      );
      await Future.delayed(Duration.zero);

      verifyNever(() => mockRequestEditorViewModel.initializeNewRequest(any()));
    });
  });

  group('loadExistingRequest', () {
    final request = Request(
      id: 'req-1',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      roomID: 'room-1',
      roomName: 'Room 1',
    );
    final details = PrivateRequestDetails(
      eventName: 'Meeting',
      name: 'User',
      email: 'user@example.com',
      phone: '123',
    );

    test('loads request and details then initializes editor', () async {
      final viewModel = createViewModel(createRequest: false);

      when(
        () => mockBookingService.getRequest('test_org_id', 'req-1'),
      ).thenAnswer((_) => Stream.value(request));
      when(
        () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).thenAnswer((_) {});

      await viewModel.loadExistingRequest('req-1');

      verify(
        () => mockBookingService.getRequest('test_org_id', 'req-1'),
      ).called(1);
      verify(
        () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
      ).called(1);
      verify(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).called(1);
    });

    test(
      'is called on initialization when existingRequestID is provided',
      () async {
        when(
          () => mockBookingService.getRequest('test_org_id', 'req-1'),
        ).thenAnswer((_) => Stream.value(request));
        when(
          () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
        ).thenAnswer((_) => Stream.value(details));
        when(
          () => mockRequestEditorViewModel.initializeFromExistingRequest(
            request,
            details,
          ),
        ).thenAnswer((_) {});

        createViewModel(createRequest: false, existingRequestID: 'req-1');

        // Allow async init to complete
        await Future.delayed(Duration.zero);

        verify(
          () => mockBookingService.getRequest('test_org_id', 'req-1'),
        ).called(1);
        verify(
          () => mockBookingService.getRequestDetails('test_org_id', 'req-1'),
        ).called(1);
        verify(
          () => mockRequestEditorViewModel.initializeFromExistingRequest(
            request,
            details,
          ),
        ).called(1);
      },
    );
  });

  group('viewStateStream', () {
    test('emits correct ViewState', () async {
      final viewModel = createViewModel(createRequest: false);

      final future = expectLater(
        viewModel.viewStateStream,
        emits(isA<ViewState>()),
      );

      // Add to the stream AFTER subscribing because initialRequestController is broadcast
      initialRequestController.add(null);

      await future;
    });

    test('toggleRoomSelector updates stream', () async {
      final viewModel = createViewModel(createRequest: false);

      var states = <ViewState>[];
      viewModel.viewStateStream.listen(states.add);

      // Emit initial value for the other stream so combineLatest can emit
      initialRequestController.add(null);

      await Future.delayed(Duration.zero); // Wait for emission
      expect(states.isNotEmpty, true, reason: "Stream should have emitted");
      expect(states.last.showRoomSelector, true);

      viewModel.toggleRoomSelector();
      await Future.delayed(Duration.zero);
      expect(states.last.showRoomSelector, false);
    });
  });

  group('getActions', () {
    test('Admin actions included', () {
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(true);
      when(() => mockAuthService.getCurrentUserID()).thenReturn('user-1');

      final viewModel = createViewModel(createRequest: false);
      final actions = viewModel.getActions(mockContext);

      expect(actions.any((a) => a.name == "Review Requests"), true);
      expect(actions.any((a) => a.name == "Settings"), true);
      expect(actions.any((a) => a.name == "Logout"), true);
    });

    test('Logged out actions', () {
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
      when(() => mockAuthService.getCurrentUserID()).thenReturn(null);

      final viewModel = createViewModel(createRequest: false);
      final actions = viewModel.getActions(mockContext);

      expect(actions.any((a) => a.name == "Review Requests"), false);
      expect(actions.any((a) => a.name == "Login"), true);
    });

    test('Print action is always present', () {
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
      when(() => mockAuthService.getCurrentUserID()).thenReturn(null);

      final viewModel = createViewModel(createRequest: false);
      final actions = viewModel.getActions(mockContext);

      expect(actions.any((a) => a.name == "Print"), true);
    });

    test('Actions order: Print first, Login/Logout last', () {
      // Case 1: Admin & Logged In
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(true);
      when(() => mockAuthService.getCurrentUserID()).thenReturn('user-1');

      var viewModel = createViewModel(createRequest: false);
      var actions = viewModel.getActions(mockContext);

      expect(actions.first.name, "Print");
      expect(actions.last.name, "Logout");

      // Case 2: Not Admin & Logged Out
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
      when(() => mockAuthService.getCurrentUserID()).thenReturn(null);

      viewModel = createViewModel(createRequest: false);
      actions = viewModel.getActions(mockContext);

      expect(actions.first.name, "Print");
      expect(actions.last.name, "Login");
    });
  });

  group('currentUriStream', () {
    test('updates URI with correct parameters', () async {
      final updatedUris = <Uri>[];
      createViewModel(
        createRequest: false,
        showPrivateBookings: true,
        readOnlyMode: false,
        updateUri: updatedUris.add,
      );

      final date = DateTime(2023, 10, 27);
      final viewState = createViewState(
        currentDate: date,
        view: CalendarView.month,
      );

      // Trigger emission
      initialRequestController.add(null);
      calendarViewStateController.add(viewState);

      await Future.delayed(Duration.zero);

      expect(updatedUris.isNotEmpty, true);
      final uri = updatedUris.last;
      expect(uri.path, '/view/test_org_id');
      expect(uri.queryParameters['td'], '2023-10-27');
      expect(uri.queryParameters['v'], 'month');
      expect(uri.queryParameters.containsKey('ro'), false);
      expect(uri.queryParameters.containsKey('spb'), false);
      expect(uri.queryParameters.containsKey('createRequest'), false);
      expect(uri.queryParameters.containsKey('rid'), false);
    });

    test(
      'updates URI with readOnlyMode and createRequest parameters',
      () async {
        final updatedUris = <Uri>[];
        createViewModel(
          createRequest: true,
          showPrivateBookings: false,
          readOnlyMode: true,
          updateUri: updatedUris.add,
        );

        final date = DateTime(2023, 10, 28);
        final viewState = createViewState(
          currentDate: date,
          view: CalendarView.week,
        );

        initialRequestController.add(null);
        calendarViewStateController.add(viewState);

        await Future.delayed(Duration.zero);

        expect(updatedUris.isNotEmpty, true);
        final uri = updatedUris.last;
        expect(uri.queryParameters['td'], '2023-10-28');
        expect(uri.queryParameters['v'], 'week');
        expect(uri.queryParameters['ro'], 'true');
        expect(uri.queryParameters['spb'], 'false');
        expect(uri.queryParameters['createRequest'], 'true');
      },
    );

    test('updates URI with request ID', () async {
      final updatedUris = <Uri>[];
      createViewModel(createRequest: false, updateUri: updatedUris.add);

      final request = Request(
        id: 'req-123',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'r1',
        roomName: 'Room',
      );

      final viewState = createViewState();

      initialRequestController.add(request);
      calendarViewStateController.add(viewState);

      await Future.delayed(Duration.zero);

      expect(updatedUris.isNotEmpty, true);
      final uri = updatedUris.last;
      expect(uri.queryParameters['rid'], 'req-123');
    });

    test('updates URI without request ID when request ID is null', () async {
      final updatedUris = <Uri>[];
      createViewModel(createRequest: false, updateUri: updatedUris.add);

      final request = Request(
        id: null,
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'r1',
        roomName: 'Room',
      );

      final viewState = createViewState();

      initialRequestController.add(request);
      calendarViewStateController.add(viewState);

      await Future.delayed(Duration.zero);

      expect(updatedUris.isNotEmpty, true);
      final uri = updatedUris.last;
      expect(uri.queryParameters.containsKey('rid'), false);
    });
  });

  group('onAddNewBooking', () {
    test('onAddNewBooking navigates to create request', () async {
      when(
        () => mockCalendarViewModel.controller,
      ).thenReturn(CalendarController());
      // Mock the controller's displayDate
      // Since CalendarController is not easily mockable for properties, we might need to rely on how it's used.
      // However, in the test setup we mocked CalendarViewModel.
      // Let's mock the controller property access.
      final mockController = MockCalendarController();
      when(() => mockCalendarViewModel.controller).thenReturn(mockController);
      when(() => mockController.displayDate).thenReturn(DateTime(2023, 10, 27));

      when(() => mockStackRouter.push(any())).thenAnswer((_) async => null);

      final viewModel = createViewModel();
      viewModel.onAddNewBooking();

      // Wait for async operations
      await Future.delayed(Duration.zero);

      verify(() => mockStackRouter.push(any())).called(1);
    });
  });

  group('drag & resize rescheduling', () {
    final now = DateTime(2026, 6, 13, 10, 0);
    final request = Request(
      id: 'req_123',
      eventStartTime: now,
      eventEndTime: now.add(const Duration(hours: 1)),
      roomID: 'room_1',
      roomName: 'Room 1',
      publicName: 'Test Meeting',
      status: RequestStatus.confirmed,
    );
    final privateDetails = PrivateRequestDetails(
      eventName: 'Test Event',
      name: 'Test Name',
      email: 'test@example.com',
      phone: '1234567890',
    );

    setUp(() {
      when(() => mockBookingService.getRequest('test_org_id', 'req_123'))
          .thenAnswer((_) => Stream.value(request));
    });

    test('dragEndStream event triggers booking update successfully', () async {
      when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
          .thenAnswer((_) => Stream.value(privateDetails));
      when(() => mockBookingService.updateBooking(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            originalStartTime: any(named: 'originalStartTime'),
          )).thenAnswer((_) async {});

      createViewModel();
      
      final dropTime = DateTime(2026, 6, 13, 12, 0);
      dragEndController.add(DragDetails(
        request: request,
        originalStartTime: request.eventStartTime,
        dropTime: dropTime,
      ));

      await Future.delayed(Duration.zero);

      verify(() => mockBookingService.getRequestDetails('test_org_id', 'req_123')).called(1);
      final captured = verify(() => mockBookingService.updateBooking(
            'test_org_id',
            request,
            captureAny(),
            privateDetails,
            RequestStatus.confirmed,
            any(),
            originalStartTime: request.eventStartTime,
          )).captured;

      expect(captured.length, 1);
      final updatedRequest = captured.first as Request;
      expect(updatedRequest.eventStartTime, dropTime);
      expect(updatedRequest.eventEndTime, dropTime.add(const Duration(hours: 1)));
    });

    test('resizeEndStream event triggers booking update successfully', () async {
      when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
          .thenAnswer((_) => Stream.value(privateDetails));
      when(() => mockBookingService.updateBooking(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            originalStartTime: any(named: 'originalStartTime'),
          )).thenAnswer((_) async {});

      createViewModel();
      
      final newStartTime = DateTime(2026, 6, 13, 10, 0);
      final newEndTime = DateTime(2026, 6, 13, 11, 30);
      resizeEndController.add(ResizeDetails(
        request: request,
        originalStartTime: request.eventStartTime,
        startTime: newStartTime,
        endTime: newEndTime,
      ));

      await Future.delayed(Duration.zero);

      verify(() => mockBookingService.getRequestDetails('test_org_id', 'req_123')).called(1);
      final captured = verify(() => mockBookingService.updateBooking(
            'test_org_id',
            request,
            captureAny(),
            privateDetails,
            RequestStatus.confirmed,
            any(),
            originalStartTime: request.eventStartTime,
          )).captured;

      expect(captured.length, 1);
      final updatedRequest = captured.first as Request;
      expect(updatedRequest.eventStartTime, newStartTime);
      expect(updatedRequest.eventEndTime, newEndTime);
    });

    test('rescheduling handles error and displays SnackBar', () async {
      final snackbarCompleter = Completer<String>();
      when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
          .thenAnswer((_) => Stream.value(privateDetails));
      when(() => mockBookingService.updateBooking(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            originalStartTime: any(named: 'originalStartTime'),
          )).thenThrow(Exception('Overlap conflict'));

      createViewModel(
        showSnackBar: (msg) {
          snackbarCompleter.complete(msg);
        },
      );

      final dropTime = DateTime(2026, 6, 13, 12, 0);
      dragEndController.add(DragDetails(
        request: request,
        originalStartTime: request.eventStartTime,
        dropTime: dropTime,
      ));

      final errorMsg = await snackbarCompleter.future;
      expect(errorMsg, contains('Failed to reschedule: Exception: Overlap conflict'));
    });

    test('dragEndStream event on recurring instance passes correct originalStartTime', () async {
      when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
          .thenAnswer((_) => Stream.value(privateDetails));
      when(() => mockBookingService.updateBooking(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            originalStartTime: any(named: 'originalStartTime'),
          )).thenAnswer((_) async {});

      createViewModel();
      
      final occurrenceStartTime = now.add(const Duration(days: 2));
      final dropTime = occurrenceStartTime.add(const Duration(hours: 2));
      dragEndController.add(DragDetails(
        request: request,
        originalStartTime: occurrenceStartTime,
        dropTime: dropTime,
      ));

      await Future.delayed(Duration.zero);

      verify(() => mockBookingService.updateBooking(
            'test_org_id',
            request,
            any(that: isA<Request>()),
            privateDetails,
            RequestStatus.confirmed,
            any(),
            originalStartTime: occurrenceStartTime,
          )).called(1);
    });

    test('resizeEndStream event on recurring instance passes correct originalStartTime', () async {
      when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
          .thenAnswer((_) => Stream.value(privateDetails));
      when(() => mockBookingService.updateBooking(
            any(),
            any(),
            any(),
            any(),
            any(),
            any(),
            originalStartTime: any(named: 'originalStartTime'),
          )).thenAnswer((_) async {});

      createViewModel();
      
      final occurrenceStartTime = now.add(const Duration(days: 2));
      final newStartTime = occurrenceStartTime;
      final newEndTime = occurrenceStartTime.add(const Duration(hours: 2));
      resizeEndController.add(ResizeDetails(
        request: request,
        originalStartTime: occurrenceStartTime,
        startTime: newStartTime,
        endTime: newEndTime,
      ));

      await Future.delayed(Duration.zero);

      verify(() => mockBookingService.updateBooking(
            'test_org_id',
            request,
            any(that: isA<Request>()),
            privateDetails,
            RequestStatus.confirmed,
            any(),
            originalStartTime: occurrenceStartTime,
          )).called(1);
    });

    test('dragEndStream event forwards correct choiceProvider with different edit choices', () async {
      final choices = [
        RecurringBookingEditChoice.thisInstance,
        RecurringBookingEditChoice.all,
        RecurringBookingEditChoice.thisAndFuture,
      ];

      for (var expectedChoice in choices) {
        when(() => mockRequestEditorViewModel.choiceProvider)
            .thenReturn(() async => expectedChoice);
        when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
            .thenAnswer((_) => Stream.value(privateDetails));
        when(() => mockBookingService.updateBooking(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
              originalStartTime: any(named: 'originalStartTime'),
            )).thenAnswer((_) async {});

        createViewModel();

        final occurrenceStartTime = now.add(const Duration(days: 2));
        final dropTime = occurrenceStartTime.add(const Duration(hours: 2));
        dragEndController.add(DragDetails(
          request: request,
          originalStartTime: occurrenceStartTime,
          dropTime: dropTime,
        ));

        await Future.delayed(Duration.zero);

        final capturedChoiceProvider = verify(() => mockBookingService.updateBooking(
              'test_org_id',
              request,
              any(that: isA<Request>()),
              privateDetails,
              RequestStatus.confirmed,
              captureAny(),
              originalStartTime: occurrenceStartTime,
            )).captured.first as RecurringBookingEditChoiceProvider;

        final choice = await capturedChoiceProvider();
        expect(choice, expectedChoice);
      }
    });

    test('resizeEndStream event forwards correct choiceProvider with different edit choices', () async {
      final choices = [
        RecurringBookingEditChoice.thisInstance,
        RecurringBookingEditChoice.all,
        RecurringBookingEditChoice.thisAndFuture,
      ];

      for (var expectedChoice in choices) {
        when(() => mockRequestEditorViewModel.choiceProvider)
            .thenReturn(() async => expectedChoice);
        when(() => mockBookingService.getRequestDetails('test_org_id', 'req_123'))
            .thenAnswer((_) => Stream.value(privateDetails));
        when(() => mockBookingService.updateBooking(
              any(),
              any(),
              any(),
              any(),
              any(),
              any(),
              originalStartTime: any(named: 'originalStartTime'),
            )).thenAnswer((_) async {});

        createViewModel();

        final occurrenceStartTime = now.add(const Duration(days: 2));
        final newStartTime = occurrenceStartTime;
        final newEndTime = occurrenceStartTime.add(const Duration(hours: 2));
        resizeEndController.add(ResizeDetails(
          request: request,
          originalStartTime: occurrenceStartTime,
          startTime: newStartTime,
          endTime: newEndTime,
        ));

        await Future.delayed(Duration.zero);

        final capturedChoiceProvider = verify(() => mockBookingService.updateBooking(
              'test_org_id',
              request,
              any(that: isA<Request>()),
              privateDetails,
              RequestStatus.confirmed,
              captureAny(),
              originalStartTime: occurrenceStartTime,
            )).captured.first as RecurringBookingEditChoiceProvider;

        final choice = await capturedChoiceProvider();
        expect(choice, expectedChoice);
      }
    });
  });
}

class MockCalendarController extends Mock implements CalendarController {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}
