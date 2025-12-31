import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';
import 'package:room_booker/ui/widgets/booking_list/conflicting_bookings.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

import 'booking_lists_test.dart'; // Reuse mocks

void main() {
  late MockBookingService mockBookingService;
  late MockLogRepo mockLogRepo;
  late MockRoomState mockRoomState;
  late MockBookingFilterViewModel mockFilterViewModel;

  final orgID = 'org1';
  final room = Room(name: 'Room A', id: 'room1');
  final request1 = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now(),
    eventEndTime: DateTime.now().add(Duration(hours: 1)),
    status: RequestStatus.confirmed,
  );
  final request2 = Request(
    id: 'req2',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now().add(Duration(minutes: 30)),
    eventEndTime: DateTime.now().add(Duration(hours: 1, minutes: 30)),
    status: RequestStatus.confirmed,
  );
  final requestDetails = PrivateRequestDetails(
    id: 'req1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '1234567890',
    eventName: 'Meeting 1',
  );
  final requestDetails2 = PrivateRequestDetails(
    id: 'req2',
    name: 'Jane Doe',
    email: 'jane@example.com',
    phone: '0987654321',
    eventName: 'Meeting 2',
  );

  setUp(() {
    mockBookingService = MockBookingService();
    mockLogRepo = MockLogRepo();
    mockRoomState = MockRoomState();
    mockFilterViewModel = MockBookingFilterViewModel();

    when(() => mockRoomState.enabledValues()).thenReturn({room});
    when(() => mockRoomState.color(any())).thenReturn(Colors.blue);
    when(() => mockFilterViewModel.searchQuery).thenReturn('');
    when(() => mockFilterViewModel.addListener(any())).thenReturn(null);
    when(() => mockFilterViewModel.removeListener(any())).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            Provider<BookingService>.value(value: mockBookingService),
            ChangeNotifierProvider<LogRepo>.value(value: mockLogRepo),
            ChangeNotifierProvider<RoomState>.value(value: mockRoomState),
            ChangeNotifierProvider<BookingFilterViewModel>.value(
              value: mockFilterViewModel,
            ),
          ],
          child: ConflictingBookings(orgID: orgID, service: mockBookingService),
        ),
      ),
    );
  }

  testWidgets('displays conflicting bookings', (WidgetTester tester) async {
    when(
      () => mockBookingService.findOverlappingBookings(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
      ),
    ).thenAnswer((_) => Stream.value([OverlapPair(request1, request2)]));

    // Need to mock getting details for these requests as BookingList uses BookingListViewModel which fetches details
    when(
      () => mockBookingService.getRequestDetails(orgID, request1.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));
    when(
      () => mockBookingService.getRequestDetails(orgID, request2.id!),
    ).thenAnswer((_) => Stream.value(requestDetails2));
    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Meeting 1 for John Doe'), findsOneWidget);
    expect(find.text('Meeting 2 for Jane Doe'), findsOneWidget);
  });

  testWidgets('displays empty text when no conflicts', (
    WidgetTester tester,
  ) async {
    when(
      () => mockBookingService.findOverlappingBookings(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('No conflicting bookings'), findsOneWidget);
  });
}
