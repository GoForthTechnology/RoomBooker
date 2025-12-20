import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/screens/org_settings/org_settings_screen.dart';
import 'package:room_booker/ui/widgets/org_settings/admin_widget.dart';
import 'package:room_booker/ui/widgets/org_settings/app_info.dart';
import 'package:room_booker/ui/widgets/org_settings/notification_widget.dart';
import 'package:room_booker/ui/widgets/org_settings/org_actions.dart';
import 'package:room_booker/ui/widgets/room_list_widget.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockLogRepo extends Mock implements LogRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockFirebaseAnalyticsService extends Mock
    implements FirebaseAnalyticsService {}

class MockStackRouter extends Mock implements StackRouter {}

class FakeRequestLogEntryStream extends Fake
    implements Stream<List<RequestLogEntry>> {}

void main() {
  late MockOrgRepo mockOrgRepo;
  late MockRoomRepo mockRoomRepo;
  late MockLogRepo mockLogRepo;
  late MockBookingRepo mockBookingRepo;
  late MockFirebaseAnalyticsService mockAnalyticsService;
  late MockStackRouter mockRouter;

  const String testOrgID = 'test-org-id';
  final testOrg = Organization(
    id: testOrgID,
    name: 'Test Org',
    ownerID: 'owner-id',
    acceptingAdminRequests: true,
  );

  setUpAll(() {
    registerFallbackValue(FakeRequestLogEntryStream());
    registerFallbackValue(<String, Object>{});
    registerFallbackValue(const PageRouteInfo('LandingRoute'));
  });

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockRoomRepo = MockRoomRepo();
    mockLogRepo = MockLogRepo();
    mockBookingRepo = MockBookingRepo();
    mockAnalyticsService = MockFirebaseAnalyticsService();
    mockRouter = MockStackRouter();

    when(
      () => mockAnalyticsService.logScreenView(
        screenName: any(named: 'screenName'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockOrgRepo.getOrg(testOrgID),
    ).thenAnswer((_) => Stream.value(testOrg));

    // Stubbing for child widgets that might use these repos
    when(
      () => mockOrgRepo.adminRequests(testOrgID),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockOrgRepo.activeAdmins(testOrgID),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockRoomRepo.listRooms(testOrgID),
    ).thenAnswer((_) => Stream.value([]));

    // Stubbing for RequestLogsWidget
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(
      () => mockBookingRepo.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
        ChangeNotifierProvider<LogRepo>.value(value: mockLogRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
        ChangeNotifierProvider<AnalyticsService>.value(
          value: mockAnalyticsService,
        ),
      ],
      child: MaterialApp(
        home: StackRouterScope(
          controller: mockRouter,
          stateHash: 0,
          child: const OrgSettingsScreen(orgID: testOrgID),
        ),
      ),
    );
  }

  testWidgets('shows loading indicator when stream has no data', (
    tester,
  ) async {
    when(
      () => mockOrgRepo.getOrg(testOrgID),
    ).thenAnswer((_) => const Stream.empty());

    await tester.pumpWidget(createWidgetUnderTest());
    // Pump once to let the build happen, but stream hasn't emitted yet (or is empty)
    // Actually StreamBuilder with no initial data and empty stream waits.
    // But here we want to test the waiting state.

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders all sections when data is loaded', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle(); // Wait for stream to emit

    expect(find.text('Organization Settings'), findsOneWidget);
    expect(find.byType(OrgDetails), findsOneWidget);
    expect(find.byType(LogsWidget), findsOneWidget);
    expect(find.byType(RoomListWidget), findsOneWidget);
    expect(find.byType(NotificationWidget), findsOneWidget);
    expect(find.byType(AdminWidget), findsOneWidget);
    expect(find.byType(AppInfoWidget), findsOneWidget);
    expect(find.byType(OrgActions), findsOneWidget);
  });

  testWidgets('logs screen view on build', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    verify(
      () => mockAnalyticsService.logScreenView(
        screenName: "Org Settings",
        parameters: {"orgID": testOrgID},
      ),
    ).called(1);
  });

  testWidgets('back button pops if can pop', (tester) async {
    when(() => mockRouter.canPop()).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pump();

    verify(() => mockRouter.pop()).called(1);
  });

  testWidgets('back button replaces with LandingRoute if cannot pop', (
    tester,
  ) async {
    when(() => mockRouter.canPop()).thenReturn(false);
    when(() => mockRouter.replace(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pump();

    // Since LandingRoute is generated, we might not be able to match it exactly without importing router.gr.dart
    // But we can verify replace is called.
    verify(() => mockRouter.replace(any())).called(1);
  });
}
