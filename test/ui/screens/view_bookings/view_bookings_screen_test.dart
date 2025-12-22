import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/logging_service.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_screen.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/navigation_drawer.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../utils/fake_analytics_service.dart';
import '../../../utils/fake_logging_service.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockPreferencesRepo extends Mock implements PreferencesRepo {}

class MockUserRepo extends Mock implements UserRepo {}

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

class MockStackRouter extends Mock implements StackRouter {}

void main() {
  Provider.debugCheckInvalidValueType = null;

  late MockOrgRepo mockOrgRepo;
  late MockRoomRepo mockRoomRepo;
  late MockBookingRepo mockBookingRepo;
  late MockPreferencesRepo mockPreferencesRepo;
  late MockUserRepo mockUserRepo;
  late MockFirebaseAuthService mockAuthService;
  late FakeAnalyticsService fakeAnalyticsService;
  late MockStackRouter mockRouter;

  setUpAll(() {
    registerFallbackValue(
      Request(
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'room1',
        roomName: 'Room 1',
      ),
    );
    registerFallbackValue(
      PrivateRequestDetails(
        name: 'Test User',
        email: 'test@example.com',
        phone: '1234567890',
        eventName: 'Test Event',
      ),
    );
    registerFallbackValue(
      Organization(
        id: 'org1',
        name: 'Fallback Org',
        ownerID: 'owner1',
        acceptingAdminRequests: false,
      ),
    );
    registerFallbackValue(RequestStatus.confirmed);
    registerFallbackValue(<RequestStatus>[]);
    registerFallbackValue(<Room>[]);
    registerFallbackValue(<AdminEntry>[]);
    registerFallbackValue(DateTime.now());
  });

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockRoomRepo = MockRoomRepo();
    mockBookingRepo = MockBookingRepo();
    mockPreferencesRepo = MockPreferencesRepo();
    mockUserRepo = MockUserRepo();
    mockAuthService = MockFirebaseAuthService();
    fakeAnalyticsService = FakeAnalyticsService();
    mockRouter = MockStackRouter();

    // Default Stubs
    when(() => mockAuthService.getCurrentUserID()).thenReturn('user1');
    when(
      () => mockAuthService.getCurrentUserEmail(),
    ).thenReturn('test@test.com');

    when(
      () => mockPreferencesRepo.defaultCalendarView,
    ).thenReturn(CalendarView.week);

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
    // Behave as Admin
    when(() => mockOrgRepo.activeAdmins(any())).thenAnswer(
      (_) => Stream.value([
        AdminEntry(
          id: 'user1',
          email: 'test@test.com',
          lastUpdated: DateTime.now(),
        ),
      ]),
    );

    when(() => mockRoomRepo.listRooms(any())).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );

    // Bookings
    when(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(
      () => mockBookingRepo.listBlackoutWindows(any(), any(), any()),
    ).thenAnswer((_) => Stream.value([]));

    // UserRepo
    when(() => mockUserRepo.getUser(any())).thenAnswer((_) async => null);
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
        Provider<AuthService>.value(value: mockAuthService),
        ChangeNotifierProvider<AnalyticsService>.value(
          value: fakeAnalyticsService,
        ),
        ChangeNotifierProvider<LoggingService>.value(
          value: FakeLoggingService(),
        ),
        ChangeNotifierProvider<UserRepo>.value(value: mockUserRepo),
      ],
      child: MaterialApp(
        home: StackRouterScope(
          controller: mockRouter,
          stateHash: 0,
          child: ViewBookingsScreen(orgID: 'org1'),
        ),
      ),
    );
  }

  testWidgets('ViewBookingsScreen renders correctly (Deep Assembly)', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // OrgState
    await tester.pump(); // RoomState
    await tester.pumpAndSettle();

    expect(find.text('Test Org'), findsOneWidget);
    expect(find.byType(ViewBookingsScreen), findsOneWidget);
    expect(find.byType(BookingCalendarView), findsOneWidget);
  });

  testWidgets('Clicking FAB opens route to create new booking', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);
  });

  testWidgets('Toggling room selector opens drawer (Interaction)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800); // Large screen
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final menuButton = find.byIcon(Icons.menu);
    expect(menuButton, findsOneWidget);

    final drawerFinder = find.byType(MyDrawer);
    final drawerContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: drawerFinder, matching: find.byType(AnimatedContainer))
          .first,
    );
    // Initially open due to defaults in ViewBookingsViewModel
    expect(drawerContainer.constraints!.maxWidth, 300.0);

    // Tap to toggle (Close)
    await tester.tap(menuButton);
    await tester.pump();
    await tester.pumpAndSettle();

    final closedDrawerContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: drawerFinder, matching: find.byType(AnimatedContainer))
          .first,
    );
    expect(closedDrawerContainer.constraints!.maxWidth, 0.0);
  });

  testWidgets('Clicking a booking opens the Editor (Deep Assembly)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Arrange: Mock returning a booking
    final booking = Request(
      id: 'req1',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      roomID: 'room1',
      roomName: 'Room 1',
      publicName: 'Meeting',
      status: RequestStatus.confirmed,
    );

    when(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).thenAnswer((_) => Stream.value([booking]));

    when(() => mockBookingRepo.getRequestDetails('org1', 'req1')).thenAnswer(
      (_) => Stream.value(
        PrivateRequestDetails(
          eventName: 'Meeting',
          name: 'Test',
          email: 'test@test',
          phone: '123',
        ),
      ),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(BookingCalendarView), findsOneWidget);
    verify(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).called(greaterThan(0));
  });
}
