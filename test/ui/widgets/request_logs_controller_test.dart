import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/request_logs_controller.dart';

class MockLogRepo extends Mock implements LogRepo {}

class MockBookingService extends Mock implements BookingService {}

void main() {
  late MockLogRepo mockLogRepo;
  late MockBookingService mockBookingService;

  setUp(() {
    mockLogRepo = MockLogRepo();
    mockBookingService = MockBookingService();
    registerFallbackValue(Stream<List<RequestLogEntry>>.empty());
    registerFallbackValue(<String>{});
  });

  RequestLogEntry createLogEntry(String id) {
    return RequestLogEntry(
      id: id,
      requestID: 'req_$id',
      timestamp: DateTime.now(),
      action: Action.create,
    );
  }

  DecoratedLogEntry createDecoratedLog(String id) {
    final entry = createLogEntry(id);
    return DecoratedLogEntry(
      PrivateRequestDetails(
        email: 'test@example.com',
        eventName: 'Test Event',
        name: 'Test User',
        phone: '1234567890',
      ),
      entry: entry,
      request: Request(
        id: 'req_$id',
        roomID: 'room1',
        roomName: 'Room 1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        publicName: 'Test Event',
        status: RequestStatus.confirmed,
        recurrancePattern: null,
        ignoreOverlaps: false,
      ),
    );
  }

  test('RequestLogsController loads logs initially', () async {
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([]));

    final controller = RequestLogsController(
      logRepo: mockLogRepo,
      bookingService: mockBookingService,
      orgID: 'org1',
    );

    expect(controller.isLoading, true);

    // Wait for stream to emit
    await Future.delayed(Duration.zero);

    expect(controller.isLoading, false);
    expect(controller.logs, isEmpty);
  });

  test('RequestLogsController handles errors', () async {
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.error('Test Error'));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.error('Test Error'));

    final controller = RequestLogsController(
      logRepo: mockLogRepo,
      bookingService: mockBookingService,
      orgID: 'org1',
    );

    await Future.delayed(Duration.zero);

    expect(controller.isLoading, false);
    expect(controller.error, contains('Test Error'));
  });

  test('RequestLogsController handles pagination', () async {
    final log1 = createDecoratedLog('1');
    final log2 = createDecoratedLog('2');

    // Initial load
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: null,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([log1.entry]));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([log1]));

    final controller = RequestLogsController(
      logRepo: mockLogRepo,
      bookingService: mockBookingService,
      orgID: 'org1',
    );

    await Future.delayed(Duration.zero);

    expect(controller.logs.length, 1);
    expect(controller.logs.first.entry.id, '1');
    expect(controller.canGoBack, false);

    // Next page
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: log1.entry,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([log2.entry]));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([log2]));

    controller.nextPage();
    expect(controller.isLoading, true);

    await Future.delayed(Duration.zero);

    expect(controller.logs.length, 1);
    expect(controller.logs.first.entry.id, '2');
    expect(controller.canGoBack, true);

    // Previous page
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: null,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([log1.entry]));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([log1]));

    controller.previousPage();
    expect(controller.isLoading, true);

    await Future.delayed(Duration.zero);

    expect(controller.logs.length, 1);
    expect(controller.logs.first.entry.id, '1');
    expect(controller.canGoBack, false);
  });

  test('RequestLogsController updates records per page', () async {
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([]));

    final controller = RequestLogsController(
      logRepo: mockLogRepo,
      bookingService: mockBookingService,
      orgID: 'org1',
    );

    // Initial load with default 5
    await Future.delayed(Duration.zero);
    expect(controller.recordsPerPage, 5);

    // Change to 10
    controller.setRecordsPerPage(10);
    expect(controller.recordsPerPage, 10);
    expect(controller.isLoading, true);

    await Future.delayed(Duration.zero);
    expect(controller.isLoading, false);

    verify(
      () => mockLogRepo.getLogEntries(
        'org1',
        limit: 10,
        startAfter: any(named: 'startAfter'),
        requestIDs: any(named: 'requestIDs'),
      ),
    ).called(1);
  });

  test('RequestLogsController filters by requestID', () async {
    when(
      () => mockLogRepo.getLogEntries(
        any(),
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: {'req1'},
      ),
    ).thenAnswer((_) => Stream.value([]));

    when(
      () => mockBookingService.decorateLogs(any(), any()),
    ).thenAnswer((_) => Stream.value([]));

    final controller = RequestLogsController(
      logRepo: mockLogRepo,
      bookingService: mockBookingService,
      orgID: 'org1',
      requestID: 'req1',
    );

    await Future.delayed(Duration.zero);
    expect(controller.isLoading, false);

    verify(
      () => mockLogRepo.getLogEntries(
        'org1',
        limit: any(named: 'limit'),
        startAfter: any(named: 'startAfter'),
        requestIDs: {'req1'},
      ),
    ).called(1);
  });
}
