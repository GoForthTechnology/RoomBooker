import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/logging_service.dart';
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

    // Verify Tooltip message matches room name
    final tooltip = tester.widget<Tooltip>(tooltipFinder);
    expect(tooltip.message, 'Conference Room A');

    // Verify Appointment subject is rendered in Text widget
    expect(find.text('Test Meeting'), findsOneWidget);
  });
}
