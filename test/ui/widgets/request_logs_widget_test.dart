import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/request_logs_widget.dart';

class MockLogRepo extends Mock implements LogRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockStackRouter extends Mock implements StackRouter {}

void main() {
  late MockLogRepo mockLogRepo;
  late MockBookingRepo mockBookingRepo;
  late MockStackRouter mockRouter;

  setUpAll(() {
    registerFallbackValue(Stream<List<RequestLogEntry>>.empty());
    registerFallbackValue(
      RequestLogEntry(
        requestID: 'fallback',
        timestamp: DateTime.now(),
        action: Action.create,
      ),
    );
    registerFallbackValue(<String>{});
    registerFallbackValue(const PageRouteInfo(''));
  });

  setUp(() {
    mockLogRepo = MockLogRepo();
    mockBookingRepo = MockBookingRepo();
    mockRouter = MockStackRouter();
    when(() => mockRouter.push(any())).thenAnswer((_) async => null);
  });

  Widget createWidgetUnderTest({
    required Organization org,
    String? requestID,
    bool allowPagination = true,
    bool showViewButton = true,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LogRepo>.value(value: mockLogRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
      ],
      child: MaterialApp(
        home: StackRouterScope(
          controller: mockRouter,
          stateHash: 0,
          child: Scaffold(
            body: RequestLogsWidget(
              org: org,
              requestID: requestID,
              allowPagination: allowPagination,
              showViewButton: showViewButton,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('RequestLogsWidget renders loading state', (tester) async {
    final org = Organization(
      id: 'org1',
      name: 'Test Org',
      ownerID: 'owner1',
      acceptingAdminRequests: true,
    );

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
    ).thenAnswer((_) => Stream.value([])); // Initially empty or waiting

    await tester.pumpWidget(createWidgetUnderTest(org: org));
    await tester.pump();

    // Should show loading or empty state depending on stream
    // If stream emits empty list immediately, it shows "No request logs found"
    expect(find.text('No request logs found'), findsOneWidget);
  });

  testWidgets('RequestLogsWidget renders logs', (tester) async {
    final org = Organization(
      id: 'org1',
      name: 'Test Org',
      ownerID: 'owner1',
      acceptingAdminRequests: true,
    );

    final logEntry = RequestLogEntry(
      id: 'log1',
      requestID: 'req1',
      timestamp: DateTime.now(),
      action: Action.create,
    );

    final request = Request(
      id: 'req1',
      roomID: 'room1',
      roomName: 'Room 1',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      publicName: 'Test Event',
      status: RequestStatus.confirmed,
      recurrancePattern: null,
      ignoreOverlaps: false,
    );

    final decoratedLog = DecoratedLogEntry(
      PrivateRequestDetails(
        email: 'test@example.com',
        eventName: 'Test Event',
        name: 'Test User',
        phone: '1234567890',
      ),
      entry: logEntry,
      request: request,
    );

    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([logEntry]));

    when(
      () => mockBookingRepo.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([decoratedLog]));

    await tester.pumpWidget(createWidgetUnderTest(org: org));
    await tester.pumpAndSettle();

    expect(find.text('test@example.com - create'), findsOneWidget);
    expect(find.textContaining('Test Event'), findsOneWidget);
    expect(find.text('VIEW'), findsOneWidget);
  });

  testWidgets('Clicking VIEW button navigates to ViewBookingsRoute', (
    tester,
  ) async {
    final org = Organization(
      id: 'org1',
      name: 'Test Org',
      ownerID: 'owner1',
      acceptingAdminRequests: true,
    );

    final logEntry = RequestLogEntry(
      id: 'log1',
      requestID: 'req1',
      timestamp: DateTime.now(),
      action: Action.create,
    );

    final request = Request(
      id: 'req1',
      roomID: 'room1',
      roomName: 'Room 1',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(const Duration(hours: 1)),
      publicName: 'Test Event',
      status: RequestStatus.confirmed,
      recurrancePattern: null,
      ignoreOverlaps: false,
    );

    final decoratedLog = DecoratedLogEntry(
      PrivateRequestDetails(
        email: 'test@example.com',
        eventName: 'Test Event',
        name: 'Test User',
        phone: '1234567890',
      ),
      entry: logEntry,
      request: request,
    );

    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([logEntry]));

    when(
      () => mockBookingRepo.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([decoratedLog]));

    await tester.pumpWidget(createWidgetUnderTest(org: org));
    await tester.pumpAndSettle();

    await tester.tap(find.text('VIEW'));
    await tester.pump();

    verify(
      () => mockRouter.push(
        any(
          that: isA<ViewBookingsRoute>()
              .having((r) => r.args!.orgID, 'args.orgID', 'org1')
              .having((r) => r.args!.requestID, 'args.requestID', 'req1'),
        ),
      ),
    ).called(1);
  });
}
