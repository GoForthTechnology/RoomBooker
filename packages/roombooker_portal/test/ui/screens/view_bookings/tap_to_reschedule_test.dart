import 'dart:async';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roombooker_portal/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:roombooker_portal/ui/widgets/booking_calendar/view_model.dart';
import 'package:roombooker_portal/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:roombooker_core/data/repos/room_repo.dart';
import 'package:roombooker_core/data/services/auth_service.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_core/data/services/analytics_service.dart';
import 'package:roombooker_portal/ui/widgets/room_selector.dart';
import 'package:roombooker_portal/ui/widgets/org_state_provider.dart';
import 'package:auto_route/auto_route.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/entities/organization.dart';

class MockRoomRepo extends Mock implements RoomRepo {}
class MockAuthService extends Mock implements AuthService {}
class MockOrgState extends Mock implements OrgState {}
class MockBookingService extends Mock implements BookingService {}
class MockStackRouter extends Mock implements StackRouter {}
class MockCalendarViewModel extends Mock implements CalendarViewModel {}
class MockRequestEditorViewModel extends Mock implements RequestEditorViewModel {}
class MockRoomState extends Mock implements RoomState {}
class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  late MockRoomRepo mockRoomRepo;
  late MockAuthService mockAuthService;
  late MockOrgState mockOrgState;
  late MockBookingService mockBookingService;
  late MockStackRouter mockStackRouter;
  late MockCalendarViewModel mockCalendarViewModel;
  late MockRequestEditorViewModel mockRequestEditorViewModel;

  late StreamController<DateTapDetails> dateTapController;
  late StreamController<Request> requestTapController;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(CalendarView.day);
    registerFallbackValue(DateTapDetails(date: DateTime.now(), view: CalendarView.day));
    registerFallbackValue(const Stream<(Request?, PrivateRequestDetails?)>.empty());
  });

  setUp(() {
    mockRoomRepo = MockRoomRepo();
    mockAuthService = MockAuthService();
    mockOrgState = MockOrgState();
    mockBookingService = MockBookingService();
    mockStackRouter = MockStackRouter();
    mockCalendarViewModel = MockCalendarViewModel();
    mockRequestEditorViewModel = MockRequestEditorViewModel();

    dateTapController = StreamController<DateTapDetails>.broadcast();
    requestTapController = StreamController<Request>.broadcast();

    when(() => mockCalendarViewModel.dateTapStream).thenAnswer((_) => dateTapController.stream);
    when(() => mockCalendarViewModel.requestTapStream).thenAnswer((_) => requestTapController.stream);
    when(() => mockCalendarViewModel.dragEndStream).thenAnswer((_) => const Stream.empty());
    when(() => mockCalendarViewModel.resizeEndStream).thenAnswer((_) => const Stream.empty());
    when(() => mockCalendarViewModel.calendarViewState()).thenAnswer((_) => Stream.empty());
    when(() => mockCalendarViewModel.registerNewAppointmentStream(any())).thenReturn(null);
    when(() => mockRequestEditorViewModel.currentDataStream()).thenAnswer((_) => Stream.empty());
    when(() => mockRequestEditorViewModel.initialRequestStream).thenAnswer((_) => Stream.empty());
    
    // Default mock for orgState
    when(() => mockOrgState.org).thenReturn(Organization(
      id: "org-1",
      name: "Test Org",
      ownerID: "owner-1",
      acceptingAdminRequests: true,
    ));
  });

  tearDown(() {
    dateTapController.close();
    requestTapController.close();
  });

  ViewBookingsViewModel createViewModel() {
    return ViewBookingsViewModel(
      roomRepo: mockRoomRepo,
      authService: mockAuthService,
      orgState: mockOrgState,
      bookingService: mockBookingService,
      router: mockStackRouter,
      sizeProvider: () => const Size(1000, 800),
      calendarViewModel: mockCalendarViewModel,
      requestEditorViewModel: mockRequestEditorViewModel,
      existingRequestID: null,
      showRoomSelector: false,
      createRequest: false,
      readOnlyMode: false,
      showPrivateBookings: true,
      showRequestDialog: (_) {},
      showEditorAsDialog: () {},
      showSnackBar: (_) {},
      updateUri: (_) {},
      pickDate: (_, _, _) async => null,
      pickTime: (_) async => null,
    );
  }

  group('Tap-to-Reschedule Logic', () {
    test('Tapping calendar in Day/Week view calls moveEventTo when rescheduling', () async {
      when(() => mockRequestEditorViewModel.isRescheduling).thenReturn(true);
      final targetDate = DateTime(2026, 5, 15, 14, 0);

      createViewModel();
      
      dateTapController.add(DateTapDetails(date: targetDate, view: CalendarView.week));
      await Future.delayed(Duration.zero);

      verify(() => mockRequestEditorViewModel.moveEventTo(targetDate)).called(1);
      verifyNever(() => mockRequestEditorViewModel.initializeNewRequest(any()));
    });

    test('Tapping calendar in Month view is ignored when rescheduling', () async {
      when(() => mockRequestEditorViewModel.isRescheduling).thenReturn(true);
      final targetDate = DateTime(2026, 5, 15);

      createViewModel();
      
      dateTapController.add(DateTapDetails(date: targetDate, view: CalendarView.month));
      await Future.delayed(Duration.zero);

      verifyNever(() => mockRequestEditorViewModel.moveEventTo(any()));
      verifyNever(() => mockCalendarViewModel.focusDate(any()));
    });

    test('Tapping calendar in Month view focuses date when NOT rescheduling', () async {
      when(() => mockRequestEditorViewModel.isRescheduling).thenReturn(false);
      final targetDate = DateTime(2026, 5, 15);

      createViewModel();
      
      dateTapController.add(DateTapDetails(date: targetDate, view: CalendarView.month));
      await Future.delayed(Duration.zero);

      verify(() => mockCalendarViewModel.focusDate(targetDate)).called(1);
    });

    test('Multiple moves preserves duration correctly in RequestEditorViewModel', () async {
      final start = DateTime(2026, 5, 15, 10, 0);
      final end = DateTime(2026, 5, 15, 11, 30); // 1.5 hours
      final duration = end.difference(start);

      final mockBookingService = MockBookingService();
      final mockAuthService = MockAuthService();
      final mockAnalyticsService = MockAnalyticsService();
      final mockOrgState = MockOrgState();
      final mockRoomState = MockRoomState();

      when(() => mockOrgState.org).thenReturn(Organization(id: "o1", name: "N", ownerID: "u1", acceptingAdminRequests: true));
      when(() => mockRoomState.enabledValues()).thenReturn(<Room>{});

      final editorViewModel = RequestEditorViewModel(
        editorTitle: "Edit",
        analyticsService: mockAnalyticsService,
        authService: mockAuthService,
        bookingService: mockBookingService,
        orgState: mockOrgState,
        roomState: mockRoomState,
        choiceProvider: () async => null,
      );

      final initialRequest = Request(
        id: "r1",
        eventStartTime: start,
        eventEndTime: end,
        roomID: "rm1",
        roomName: "Room",
        status: RequestStatus.confirmed,
      );

      editorViewModel.initializeFromExistingRequest(initialRequest, PrivateRequestDetails(name: "U", eventName: "E", email: "e@e.com", phone: "123"));

      final target1 = DateTime(2026, 5, 16, 14, 0);
      editorViewModel.moveEventTo(target1);
      
      var data = await editorViewModel.eventTimeStream.first;
      expect(data.$1, target1);
      expect(data.$2, target1.add(duration));

      final target2 = DateTime(2026, 5, 17, 09, 0);
      editorViewModel.moveEventTo(target2);

      data = await editorViewModel.eventTimeStream.first;
      expect(data.$1, target2);
      expect(data.$2, target2.add(duration));
    });
  });
}
