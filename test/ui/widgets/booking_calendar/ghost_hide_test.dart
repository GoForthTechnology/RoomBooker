import 'dart:async';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/booking_service.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockOrgState extends Mock implements OrgState {}
class MockRoomState extends Mock implements RoomState {}
class MockBookingService extends Mock implements BookingService {}
class MockLoggingService extends Mock implements LoggingService {}

void main() {
  late MockOrgState mockOrgState;
  late MockRoomState mockRoomState;
  late MockBookingService mockBookingService;
  late MockLoggingService mockLoggingService;

  setUpAll(() {
    registerFallbackValue(Organization(
      name: 'Fallback',
      ownerID: 'fallback',
      acceptingAdminRequests: true,
    ));
  });

  setUp(() {
    mockOrgState = MockOrgState();
    mockRoomState = MockRoomState();
    mockBookingService = MockBookingService();
    mockLoggingService = MockLoggingService();

    when(() => mockOrgState.org).thenReturn(Organization(
      id: 'org1',
      name: 'Org 1',
      ownerID: 'owner1',
      acceptingAdminRequests: true,
    ));
    when(() => mockOrgState.currentUserIsAdmin).thenReturn(true);
    when(() => mockRoomState.color(any())).thenReturn(const Color(0xFF000000));
    when(() => mockRoomState.isEnabled(any())).thenReturn(true);
    when(() => mockRoomState.enabledValues()).thenReturn({});
    when(() => mockBookingService.listBlackoutWindows(any(), any(), any()))
        .thenAnswer((_) => Stream.value([]));
  });

  test('CalendarViewModel hides original appointment when editing', () async {
    final startTime = DateTime(2026, 5, 10, 10);
    final existingRequest = Request(
      id: 'req1',
      eventStartTime: startTime,
      eventEndTime: startTime.add(const Duration(hours: 1)),
      roomID: 'room1',
      roomName: 'Room 1',
      status: RequestStatus.confirmed,
    );

    // Mock initial list of requests containing the existing request
    when(() => mockBookingService.getRequestsStream(
          orgID: any(named: 'orgID'),
          isAdmin: any(named: 'isAdmin'),
          start: any(named: 'start'),
          end: any(named: 'end'),
        )).thenAnswer((_) => Stream.value([existingRequest]));

    final viewModel = CalendarViewModel(
      orgState: mockOrgState,
      roomState: mockRoomState,
      bookingService: mockBookingService,
      loggingService: mockLoggingService,
      includePrivateBookings: true,
    );

    // Wait for initial state (skip the startWith empty state)
    var state = await viewModel.calendarViewState().where((s) => s.dataSource.appointments!.isNotEmpty).first;
    expect(state.dataSource.appointments!.length, 1);
    expect((state.dataSource.appointments!.first as Appointment).startTime, startTime);

    // Now signal that we are editing this request
    final initialRequestController = StreamController<Request?>.broadcast();
    viewModel.registerInitialRequestStream(initialRequestController.stream);
    
    initialRequestController.add(existingRequest);
    
    // Wait for update (should now be empty)
    state = await viewModel.calendarViewState().where((s) => s.dataSource.appointments!.isEmpty).first;
    
    // The original should now be HIDDEN
    expect(state.dataSource.appointments!.length, 0, reason: 'Original request should be hidden during edit');

    // If we move the event (Ghost appointment), only the Ghost should be visible
    final ghostRequest = existingRequest.copyWith(
      eventStartTime: startTime.add(const Duration(days: 1)),
      eventEndTime: startTime.add(const Duration(days: 1, hours: 1)),
    );
    
    final ghostController = StreamController<(Request?, PrivateRequestDetails?)>.broadcast();
    viewModel.registerNewAppointmentStream(ghostController.stream);
    
    ghostController.add((ghostRequest, null));
    
    await Future.delayed(Duration.zero);
    state = await viewModel.calendarViewState().first;

    expect(state.dataSource.appointments!.length, 1, reason: 'Only the ghost appointment should be visible');
    expect((state.dataSource.appointments!.first as Appointment).startTime, ghostRequest.eventStartTime);

    // Clean up
    viewModel.dispose();
    initialRequestController.close();
    ghostController.close();
  });
}
