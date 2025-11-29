import 'dart:async';

import 'package:flutter/material.dart';
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
    when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
    when(() => mockOrganization.id).thenReturn('org_id');
    when(
      () => mockBookingRepo.listRequests(
        orgID: any(named: 'orgID'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        includeStatuses: any(named: 'includeStatuses'),
      ),
    ).thenAnswer((_) => Stream.value([]));
    when(() => mockBookingRepo.getRequestDetails(any(), any())).thenAnswer(
      (_) => Stream.value(
        PrivateRequestDetails(
          id: 'detail_id',
          eventName: "Fake Event",
          name: "Some name",
          email: "someone@somewhere.com",
          phone: "1234",
        ),
      ),
    );
    when(
      () => mockBookingRepo.listBlackoutWindows(any(), any(), any()),
    ).thenAnswer((_) => Stream.value([]));
    when(
      () => mockRoomState.getRoom(any()),
    ).thenReturn(Room(id: 'room_id', name: 'Test Room', colorHex: '#FF0000'));
    when(() => mockRoomState.color(any())).thenReturn(Colors.red);

    viewModel = CalendarViewModel(
      bookingRepo: mockBookingRepo,
      orgState: mockOrgState,
      roomState: mockRoomState,
    );
  });

  group('Data Transformation', () {
    test(
      'private bookings are filtered when includePrivateBookings is false',
      () async {
        final List<Request> requests = [
          Request(
            id: 'req_1',
            roomID: 'room_1',
            eventStartTime: DateTime.now(),
            eventEndTime: DateTime.now().add(Duration(hours: 1)),
            status: RequestStatus.confirmed,
            roomName: 'Test Room',
          ),
        ];
        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
          ),
        ).thenAnswer((_) => Stream.value(requests));

        viewModel = CalendarViewModel(
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          roomState: mockRoomState,
          includePrivateBookings: false,
        );

        await expectLater(
          viewModel.calendarViewState(),
          emitsThrough(
            isA<CalendarViewState>().having(
              (state) => state.dataSource.appointments!.length,
              'appointments.length',
              0,
            ),
          ),
        );
      },
    );

    test('room name is appended when appendRoomName is true', () async {
      final List<Request> requests = [
        Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: DateTime.now(),
          eventEndTime: DateTime.now().add(Duration(hours: 1)),
          publicName: 'Public Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room',
        ),
      ];
      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value(requests));

      when(() => mockBookingRepo.getRequestDetails(any(), any())).thenAnswer(
        (_) => Stream.value(
          PrivateRequestDetails(
            id: 'req_1',
            eventName: "Fake Event",
            name: "Some name",
            email: "someone@somewhere.com",
            phone: "1234",
          ),
        ),
      );

      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
        appendRoomName: true,
      );

      await expectLater(
        viewModel.calendarViewState(),
        emitsThrough(
          isA<CalendarViewState>().having(
            (state) =>
                (state.dataSource.appointments!.first as Appointment).subject,
            'first appointment subject',
            'Public Event (Test Room)',
          ),
        ),
      );
    });
  });

  group('User Interaction', () {
    test('handleTap on calendar cell emits date on dateTapStream', () async {
      final date = DateTime.now();

      bool called = false;
      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
      );
      viewModel.dateTapStream.listen((details) {
        expect(details.date, date);
        called = true;
      });

      viewModel.handleTap(
        CalendarTapDetails(null, date, CalendarElement.calendarCell, null),
      );

      await Future.delayed(Duration(milliseconds: 100));

      expect(called, isTrue);
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
        roomName: 'Test Room',
      );
      final dropTime = now.add(Duration(hours: 2));

      when(
        () => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeStatuses: any(named: 'includeStatuses'),
        ),
      ).thenAnswer((_) => Stream.value([request]));

      Completer<DragDetails> dragDetails = Completer();
      viewModel = CalendarViewModel(
        bookingRepo: mockBookingRepo,
        orgState: mockOrgState,
        roomState: mockRoomState,
        onDragEnd: (details) {
          dragDetails.complete(details);
        },
      );

      viewModel.controller.displayDate = now;
      await Future.delayed(Duration(seconds: 1));
      final state = await viewModel
          .calendarViewState()
          .where((state) => state.dataSource.appointments?.isNotEmpty ?? false)
          .first;
      final appointment = state.dataSource.appointments!.first as Appointment;

      final details = AppointmentDragEndDetails(
        appointment,
        null,
        null,
        dropTime,
      );
      viewModel.handleDragEnd(details);

      var gotDetails = await dragDetails.future;

      expect(
        gotDetails,
        isA<DragDetails>()
            .having((d) => d.request, 'request', request)
            .having((d) => d.dropTime, 'dropTime', dropTime),
      );
    });

    test('handleResizeEnd emits resize details on resizeEventStream', () async {
      final appointment = Appointment(
        subject: 'Public Event',
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(hours: 1)),
      );
      final startTime = DateTime.now().add(Duration(minutes: 30));
      final endTime = DateTime.now().add(Duration(hours: 1, minutes: 30));

      final details = AppointmentResizeEndDetails(
        appointment,
        null,
        startTime,
        endTime,
      );

      var completer = Completer<ResizeDetails>();
      var viewModel = CalendarViewModel(
        orgState: mockOrgState,
        bookingRepo: mockBookingRepo,
        roomState: mockRoomState,
        onResizeEnd: (details) => completer.complete(details),
      );
      viewModel.handleResizeEnd(details);

      var gotDetails = await completer.future;

      expect(
        gotDetails,
        isA<ResizeDetails>()
            .having((d) => d.appointment, 'appointment', appointment)
            .having((d) => d.startTime, 'startTime', startTime)
            .having((d) => d.endTime, 'endTime', endTime),
      );
    });

    test(
      'handleTap on non-existent appointment does not emit on requestTapStream',
      () async {
        final nonExistentAppointment = Appointment(
          subject: 'Non Existent',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(Duration(hours: 1)),
        );

        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
          ),
        ).thenAnswer((_) => Stream.value([]));

        var eventFired = false;
        viewModel = CalendarViewModel(
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          roomState: mockRoomState,
        );
        viewModel.dateTapStream.listen((_) {
          eventFired = true;
        });

        viewModel.handleTap(
          CalendarTapDetails(
            [nonExistentAppointment],
            DateTime.now(),
            CalendarElement.appointment,
            null,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(eventFired, isFalse);
      },
    );

    test(
      'handleDragEnd emits drag details even if droppingTime is in a blackout window',
      () async {
        final now = DateTime(2025, 1, 1, 12, 0);
        final request = Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: now,
          eventEndTime: now.add(Duration(hours: 1)),
          publicName: 'Public Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room',
        );
        final dropTime = now.add(Duration(hours: 2));

        final blackoutWindow = BlackoutWindow(
          start: dropTime.subtract(Duration(minutes: 30)),
          end: dropTime.add(Duration(minutes: 30)),
          reason: 'Maintenance',
        );
        when(
          () => mockBookingRepo.listBlackoutWindows(any(), any(), any()),
        ).thenAnswer((_) => Stream.value([blackoutWindow]));

        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
          ),
        ).thenAnswer((_) => Stream.value([request]));

        Completer<DragDetails> dragDetails = Completer();
        viewModel = CalendarViewModel(
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          roomState: mockRoomState,
          onDragEnd: (details) => dragDetails.complete(details),
        );

        viewModel.controller.displayDate = now;
        await Future.delayed(Duration(seconds: 1));
        final state = await viewModel
            .calendarViewState()
            .where(
              (state) => state.dataSource.appointments?.isNotEmpty ?? false,
            )
            .first;
        final appointment = state.dataSource.appointments!.first as Appointment;

        final details = AppointmentDragEndDetails(
          appointment,
          null,
          null,
          dropTime,
        );
        viewModel.handleDragEnd(details);

        var gotDetails = await dragDetails.future;
        expect(
          gotDetails,
          isA<DragDetails>()
              .having((d) => d.request, 'request', request)
              .having((d) => d.dropTime, 'dropTime', dropTime),
        );
      },
    );
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

      final endOfWeek = startOfWeek.add(Duration(days: 7));
      expect(viewModel.endOfView.year, endOfWeek.year);
      expect(viewModel.endOfView.month, endOfWeek.month);
      expect(viewModel.endOfView.day, 9);
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

  group('Recurring Events', () {
    test(
      'daily recurring event generates correct number of appointments',
      () async {
        final start = DateTime(2025, 1, 1, 12, 0);
        final end = start.add(Duration(days: 6)); // Cover 7 days
        final recurrancePattern = RecurrancePattern(
          frequency: Frequency.daily,
          period: 1,
          end: end,
        );
        final request = Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: start,
          eventEndTime: start.add(Duration(hours: 1)),
          publicName: 'Daily Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room',
          recurrancePattern: recurrancePattern,
        );

        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
          ),
        ).thenAnswer((_) => Stream.value([request]));

        viewModel = CalendarViewModel(
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          roomState: mockRoomState,
        );

        viewModel.controller.view = CalendarView.week; // Set to week view
        viewModel.controller.displayDate = start.add(
          Duration(days: 3),
        ); // Middle of the week
        await Future.delayed(Duration(seconds: 1));

        await expectLater(
          viewModel.calendarViewState(),
          emitsThrough(
            isA<CalendarViewState>().having(
              (state) => state.dataSource.appointments!.length,
              'appointments.length',
              5, // Expect 5 appointments for a week
            ),
          ),
        );
      },
    );

    test(
      'weekly recurring event generates correct number of appointments',
      () async {
        final start = DateTime(2025, 1, 1, 12, 0); // Wednesday
        final end = start.add(Duration(days: 27)); // Cover 4 weeks
        final recurrancePattern = RecurrancePattern(
          frequency: Frequency.weekly,
          period: 1,
          weekday: {Weekday.wednesday},
          end: end,
        );
        final request = Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: start,
          eventEndTime: start.add(Duration(hours: 1)),
          publicName: 'Weekly Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room',
          recurrancePattern: recurrancePattern,
        );

        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
          ),
        ).thenAnswer((_) => Stream.value([request]));

        viewModel = CalendarViewModel(
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          roomState: mockRoomState,
        );

        viewModel.controller.view = CalendarView.month; // Set to month view
        viewModel.controller.displayDate = start.add(
          Duration(days: 15),
        ); // Middle of the month
        await Future.delayed(Duration(seconds: 1));

        await expectLater(
          viewModel.calendarViewState(),
          emitsThrough(
            isA<CalendarViewState>().having(
              (state) => state.dataSource.appointments!.length,
              'appointments.length',
              4, // Expect 4 appointments for 4 weeks
            ),
          ),
        );
      },
    );

    test(
      'monthly recurring event generates correct number of appointments',
      () async {
        final start = DateTime(2025, 1, 1, 12, 0); // First Wednesday of January
        final recurrancePattern = RecurrancePattern.monthlyOnNth(
          1,
          Weekday.wednesday,
        );
        final request = Request(
          id: 'req_1',
          roomID: 'room_1',
          eventStartTime: start,
          eventEndTime: start.add(Duration(hours: 1)),
          publicName: 'Monthly Event',
          status: RequestStatus.confirmed,
          roomName: 'Test Room',
          recurrancePattern: recurrancePattern,
        );

        when(
          () => mockBookingRepo.listRequests(
            orgID: any(named: 'orgID'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
            includeStatuses: any(named: 'includeStatuses'),
          ),
        ).thenAnswer((_) => Stream.value([request]));

        viewModel = CalendarViewModel(
          bookingRepo: mockBookingRepo,
          orgState: mockOrgState,
          roomState: mockRoomState,
        );

        viewModel.controller.view = CalendarView.month; // Set to month view
        viewModel.controller.displayDate = start.add(
          Duration(days: 15),
        ); // Middle of the month
        await Future.delayed(Duration(seconds: 1));

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
      },
    );
  });
}
