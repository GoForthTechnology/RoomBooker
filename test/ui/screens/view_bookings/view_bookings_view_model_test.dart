import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockBookingRepo extends Mock implements BookingRepo {}

class MockAuthService extends Mock implements AuthService {}

class MockOrgState extends Mock implements OrgState {}

class MockStackRouter extends Mock implements StackRouter {}

class MockCalendarViewModel extends Mock implements CalendarViewModel {}

class MockRequestEditorViewModel extends Mock
    implements RequestEditorViewModel {}

class MockOrganization extends Mock implements Organization {}

class MockBuildContext extends Mock implements BuildContext {}

// Fakes
class FakeRequest extends Fake implements Request {}

class FakePrivateRequestDetails extends Fake implements PrivateRequestDetails {}

class FakeViewBookingsRoute extends Fake implements ViewBookingsRoute {}

void main() {
  late MockBookingRepo mockBookingRepo;
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

  setUpAll(() {
    registerFallbackValue(Stream<(Request?, PrivateRequestDetails?)>.empty());
    registerFallbackValue(FakeRequest());
    registerFallbackValue(FakePrivateRequestDetails());
    registerFallbackValue(FakeViewBookingsRoute());
    registerFallbackValue(
      ViewBookingsRoute(orgID: 'test', createRequest: false),
    );
  });

  setUp(() {
    mockBookingRepo = MockBookingRepo();
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

    when(
      () => mockCalendarViewModel.dateTapStream,
    ).thenAnswer((_) => dateTapController.stream);
    when(
      () => mockCalendarViewModel.requestTapStream,
    ).thenAnswer((_) => requestTapController.stream);
    when(
      () => mockRequestEditorViewModel.initialRequestStream,
    ).thenAnswer((_) => initialRequestController.stream);
    when(() => mockRequestEditorViewModel.currentDataStream()).thenAnswer(
      (_) => Stream<(Request?, PrivateRequestDetails?)>.value((null, null)),
    );

    when(() => mockOrgState.org).thenReturn(mockOrganization);
    when(() => mockOrganization.id).thenReturn('test-org-id');
  });

  tearDown(() {
    dateTapController.close();
    requestTapController.close();
    initialRequestController.close();
  });

  ViewBookingsViewModel createViewModel({
    required bool createRequest,
    bool readOnlyMode = false,
    Size? size,
    Function(Request)? showRequestDialog,
    Function()? showEditorAsDialog,
  }) {
    return ViewBookingsViewModel(
      bookingRepo: mockBookingRepo,
      authService: mockAuthService,
      orgState: mockOrgState,
      router: mockStackRouter,
      sizeProvider: () => size ?? const Size(1000, 800),
      calendarViewModel: mockCalendarViewModel,
      requestEditorViewModel: mockRequestEditorViewModel,
      existingRequestID: null,
      showRoomSelector: false,
      createRequest: createRequest,
      readOnlyMode: readOnlyMode,
      showRequestDialog: showRequestDialog ?? (_) {},
      showEditorAsDialog: showEditorAsDialog ?? () {},
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
      verifyZeroInteractions(mockBookingRepo);
    });

    test('!readOnlyMode loads details and initializes editor', () async {
      createViewModel(createRequest: false, readOnlyMode: false);

      when(
        () => mockBookingRepo.getRequestDetails('test-org-id', 'req-1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).thenAnswer((_) {});

      requestTapController.add(request);
      await Future.delayed(Duration.zero);

      verify(
        () => mockBookingRepo.getRequestDetails('test-org-id', 'req-1'),
      ).called(1);
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

      when(
        () => mockBookingRepo.getRequestDetails('test-org-id', 'req-1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).thenAnswer((_) {});

      requestTapController.add(request);
      await Future.delayed(Duration.zero);

      expect(showEditorCalled, true);
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

    test('loadNewRequest is NOT called when createRequest is false', () async {
      createViewModel(createRequest: false);
      final targetDate = DateTime(2023, 10, 27);

      dateTapController.add(
        DateTapDetails(date: targetDate, view: CalendarView.day),
      );
      await Future.delayed(Duration.zero);

      verifyNever(() => mockRequestEditorViewModel.initializeNewRequest(any()));
    });

    test('Month view triggers navigation to Day view', () async {
      createViewModel(createRequest: false);
      final targetDate = DateTime(2023, 10, 27);

      when(() => mockStackRouter.push(any())).thenAnswer((_) async => null);

      dateTapController.add(
        DateTapDetails(date: targetDate, view: CalendarView.month),
      );
      await Future.delayed(Duration.zero);

      verify(
        () => mockStackRouter.push(any(that: isA<ViewBookingsRoute>())),
      ).called(1);
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
        () => mockBookingRepo.getRequest('test-org-id', 'req-1'),
      ).thenAnswer((_) => Stream.value(request));
      when(
        () => mockBookingRepo.getRequestDetails('test-org-id', 'req-1'),
      ).thenAnswer((_) => Stream.value(details));
      when(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).thenAnswer((_) {});

      await viewModel.loadExistingRequest('req-1');

      verify(
        () => mockBookingRepo.getRequest('test-org-id', 'req-1'),
      ).called(1);
      verify(
        () => mockBookingRepo.getRequestDetails('test-org-id', 'req-1'),
      ).called(1);
      verify(
        () => mockRequestEditorViewModel.initializeFromExistingRequest(
          request,
          details,
        ),
      ).called(1);
    });
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
      expect(states.last.showRoomSelector, false);

      viewModel.toggleRoomSelector();
      await Future.delayed(Duration.zero);
      expect(states.last.showRoomSelector, true);
    });
  });

  group('getActions', () {
    setUp(() {
      // AutoRoute.of(context) returns the router. We can mock this using a provider or finding
      // a way to mock the static call.
      // However, ViewBookingsViewModel uses AutoRouter.of(context).
      // Mocking static extensions or inherited widgets in unit tests without a widget tree is hard.
      // We will test the logic branches based on auth/admin state, but we might not be able to call onPressed
      // without crashing if we don't wrap in a proper widget test or mock AutoRouter.of.
      // For unit test of ViewModel, we check the list content.
    });

    test('Admin actions included', () {
      when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
      when(() => mockAuthService.getCurrentUserID()).thenReturn('user-1');

      final viewModel = createViewModel(createRequest: false);
      final actions = viewModel.getActions(mockContext);

      expect(actions.any((a) => a.name == "Review Requests"), true);
      expect(actions.any((a) => a.name == "Settings"), true);
      expect(actions.any((a) => a.name == "Logout"), true);
    });

    test('Logged out actions', () {
      when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
      when(() => mockAuthService.getCurrentUserID()).thenReturn(null);

      final viewModel = createViewModel(createRequest: false);
      final actions = viewModel.getActions(mockContext);

      expect(actions.any((a) => a.name == "Review Requests"), false);
      expect(actions.any((a) => a.name == "Login"), true);
    });
  });
}
