import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/blackout_window.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Mock classes
class MockBookingRepo extends Mock implements BookingRepo {}

class MockOrgState extends Mock implements OrgState {}

class MockRoomState extends Mock implements RoomState {}

class MockOrganization extends Mock implements Organization {}

class FakeOrganization extends Fake implements Organization {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CalendarViewModel viewModel;
  late MockBookingRepo mockBookingRepo;
  late MockOrgState mockOrgState;
  late MockRoomState mockRoomState;
  late MockOrganization mockOrganization;

  setUpAll(() {
    registerFallbackValue(FakeOrganization());
  });

  setUp(() {
    mockBookingRepo = MockBookingRepo();
    mockOrgState = MockOrgState();
    mockRoomState = MockRoomState();
    mockOrganization = MockOrganization();

    // Default stubs
    when(() => mockOrgState.org).thenReturn(mockOrganization);
    when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
    when(() => mockOrganization.id).thenReturn('org_id');
    when(() => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'))).thenAnswer((_) => Stream.value([]));
    when(() => mockBookingRepo.getRequestDetails(any(), any())).thenAnswer(
        (_) => Stream.value(PrivateRequestDetails(
            id: 'detail_id',
            eventName: "Fake Event",
            name: "Some name",
            email: "someone@somewhere.com",
            phone: "1234")));
    when(() => mockBookingRepo.listBlackoutWindows(any(), any(), any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockRoomState.getRoom(any())).thenReturn(Room(
      id: 'room_id',
      name: 'Test Room',
      colorHex: '#FF0000',
    ));

    viewModel = CalendarViewModel(
      bookingRepo: mockBookingRepo,
      orgState: mockOrgState,
      roomState: mockRoomState,
    );
  });

  group('CalendarViewModel', () {
    test('initial state is correct', () async {
      final completer = Completer<CalendarViewState>();
      viewModel.calendarViewState().listen((state) {
        completer.complete(state);
      });
      final state = await completer.future;
      expect(state, isA<CalendarViewState>());
    });

    test('loads and converts appointments', () async {
      final List<Request> requests = [
        Request(
            id: 'req_1',
            roomID: 'room_1',
            eventStartTime: DateTime.now(),
            eventEndTime: DateTime.now().add(Duration(hours: 1)),
            publicName: 'Public Event',
            status: RequestStatus.confirmed,
            roomName: 'Test Room')
      ];
      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value(requests));

      viewModel.controller.displayDate = DateTime.now();

      await expectLater(
        viewModel.calendarViewState(),
        emits(isA<CalendarViewState>()
          ..having(
            (state) => state.dataSource.appointments!.length,
            'appointments.length',
            requests.length,
          )
          ..having(
            (state) =>
                (state.dataSource.appointments!.first as Appointment).subject,
            'first appointment subject',
            'Public Event',
          )),
      );
    });
  });

  group('Data Transformation', () {
    test('private bookings are filtered when includePrivateBookings is false', () async {
      final List<Request> requests = [
        Request(
            id: 'req_1',
            roomID: 'room_1',
            eventStartTime: DateTime.now(),
            eventEndTime: DateTime.now().add(Duration(hours: 1)),
            status: RequestStatus.confirmed,
            roomName: 'Test Room')
      ];
      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value(requests));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
        includePrivateBookings: false,
      );

      await expectLater(
        viewModel.calendarViewState(),
        emits(isA<CalendarViewState>()
          ..having(
            (state) => state.dataSource.appointments!.length,
            'appointments.length',
            0,
          )),
      );
    });

    test('private bookings are included when includePrivateBookings is true', () async {
      final List<Request> requests = [
        Request(
            id: 'req_1',
            roomID: 'room_1',
            eventStartTime: DateTime.now(),
            eventEndTime: DateTime.now().add(Duration(hours: 1)),
            status: RequestStatus.confirmed,
            roomName: 'Test Room')
      ];
      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value(requests));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
        includePrivateBookings: true,
      );

      await expectLater(
        viewModel.calendarViewState(),
        emits(isA<CalendarViewState>()
          ..having(
            (state) => state.dataSource.appointments!.length,
            'appointments.length',
            1,
          )
          ..having(
            (state) =>
                (state.dataSource.appointments!.first as Appointment).subject,
            'first appointment subject',
            'Fake Event (Private)',
          )),
      );
    });

    test('getRequestDetails is called for admin users', () async {
      final List<Request> requests = [
        Request(
            id: 'req_1',
            roomID: 'room_1',
            eventStartTime: DateTime.now(),
            eventEndTime: DateTime.now().add(Duration(hours: 1)),
            status: RequestStatus.confirmed,
            roomName: 'Test Room')
      ];
      when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value(requests));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
        includePrivateBookings: true,
      );

      await viewModel.calendarViewState().first;

      verify(() => mockBookingRepo.getRequestDetails(any(), 'req_1')).called(1);
    });

    test('room name is appended when appendRoomName is true', () async {
      final List<Request> requests = [
        Request(
            id: 'req_1',
            roomID: 'room_1',
            eventStartTime: DateTime.now(),
            eventEndTime: DateTime.now().add(Duration(hours: 1)),
            publicName: 'Public Event',
            status: RequestStatus.confirmed,
            roomName: 'Test Room')
      ];
      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value(requests));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
        appendRoomName: true,
      );

      await expectLater(
        viewModel.calendarViewState(),
        emits(isA<CalendarViewState>()
          ..having(
            (state) =>
                (state.dataSource.appointments!.first as Appointment).subject,
            'first appointment subject',
            'Public Event (Test Room)',
          )),
      );
    });
  });

  group('User Interaction', () {
    test('handleTap on appointment emits request on requestTapStream', () async {
      final now = DateTime(2025, 1, 1, 12, 0);
      final request = Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: now,
          eventEndTime: now.add(Duration(hours: 1)),
          publicName: 'Public Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room');

      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value([request]));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
      );

      viewModel.controller.displayDate = now;
      await Future.delayed(Duration(seconds: 1));
      final state = await viewModel.calendarViewState().first;
      final appointment = state.dataSource.appointments!.first as Appointment;

      viewModel.handleTap(CalendarTapDetails([appointment], now, CalendarElement.appointment, null));
    });

    test('handleTap on calendar cell emits date on dateTapStream', () async {
      final date = DateTime.now();

      expect(viewModel.dateTapStream, emits(date));

      viewModel.handleTap(CalendarTapDetails(null, date, CalendarElement.calendarCell, null));
    });

    test('handleDragEnd emits drag details on dragEventStream', () async {
      final now = DateTime(2025, 1, 1, 12, 0);
      final request = Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: now,
          eventEndTime: now.add(Duration(hours: 1)),
          publicName: 'Public Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room');
      final dropTime = now.add(Duration(hours: 2));

      when(() => mockBookingRepo.listRequests(
              orgID: any(named: 'orgID'),
              startTime: any(named: 'startTime'),
              endTime: any(named: 'endTime')))
          .thenAnswer((_) => Stream.value([request]));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
      );

      expect(viewModel.dragEventStream, emits(isA<DragDetails>()
        ..having((d) => d.request, 'request', request)
        ..having((d) => d.dropTime, 'dropTime', dropTime)));

      viewModel.controller.displayDate = now;
      await Future.delayed(Duration(seconds: 1));
      final state = await viewModel.calendarViewState().first;
      final appointment = state.dataSource.appointments!.first as Appointment;

      final details = AppointmentDragEndDetails(appointment, null, null, dropTime);
      viewModel.handleDragEnd(details);
    });

    test('handleResizeEnd emits resize details on resizeEventStream', () async {
      final appointment = Appointment(subject: 'Public Event', startTime: DateTime.now(), endTime: DateTime.now().add(Duration(hours: 1)));
      final startTime = DateTime.now().add(Duration(minutes: 30));
      final endTime = DateTime.now().add(Duration(hours: 1, minutes: 30));

      expect(viewModel.resizeEventStream, emits(isA<ResizeDetails>()
        ..having((d) => d.appointment, 'appointment', appointment)
        ..having((d) => d.startTime, 'startTime', startTime)
        ..having((d) => d.endTime, 'endTime', endTime)));

      final details = AppointmentResizeEndDetails(appointment, null, startTime, endTime);
      viewModel.handleResizeEnd(details);
    });
  });

  group('View and Date Range', () {
    test('startOfView and endOfView are correct for day view', () {
      viewModel.controller.view = CalendarView.day;
      final now = DateTime.now();
      viewModel.controller.displayDate = now;

      expect(viewModel.startOfView.year, now.year);
      expect(viewModel.startOfView.month, now.month);
      expect(viewModel.startOfView.day, now.day);

      final endOfView = now.add(Duration(days: 1));
      expect(viewModel.endOfView.year, endOfView.year);
      expect(viewModel.endOfView.month, endOfView.month);
      expect(viewModel.endOfView.day, endOfView.day);
    });

    test('startOfView and endOfView are correct for week view', () {
      viewModel.controller.view = CalendarView.week;
      final now = DateTime(2025, 11, 5); // A Wednesday
      viewModel.controller.displayDate = now;

      final startOfWeek = DateTime(2025, 11, 2); // The preceding Sunday
      expect(viewModel.startOfView.year, startOfWeek.year);
      expect(viewModel.startOfView.month, startOfWeek.month);
      expect(viewModel.startOfView.day, startOfWeek.day);
    });

    test('startOfView and endOfView are correct for month view', () {
      viewModel.controller.view = CalendarView.month;
      final now = DateTime(2025, 11, 5);
      viewModel.controller.displayDate = now;

      final startOfMonthView = DateTime(2025, 10, 26);
      final endOfMonthView = DateTime(2025, 12, 6);
      expect(viewModel.startOfView, startOfMonthView);
      expect(viewModel.endOfView, endOfMonthView);
    });

    test('startOfView and endOfView are correct for schedule view', () {
      viewModel.controller.view = CalendarView.schedule;
      final now = DateTime.now();
      viewModel.controller.displayDate = now;

      expect(viewModel.startOfView, now);
      expect(viewModel.endOfView, now.add(Duration(days: 90)));
    });
  });

  group('Blackout Windows', () {
    test('blackout windows are converted to special regions', () async {
      final blackoutWindow = BlackoutWindow(
        start: DateTime.now(),
        end: DateTime.now().add(Duration(hours: 1)),
        reason: 'Maintenance',
      );
      when(() => mockBookingRepo.listBlackoutWindows(any(), any(), any()))
          .thenAnswer((_) => Stream.value([blackoutWindow]));

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
      );

      await expectLater(
        viewModel.calendarViewState(),
        emits(isA<CalendarViewState>()
          ..having(
            (state) => state.specialRegions.length,
            'specialRegions.length',
            1,
          )
          ..having(
            (state) => state.specialRegions.first.text,
            'specialRegions.first.text',
            'Maintenance',
          )),
      );
    });
  });
}
