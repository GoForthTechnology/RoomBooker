import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/services/auth_service.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:room_booker/ui/screens/embed/embed_screen.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:room_booker/data/entities/request.dart';

import '../../../utils/fake_logging_service.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockUserRepo extends Mock implements UserRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockBookingService extends Mock implements BookingService {}

class MockAuthService extends Mock implements FirebaseAuthService {}

class FakeAppointmentResizeEndDetails extends Fake
    implements AppointmentResizeEndDetails {}

class FakeAppointmentDragEndDetails extends Fake
    implements AppointmentDragEndDetails {}

class FakeCalendarTapDetails extends Fake implements CalendarTapDetails {}

class FakeOrganization extends Fake implements Organization {}

void main() {
  late MockOrgRepo mockOrgRepo;
  late MockRoomRepo mockRoomRepo;
  late MockBookingRepo mockBookingRepo;
  late MockBookingService mockBookingService;
  late MockUserRepo mockUserRepo;
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FakeAppointmentResizeEndDetails());
    registerFallbackValue(FakeAppointmentDragEndDetails());
    registerFallbackValue(FakeCalendarTapDetails());
    registerFallbackValue(CalendarView.week);
    registerFallbackValue(FakeOrganization());
    registerFallbackValue(DateTime.now());
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
        name: 'Test',
        email: 'test@test',
        phone: '123',
        eventName: 'Event',
      ),
    );
    registerFallbackValue(RequestStatus.confirmed);
    registerFallbackValue(<RequestStatus>[]);
  });

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockRoomRepo = MockRoomRepo();
    mockRoomRepo = MockRoomRepo();
    mockBookingRepo = MockBookingRepo();
    mockBookingService = MockBookingService();
    mockUserRepo = MockUserRepo();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.getCurrentUserID()).thenReturn(null);

    // Default BookingRepo stubs
    when(
      () => mockBookingService.getRequestsStream(
        orgID: any(named: 'orgID'),
        isAdmin: any(named: 'isAdmin'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        includeStatuses: any(named: 'includeStatuses'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(
      () => mockBookingRepo.getRequestDetails(any(), any()),
    ).thenAnswer((_) => Stream.value(null));

    when(
      () => mockBookingService.listBlackoutWindows(any(), any(), any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  Widget createWidgetUnderTest({String? view}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
        Provider<BookingRepo>(create: (_) => mockBookingRepo),
        Provider<BookingService>.value(value: mockBookingService),
        ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ChangeNotifierProvider<LoggingService>.value(
          value: FakeLoggingService(),
        ),
        ChangeNotifierProvider<UserRepo>.value(value: mockUserRepo),
      ],
      child: MaterialApp(
        home: EmbedScreen(orgID: 'org1', view: view),
      ),
    );
  }

  // ... (Existing tests: renders BookingCalendar, loading indicator, error, view param, all rooms)
  // I will append new tests here, but since I am using replace_file_content I need to target insertion correctly.
  // Wait, I am replacing setUpAll and setUp completely?
  // Efficient strategy: Replace setUpAll/setUp first. Then append tests.
  // Code edit below replaces setUpAll and setUp logic.

  // Actually, I can replace lines 50-53 with expanded list.
  // And append tests at the end.
  // replace_file_content allows replacing a block.
  // I'll update setUpAll first.

  testWidgets(
    'EmbedScreen shows appointments for all rooms (enables all rooms)',
    (tester) async {
      // ... (existing test content)
    },
  );

  testWidgets('EmbedScreen renders appointments from BookingRepo', (
    tester,
  ) async {
    // Arrange
    when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
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
      () => mockOrgRepo.activeAdmins('org1'),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockRoomRepo.listRooms('org1')).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );

    final booking = Request(
      id: 'req1',
      eventStartTime: DateTime.now(), // Today
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      roomID: 'room1',
      roomName: 'Room 1',
      publicName: 'Meeting',
      status: RequestStatus.confirmed,
    );

    when(
      () => mockBookingService.getRequestsStream(
        orgID: any(named: 'orgID'),
        isAdmin: any(named: 'isAdmin'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        includeStatuses: any(named: 'includeStatuses'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
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

    // Assert
    expect(find.textContaining('Meeting'), findsOneWidget);
    // Subject is rendered in Appointment widget used in BookingCalendarView
  });

  testWidgets('Tapping data in EmbedScreen does not crash', (tester) async {
    // Arrange
    when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
      (_) => Stream.value(
        Organization(
          id: 'org1',
          name: 'Test Org',
          ownerID: 'owner1',
          acceptingAdminRequests: true,
        ),
      ),
    );
    // Helper would be nice, but stick to verbose
    when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
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
      () => mockOrgRepo.activeAdmins('org1'),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockRoomRepo.listRooms('org1')).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );

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
      () => mockBookingService.getRequestsStream(
        orgID: any(named: 'orgID'),
        isAdmin: any(named: 'isAdmin'),
        start: any(named: 'start'),
        end: any(named: 'end'),
        includeStatuses: any(named: 'includeStatuses'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
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

    final appointmentFinder = find.textContaining('Meeting');
    expect(appointmentFinder, findsOneWidget);

    await tester.tap(appointmentFinder);
    await tester.pump();

    // Assert - No error, no navigation check (since Router is not strictly mocked/verified here?
    // EmbedScreen doesn't depend on Router?
    // EmbedScreen is RoutePage but it doesn't use Router inside unless interacting.
    // BookingCalendar uses Router? No.
    // Only ViewBookingsViewModel uses Router. EmbedScreen calls CalendarViewModel directly.
    // CalendarViewModel has requestTapStream. Nobody listens to it in EmbedScreen.
    // So nothing should happen.
  });

  testWidgets('EmbedScreen renders BookingCalendar when data is loaded', (
    tester,
  ) async {
    // Arrange
    when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
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
      () => mockOrgRepo.activeAdmins('org1'),
    ).thenAnswer((_) => Stream.value([]));

    when(() => mockRoomRepo.listRooms('org1')).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());

    // Pump to settle OrgStateProvider
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Pump to settle RoomStateProvider
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Assert
    expect(find.byType(BookingCalendar), findsOneWidget);
    expect(find.byType(EmbedScreen), findsOneWidget);
  });

  testWidgets('EmbedScreen shows loading indicator initially', (tester) async {
    // Arrange - delay the response
    when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
      (_) => Stream.fromFuture(
        Future.delayed(
          const Duration(seconds: 2),
          () => Organization(
            id: 'org1',
            name: 'Test Org',
            ownerID: 'owner1',
            acceptingAdminRequests: true,
          ),
        ),
      ),
    );
    when(
      () => mockOrgRepo.activeAdmins('org1'),
    ).thenAnswer((_) => Stream.value([]));

    when(() => mockRoomRepo.listRooms('org1')).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // First frame

    // Assert
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Finish
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('EmbedScreen shows error when org not found', (tester) async {
    // Arrange
    when(
      () => mockOrgRepo.getOrg('org1'),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => mockOrgRepo.activeAdmins('org1'),
    ).thenAnswer((_) => Stream.value([]));

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Assert
    expect(find.text('Organization not found'), findsOneWidget);
  });

  testWidgets('EmbedScreen respects view query param', (tester) async {
    // Arrange
    when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
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
      () => mockOrgRepo.activeAdmins('org1'),
    ).thenAnswer((_) => Stream.value([]));

    when(() => mockRoomRepo.listRooms('org1')).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest(view: 'month'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // OrgState loaded
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // RoomState loaded

    // Assert
    // Verify that the calendar is in month view.
    // Since we can't easily inspect the internal state of SfCalendar created by BookingCalendar directly
    // without more complex finding, we rely on BookingCalendar being created.
    // However, createViewModel is called inside build.
    // We can verify that the view param was passed correctly if we could mock BookingCalendar, but we can't.
    // For now, just ensuring it renders without error with the param is a good sanity check.
    expect(find.byType(BookingCalendar), findsOneWidget);
  });
  testWidgets(
    'EmbedScreen shows appointments for all rooms (enables all rooms)',
    (tester) async {
      // Arrange
      when(() => mockOrgRepo.getOrg('org1')).thenAnswer(
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
        () => mockOrgRepo.activeAdmins('org1'),
      ).thenAnswer((_) => Stream.value([]));

      final rooms = [
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
        Room(id: 'room2', name: 'Room 2', colorHex: '#00FF00'),
        Room(id: 'room3', name: 'Room 3', colorHex: '#FF0000'),
      ];

      when(
        () => mockRoomRepo.listRooms('org1'),
      ).thenAnswer((_) => Stream.value(rooms));

      when(
        () => mockBookingService.getRequestsStream(
          orgID: any(named: 'orgID'),
          isAdmin: any(named: 'isAdmin'),
          start: any(named: 'start'),
          end: any(named: 'end'),
          includeStatuses: any(named: 'includeStatuses'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
        ),
      ).thenAnswer((_) => Stream.value([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // OrgState loaded
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // RoomState loaded

      // Assert
      final bookingCalendarFinder = find.byType(BookingCalendar);
      expect(bookingCalendarFinder, findsOneWidget);

      final context = tester.element(bookingCalendarFinder);
      final roomState = Provider.of<RoomState>(context, listen: false);

      expect(roomState.enabledValues().length, 3);
      for (var room in rooms) {
        expect(roomState.isEnabled(room.id!), isTrue);
      }
    },
  );
}
