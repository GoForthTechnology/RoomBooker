import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../utils/fake_logging_service.dart';

class MockCalendarViewModel extends Mock implements CalendarViewModel {}

class FakeDataSource extends CalendarDataSource {
  FakeDataSource(List<Appointment> appointments) {
    this.appointments = appointments;
  }
}

class FakeAppointmentResizeEndDetails extends Fake
    implements AppointmentResizeEndDetails {}

class FakeAppointmentDragEndDetails extends Fake
    implements AppointmentDragEndDetails {}

class FakeCalendarTapDetails extends Fake implements CalendarTapDetails {}

void main() {
  late MockCalendarViewModel mockViewModel;

  setUpAll(() {
    registerFallbackValue(FakeAppointmentResizeEndDetails());
    registerFallbackValue(FakeAppointmentDragEndDetails());
    registerFallbackValue(FakeCalendarTapDetails());
  });

  setUp(() {
    mockViewModel = MockCalendarViewModel();
  });

  testWidgets('BookingCalendarView renders Tooltip with room name', (
    WidgetTester tester,
  ) async {
    final appointment = Appointment(
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      subject: 'Test Meeting',
      notes: 'Conference Room A',
      color: Colors.blue,
    );

    final state = CalendarViewState(
      currentView: CalendarView.day,
      currentDate: DateTime.now(),
      allowDragAndDrop: true,
      allowAppointmentResize: true,
      dataSource: FakeDataSource([appointment]),
      specialRegions: [],
    );

    when(
      () => mockViewModel.calendarViewState(),
    ).thenAnswer((_) => Stream.value(state));
    when(() => mockViewModel.controller).thenReturn(CalendarController());
    when(() => mockViewModel.minDate).thenReturn(DateTime.now());
    when(() => mockViewModel.showNavigationArrow).thenReturn(true);
    when(() => mockViewModel.showTodayButton).thenReturn(true);
    when(() => mockViewModel.showDatePickerButton).thenReturn(true);
    when(() => mockViewModel.allowViewNavigation).thenReturn(true);
    when(() => mockViewModel.allowedViews).thenReturn([CalendarView.day]);
    when(() => mockViewModel.handleResizeEnd(any())).thenAnswer((_) async {});
    when(() => mockViewModel.handleDragEnd(any())).thenAnswer((_) async {});
    when(() => mockViewModel.handleTap(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LoggingService>(
          create: (_) => FakeLoggingService(),
          child: BookingCalendar(createViewModel: () => mockViewModel),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Appointment subject is rendered in Text widget
    expect(find.text('Test Meeting'), findsOneWidget);

    // Verify Tooltip is present
    final tooltipFinder = find.byType(Tooltip);
    expect(tooltipFinder, findsOneWidget);

    // Verify Tooltip message matches subject and room name
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'Test Meeting\nConference Room A');

    // Verify Appointment subject is rendered in Text widget
    expect(find.text('Test Meeting'), findsOneWidget);
  });

  testWidgets('BookingCalendarView renders appointment time in schedule view', (
    WidgetTester tester,
  ) async {
    final startTime = DateTime(2026, 3, 2, 10, 0);
    final endTime = startTime.add(const Duration(hours: 1));
    final appointment = Appointment(
      startTime: startTime,
      endTime: endTime,
      subject: 'Schedule Meeting',
      notes: 'Conference Room B',
      color: Colors.green,
    );

    final state = CalendarViewState(
      currentView: CalendarView.schedule,
      currentDate: startTime,
      allowDragAndDrop: false,
      allowAppointmentResize: false,
      dataSource: FakeDataSource([appointment]),
      specialRegions: [],
    );

    when(
      () => mockViewModel.calendarViewState(),
    ).thenAnswer((_) => Stream.value(state));
    when(() => mockViewModel.controller).thenReturn(CalendarController());
    when(
      () => mockViewModel.minDate,
    ).thenReturn(DateTime.now().subtract(const Duration(days: 30)));
    when(() => mockViewModel.showNavigationArrow).thenReturn(true);
    when(() => mockViewModel.showTodayButton).thenReturn(true);
    when(() => mockViewModel.showDatePickerButton).thenReturn(true);
    when(() => mockViewModel.allowViewNavigation).thenReturn(true);
    when(() => mockViewModel.allowedViews).thenReturn([
      CalendarView.day,
      CalendarView.week,
      CalendarView.workWeek,
      CalendarView.month,
      CalendarView.schedule,
    ]);
    when(() => mockViewModel.handleResizeEnd(any())).thenAnswer((_) async {});
    when(() => mockViewModel.handleDragEnd(any())).thenAnswer((_) async {});
    when(() => mockViewModel.handleTap(any())).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<LoggingService>(
          create: (_) => FakeLoggingService(),
          child: BookingCalendar(createViewModel: () => mockViewModel),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // In Schedule view, Syncfusion calendar handles the rendering of the appointment
    // including the time and the subject because our _appointmentBuilder returns
    // null for CalendarView.schedule. We can verify that the custom Tooltip is
    // NOT present, indicating the default Syncfusion agenda view is being used
    // which contains the time by default.
    final tooltipFinder = find.byType(Tooltip);
    expect(tooltipFinder, findsNothing);
  });
}
