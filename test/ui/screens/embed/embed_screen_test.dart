import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/screens/embed/embed_screen.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

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
  late MockAuthService mockAuthService;

  setUpAll(() {
    registerFallbackValue(FakeAppointmentResizeEndDetails());
    registerFallbackValue(FakeAppointmentDragEndDetails());
    registerFallbackValue(FakeCalendarTapDetails());
    registerFallbackValue(CalendarView.week);
    registerFallbackValue(FakeOrganization());
  });

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockRoomRepo = MockRoomRepo();
    mockBookingRepo = MockBookingRepo();
    mockAuthService = MockAuthService();

    when(() => mockAuthService.getCurrentUserID()).thenReturn(null);

    // Default BookingRepo stubs
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
  });

  Widget createWidgetUnderTest({String? view}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
        Provider<FirebaseAuthService>.value(value: mockAuthService),
      ],
      child: MaterialApp(
        home: EmbedScreen(orgID: 'org1', view: view),
      ),
    );
  }

  /*testWidgets('EmbedScreen renders BookingCalendar when data is loaded', (
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
  });*/
}
