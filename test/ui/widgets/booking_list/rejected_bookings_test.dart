import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/ui/widgets/booking_list/booking_filter_view_model.dart';
import 'package:room_booker/ui/widgets/booking_list/rejected_bookings.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

import 'booking_lists_test.dart';

void main() {
  late MockBookingRepo mockBookingRepo;
  late MockLogRepo mockLogRepo;
  late MockRoomState mockRoomState;
  late MockBookingFilterViewModel mockFilterViewModel;

  final orgID = 'org1';
  final room = Room(name: 'Room A', id: 'room1');
  final request = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room A',
    eventStartTime: DateTime.now(),
    eventEndTime: DateTime.now().add(Duration(hours: 1)),
    status: RequestStatus.denied,
  );
    final requestDetails = PrivateRequestDetails(
    id: 'req1',
    name: 'John Doe',
    email: 'john@example.com',
    phone: '1234567890',
    eventName: 'Meeting',
  );


  setUp(() {
    mockBookingRepo = MockBookingRepo();
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
            ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
            ChangeNotifierProvider<LogRepo>.value(value: mockLogRepo),
            ChangeNotifierProvider<RoomState>.value(value: mockRoomState),
            ChangeNotifierProvider<BookingFilterViewModel>.value(
                value: mockFilterViewModel),
          ],
          child: RejectedBookings(
            orgID: orgID,
            repo: mockBookingRepo,
          ),
        ),
      ),
    );
  }

  testWidgets('displays rejected booking', (WidgetTester tester) async {
    when(() => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: {RequestStatus.denied},
        )).thenAnswer((_) => Stream.value([request]));
    
    when(() => mockBookingRepo.getRequestDetails(orgID, request.id!))
        .thenAnswer((_) => Stream.value(requestDetails));
    when(() => mockLogRepo.getLogEntries(orgID, requestIDs: any(named: 'requestIDs')))
        .thenAnswer((_) => Stream.value([]));


    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Meeting for John Doe'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_return), findsOneWidget);
  });

  testWidgets('revisit action calls repo', (WidgetTester tester) async {
    when(() => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
          includeStatuses: {RequestStatus.denied},
        )).thenAnswer((_) => Stream.value([request]));
    
    when(() => mockBookingRepo.getRequestDetails(orgID, request.id!))
        .thenAnswer((_) => Stream.value(requestDetails));
    when(() => mockLogRepo.getLogEntries(orgID, requestIDs: any(named: 'requestIDs')))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockBookingRepo.revisitBookingRequest(orgID, request))
        .thenAnswer((_) async {});

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    
    await tester.tap(find.byIcon(Icons.assignment_return));
    
    verify(() => mockBookingRepo.revisitBookingRequest(orgID, request)).called(1);
  });
}
