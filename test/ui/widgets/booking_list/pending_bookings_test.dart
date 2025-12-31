import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';
import 'package:room_booker/ui/widgets/booking_list/pending_bookings.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:auto_route/auto_route.dart';

import 'booking_lists_test.dart';

class MockStackRouter extends Mock implements StackRouter {}

void main() {
  late MockBookingService mockBookingService;
  late MockLogRepo mockLogRepo;
  late MockRoomState mockRoomState;
  late MockBookingFilterViewModel mockFilterViewModel;
  late MockStackRouter mockStackRouter;

  final orgID = 'org1';
  final room = Room(name: 'Room A', id: 'room1');
  final request = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now(),
    eventEndTime: DateTime.now().add(Duration(hours: 1)),
    status: RequestStatus.pending,
  );
  final requestDetails = PrivateRequestDetails(
    id: 'req1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '1234567890',
    eventName: 'Meeting',
  );

  setUp(() {
    mockBookingService = MockBookingService();
    mockLogRepo = MockLogRepo();
    mockRoomState = MockRoomState();
    mockFilterViewModel = MockBookingFilterViewModel();
    mockStackRouter = MockStackRouter();

    when(() => mockRoomState.enabledValues()).thenReturn({room});
    when(() => mockRoomState.color(any())).thenReturn(Colors.blue);
    when(() => mockFilterViewModel.searchQuery).thenReturn('');
    when(() => mockFilterViewModel.addListener(any())).thenReturn(null);
    when(() => mockFilterViewModel.removeListener(any())).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: StackRouterScope(
        controller: mockStackRouter,
        stateHash: 0,
        child: Scaffold(
          body: MultiProvider(
            providers: [
              Provider<BookingService>.value(value: mockBookingService),
              ChangeNotifierProvider<LogRepo>.value(value: mockLogRepo),
              ChangeNotifierProvider<RoomState>.value(value: mockRoomState),
              ChangeNotifierProvider<BookingFilterViewModel>.value(
                value: mockFilterViewModel,
              ),
            ],
            child: PendingBookings(orgID: orgID, service: mockBookingService),
          ),
        ),
      ),
    );
  }

  testWidgets('displays pending booking', (WidgetTester tester) async {
    when(
      () => mockBookingService.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
        includeStatuses: {RequestStatus.pending},
      ),
    ).thenAnswer((_) => Stream.value([request]));

    when(
      () => mockBookingService.getRequestDetails(orgID, request.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));
    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Meeting for John Doe'), findsOneWidget);
  });

  testWidgets('approve action calls repo', (WidgetTester tester) async {
    when(
      () => mockBookingService.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
        includeStatuses: {RequestStatus.pending},
      ),
    ).thenAnswer((_) => Stream.value([request]));

    when(
      () => mockBookingService.getRequestDetails(orgID, request.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));
    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockBookingService.confirmRequest(orgID, request.id!),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.check_circle));

    verify(
      () => mockBookingService.confirmRequest(orgID, request.id!),
    ).called(1);
  });
}
