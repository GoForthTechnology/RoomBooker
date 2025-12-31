import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/services/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';

import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
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

  setUpAll(() {
    registerFallbackValue(Stream<(Request?, PrivateRequestDetails?)>.empty());
    registerFallbackValue(FakeRequest());
    registerFallbackValue(FakePrivateRequestDetails());
    registerFallbackValue(FakeViewBookingsRoute());
    registerFallbackValue(
      ViewBookingsRoute(orgID: 'test', createRequest: false),
    );
    registerFallbackValue(Uri());
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

    when(
      () => mockCalendarViewModel.dateTapStream,
    ).thenAnswer((_) => dateTapController.stream);
    when(
      () => mockCalendarViewModel.requestTapStream,
    ).thenAnswer((_) => requestTapController.stream);
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
}

class MockCalendarController extends Mock implements CalendarController {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}
