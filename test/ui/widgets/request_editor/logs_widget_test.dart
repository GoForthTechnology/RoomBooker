import 'package:flutter/material.dart' hide Action;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/request_editor/logs_widget.dart';

// Mocks
class MockOrganization extends Mock implements Organization {}

class MockLogRepo extends Mock implements LogRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockRequestLogEntry extends Mock implements RequestLogEntry {}

class MockDecoratedLogEntry extends Mock implements DecoratedLogEntry {}

void main() {
  late MockOrganization mockOrg;
  late MockLogRepo mockLogRepo;
  late MockBookingRepo mockBookingRepo;

  setUpAll(() {
    registerFallbackValue(MockRequestLogEntry());
    registerFallbackValue(const Stream<List<RequestLogEntry>>.empty());
    registerFallbackValue(const Stream<List<DecoratedLogEntry>>.empty());
  });

  setUp(() {
    mockOrg = MockOrganization();
    mockLogRepo = MockLogRepo();
    mockBookingRepo = MockBookingRepo();

    // Reset mocks or just creating new ones is fine.
    
    // Basic stubs that don't depend on arguments
    when(() => mockOrg.id).thenReturn('org-1');
  });

  Widget createWidgetUnderTest({required String requestID, bool readOnly = false}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LogRepo>.value(value: mockLogRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LogsWidget(
            org: mockOrg,
            requestID: requestID,
            readOnly: readOnly,
          ),
        ),
      ),
    );
  }

  group('LogsWidget', () {
    testWidgets('renders ExpansionTile with correct title', (tester) async {
      // Arrange
      // We need to mock the calls made by RequestLogsWidget even if we don't expect data yet
      when(() => mockLogRepo.getLogEntries(
            any(),
            limit: any(named: 'limit'),
            startAfter: any(named: 'startAfter'),
            requestIDs: any(named: 'requestIDs'),
          )).thenAnswer((_) => Stream.value([]));

      when(() => mockBookingRepo.decorateLogs(any(), any()))
          .thenAnswer((_) => Stream.value([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(requestID: 'req-1'));

      // Assert
      expect(find.text('Request Log'), findsOneWidget);
      expect(find.byType(ExpansionTile), findsOneWidget);
    });

    testWidgets('expands and shows logs when tapped', (tester) async {
      // Arrange
      final timestamp = DateTime(2023, 10, 27, 10, 30);
      final logEntry = RequestLogEntry(
        requestID: 'req-1',
        timestamp: timestamp,
        action: Action.create,
        adminEmail: 'admin@example.com',
      );
      
      // Need dummy request and details for DecoratedLogEntry
      final request = Request(
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'room-1',
        roomName: 'Room 1',
        id: 'req-1',
      );
      
      final details = PrivateRequestDetails(
        eventName: 'Test Event',
        name: 'User',
        email: 'user@example.com',
        phone: '1234567890',
      );

      final decoratedLog = DecoratedLogEntry(
        details,
        entry: logEntry,
        request: request,
      );

      when(() => mockLogRepo.getLogEntries(
            any(),
            limit: any(named: 'limit'),
            startAfter: any(named: 'startAfter'),
            requestIDs: any(named: 'requestIDs'),
          )).thenAnswer((_) => Stream.value([logEntry]));

      when(() => mockBookingRepo.decorateLogs(any(), any()))
          .thenAnswer((_) => Stream.value([decoratedLog]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(requestID: 'req-1'));
      await tester.pump(); // Allow FutureBuilder/StreamBuilder to settle if needed

      // Initially collapsed, but ExpansionTile keeps children in tree? 
      // Actually ExpansionTile by default doesn't build children until expanded unless maintainState is true (default).
      // But let's tap to expand to be sure and to see the content visible.
      
      await tester.tap(find.text('Request Log'));
      await tester.pumpAndSettle();

      // Assert
      // Check title builder output: "${entry.action.name} on ${dateFormat.format(entry.timestamp)}"
      // Action.create.name is "create"
      // DateFormat('MM/dd/yyyy').format(timestamp) -> 10/27/2023
      expect(find.text('create on 10/27/2023'), findsOneWidget);

      // Check subtitle builder output: "By ${entry.adminEmail} at ${timeFormat.format(entry.timestamp)}"
      // DateFormat('HH:mm').format(timestamp) -> 10:30
      expect(find.text('By admin@example.com at 10:30'), findsOneWidget);
    });

    testWidgets('is disabled when readOnly is true', (tester) async {
        // Arrange
      when(() => mockLogRepo.getLogEntries(
            any(),
            limit: any(named: 'limit'),
            startAfter: any(named: 'startAfter'),
            requestIDs: any(named: 'requestIDs'),
          )).thenAnswer((_) => Stream.value([]));

      when(() => mockBookingRepo.decorateLogs(any(), any()))
          .thenAnswer((_) => Stream.value([]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest(requestID: 'req-1', readOnly: true));

      // Assert
      // Verify ExpansionTile is disabled. 
      // We can check if the ListTile (part of ExpansionTile header) is disabled or if tapping does nothing.
      // ExpansionTile doesn't have an explicit 'enabled' property in older Flutter versions, but the snippet has 'enabled: !readOnly'.
      // So we can check that property.
      
      final expansionTile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
      expect(expansionTile.enabled, isFalse);
    });
  });
}
