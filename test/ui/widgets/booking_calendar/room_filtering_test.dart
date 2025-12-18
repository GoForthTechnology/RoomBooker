import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

// Mock classes
class MockBookingRepo extends Mock implements BookingRepo {}

class MockOrgState extends Mock implements OrgState {}

class MockOrganization extends Mock implements Organization {}

class FakeOrganization extends Fake implements Organization {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CalendarViewModel viewModel;
  late MockBookingRepo mockBookingRepo;
  late MockOrgState mockOrgState;
  late RoomState roomState;
  late MockOrganization mockOrganization;

  setUpAll(() {
    registerFallbackValue(FakeOrganization());
  });

  setUp(() {
    mockBookingRepo = MockBookingRepo();
    mockOrgState = MockOrgState();
    mockOrganization = MockOrganization();

    // Default stubs
    when(() => mockOrgState.org).thenReturn(mockOrganization);
    when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
    when(() => mockOrganization.id).thenReturn('org_id');
    when(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockBookingRepo.getRequestDetails(any(), any()),
    ).thenAnswer((_) => Stream.value(null));
    when(
      () => mockBookingRepo.listBlackoutWindows(any(), any(), any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  test('Appointments for unchecked rooms are hidden', () async {
    final room1 = Room(id: 'room_1', name: 'Room 1', colorHex: '#FF0000');
    final room2 = Room(id: 'room_2', name: 'Room 2', colorHex: '#00FF00');

    // Both rooms active initially
    roomState = RoomState([room1, room2], {room1, room2}, null);

    final request1 = Request(
      id: 'req_1',
      roomID: 'room_1',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(Duration(hours: 1)),
      publicName: 'Event Room 1',
      status: RequestStatus.confirmed,
      roomName: 'Room 1',
    );

    final request2 = Request(
      id: 'req_2',
      roomID: 'room_2',
      eventStartTime: DateTime.now(),
      eventEndTime: DateTime.now().add(Duration(hours: 1)),
      publicName: 'Event Room 2',
      status: RequestStatus.confirmed,
      roomName: 'Room 2',
    );

    when(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).thenAnswer((_) => Stream.value([request1, request2]));

    viewModel = CalendarViewModel(
      bookingRepo: mockBookingRepo,
      orgState: mockOrgState,
      roomState: roomState,
    );

    // Initial state: both events should be visible
    await expectLater(
      viewModel.calendarViewState(),
      emitsThrough(
        isA<CalendarViewState>().having(
          (state) => state.dataSource.appointments!.length,
          'appointments.length',
          2,
        ),
      ),
    );

    // Uncheck Room 1
    roomState.toggleRoom(room1);

    // Expecting to see only 1 appointment (for Room 2)
    // We expect a new emission from calendarViewState.
    // However, since we can't easily "await" the next emission on the same stream subscription
    // inside the test without setting it up beforehand, we can just listen again or use a stream queue.
    // But verify logic: if CalendarViewModel doesn't listen to roomState, this will timeout or fail.

    // We need to re-subscribe or continue listening?
    // Actually, viewModel.calendarViewState() returns a NEW stream each time it's called?
    // Let's check implementation:
    // Stream<CalendarViewState> calendarViewState() {
    //   return _viewStateStream(_bookingRepo, _orgState, _roomState);
    // }
    // Yes, it creates a new stream. But the underlying subjects are the same.
    // If we call calendarViewState() again, it should emit the CURRENT state.

    await expectLater(
      viewModel.calendarViewState(),
      emitsThrough(
        isA<CalendarViewState>().having(
          (state) => state.dataSource.appointments!.length,
          'appointments.length',
          1,
        ),
      ),
    );
  });
}
