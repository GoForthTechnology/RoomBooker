import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';
import 'package:room_booker/ui/widgets/booking_list/confirmed_bookings.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

import 'booking_lists_test.dart';

void main() {
  late MockBookingService mockBookingService;
  late MockLogRepo mockLogRepo;
  late MockRoomState mockRoomState;
  late MockBookingFilterViewModel mockFilterViewModel;

  final orgID = 'org1';
  final room = Room(name: 'Room A', id: 'room1');
  final oneOffRequest = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now(),
    eventEndTime: DateTime.now().add(Duration(hours: 1)),
    status: RequestStatus.confirmed,
  );
  final repeatingRequest = Request(
    id: 'req2',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now(),
    eventEndTime: DateTime.now().add(Duration(hours: 1)),
    status: RequestStatus.confirmed,
    recurrancePattern: RecurrancePattern.weekly(on: Weekday.monday),
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

    when(() => mockRoomState.enabledValues()).thenReturn({room});
    when(() => mockRoomState.color(any())).thenReturn(Colors.blue);
    when(() => mockFilterViewModel.searchQuery).thenReturn('');
    when(() => mockFilterViewModel.addListener(any())).thenReturn(null);
    when(() => mockFilterViewModel.removeListener(any())).thenReturn(null);
  });

  Widget createOneOffWidget() {
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
          child: ConfirmedOneOffBookings(
            orgID: orgID,
            service: mockBookingService,
          ),
        ),
      ),
    );
  }

  Widget createRepeatingWidget() {
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
          child: ConfirmedRepeatingBookings(
            orgID: orgID,
            service: mockBookingService,
          ),
        ),
      ),
    );
  }

  testWidgets('ConfirmedOneOffBookings displays only one-off bookings', (
    WidgetTester tester,
  ) async {
    when(
      () => mockBookingService.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
        includeStatuses: {RequestStatus.confirmed},
      ),
    ).thenAnswer((_) => Stream.value([oneOffRequest, repeatingRequest]));

    when(
      () => mockBookingService.getRequestDetails(orgID, oneOffRequest.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));
    // Repeating shouldn't even need details fetching if filtered out correctly by viewmodel but let's provide it to be safe/if logic fetches all then filters
    when(
      () => mockBookingService.getRequestDetails(orgID, repeatingRequest.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));

    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createOneOffWidget());
    await tester.pumpAndSettle();

    // Should see one-off, but not repeating (BookingListViewModel does client side filtering if passed)
    // Wait, ConfirmedOneOffBookings passes `requestFilter: (r) => !r.isRepeating()`.
    // BookingListViewModel applies this filter.
    // So we expect to see req1 but not req2.
    // BUT: Both have same details mock so same text. Let's verify count.

    expect(find.text('Meeting for John Doe'), findsOneWidget);
  });

  testWidgets('ConfirmedRepeatingBookings displays only repeating bookings', (
    WidgetTester tester,
  ) async {
    when(
      () => mockBookingService.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeRoomIDs: any(named: 'includeRoomIDs'),
        includeStatuses: {RequestStatus.confirmed},
      ),
    ).thenAnswer((_) => Stream.value([oneOffRequest, repeatingRequest]));

    when(
      () => mockBookingService.getRequestDetails(orgID, repeatingRequest.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));
    // One-off details
    when(
      () => mockBookingService.getRequestDetails(orgID, oneOffRequest.id!),
    ).thenAnswer((_) => Stream.value(requestDetails));

    when(
      () => mockLogRepo.getLogEntries(
        orgID,
        requestIDs: any(named: 'requestIDs'),
      ),
    ).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(createRepeatingWidget());
    await tester.pumpAndSettle();

    expect(find.text('Meeting for John Doe'), findsOneWidget);
  });
}
