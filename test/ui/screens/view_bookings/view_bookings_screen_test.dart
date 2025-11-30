import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_screen.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockPreferencesRepo extends Mock implements PreferencesRepo {}

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

class MockFirebaseAnalyticsService extends Mock
    implements FirebaseAnalyticsService {}

class MockStackRouter extends Mock implements StackRouter {}

class MockViewBookingsViewModel extends Mock implements ViewBookingsViewModel {}

class MockCalendarViewModel extends Mock implements CalendarViewModel {}

class MockRequestEditorViewModel extends Mock
    implements RequestEditorViewModel {}

class FakeBuildContext extends Fake implements BuildContext {}

class FakeDataSource extends CalendarDataSource {
  FakeDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class FakeAppointmentResizeEndDetails extends Fake
    implements AppointmentResizeEndDetails {}

class FakeAppointmentDragEndDetails extends Fake
    implements AppointmentDragEndDetails {}

class FakeCalendarTapDetails extends Fake implements CalendarTapDetails {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FakeAppointmentResizeEndDetails());
    registerFallbackValue(FakeAppointmentDragEndDetails());
    registerFallbackValue(FakeCalendarTapDetails());
  });

  late MockOrgRepo mockOrgRepo;
  late MockRoomRepo mockRoomRepo;
  late MockBookingRepo mockBookingRepo;
  late MockPreferencesRepo mockPreferencesRepo;
  late MockFirebaseAuthService mockAuthService;
  late MockFirebaseAnalyticsService mockAnalyticsService;
  late MockStackRouter mockRouter;

  late MockViewBookingsViewModel mockViewModel;
  late MockCalendarViewModel mockCalendarViewModel;
  late MockRequestEditorViewModel mockRequestEditorViewModel;

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockRoomRepo = MockRoomRepo();
    mockBookingRepo = MockBookingRepo();
    mockPreferencesRepo = MockPreferencesRepo();
    mockAuthService = MockFirebaseAuthService();
    mockAnalyticsService = MockFirebaseAnalyticsService();
    mockRouter = MockStackRouter();

    mockViewModel = MockViewBookingsViewModel();
    mockCalendarViewModel = MockCalendarViewModel();
    mockRequestEditorViewModel = MockRequestEditorViewModel();

    // Default stubs
    when(
      () => mockAnalyticsService.logScreenView(
        screenName: any(named: 'screenName'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(ViewState(showRoomSelector: true, showEditor: false)),
    );
    when(() => mockViewModel.isSmallView()).thenReturn(false);
    when(() => mockViewModel.getActions(any())).thenReturn([]);
    when(() => mockViewModel.toggleRoomSelector()).thenReturn(null);
    when(() => mockViewModel.onAddNewBooking()).thenReturn(null);

    when(
      () => mockCalendarViewModel.controller,
    ).thenReturn(CalendarController());
    when(() => mockCalendarViewModel.calendarViewState()).thenAnswer(
      (_) => Stream.value(
        CalendarViewState(
          dataSource: FakeDataSource([]),
          allowDragAndDrop: false,
          allowAppointmentResize: false,
          specialRegions: [],
          currentView: CalendarView.month,
          currentDate: DateTime.now(),
        ),
      ),
    );
    when(() => mockCalendarViewModel.allowViewNavigation).thenReturn(true);
    when(() => mockCalendarViewModel.minDate).thenReturn(DateTime(2020));
    when(() => mockCalendarViewModel.showNavigationArrow).thenReturn(true);
    when(() => mockCalendarViewModel.showTodayButton).thenReturn(true);
    when(() => mockCalendarViewModel.showDatePickerButton).thenReturn(true);
    when(
      () => mockCalendarViewModel.allowedViews,
    ).thenReturn([CalendarView.month]);
    when(() => mockCalendarViewModel.handleResizeEnd(any())).thenReturn(null);
    when(() => mockCalendarViewModel.handleDragEnd(any())).thenReturn(null);
    when(() => mockCalendarViewModel.handleTap(any())).thenReturn(null);

    // Mock OrgRepo
    when(() => mockOrgRepo.getOrg(any())).thenAnswer(
      (_) => Stream.value(
        Organization(
          id: 'org1',
          name: 'Test Org',
          ownerID: 'owner1',
          acceptingAdminRequests: true,
        ),
      ),
    );
    when(
      () => mockOrgRepo.activeAdmins(any()),
    ).thenAnswer((_) => Stream.value([]));

    // Mock RoomRepo
    when(() => mockRoomRepo.listRooms(any())).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
        ChangeNotifierProvider<PreferencesRepo>.value(
          value: mockPreferencesRepo,
        ),
        ChangeNotifierProvider<FirebaseAuthService>.value(
          value: mockAuthService,
        ),
        ChangeNotifierProvider<FirebaseAnalyticsService>.value(
          value: mockAnalyticsService,
        ),
      ],
      child: MaterialApp(
        home: StackRouterScope(
          controller: mockRouter,
          stateHash: 0,
          child: ViewBookingsScreen(
            orgID: 'org1',
            createViewModel: (_) => mockViewModel,
            createCalendarViewModel: (_, __) => mockCalendarViewModel,
            createRequestEditorViewModel: (_) => mockRequestEditorViewModel,
          ),
        ),
      ),
    );
  }

  testWidgets('ViewBookingsScreen renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Test Org'), findsOneWidget);
    expect(find.byType(ViewBookingsScreen), findsOneWidget);
  });

  testWidgets('ViewBookingsScreen shows FAB and calls onAddNewBooking', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    verify(() => mockViewModel.onAddNewBooking()).called(1);
  });

  testWidgets('ViewBookingsScreen toggles room selector', (tester) async {
    when(() => mockViewModel.isSmallView()).thenReturn(false);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final menuButton = find.byIcon(Icons.menu);
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    verify(() => mockViewModel.toggleRoomSelector()).called(1);
  });
}
