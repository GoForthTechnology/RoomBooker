import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockCalendarViewModel extends Mock implements CalendarViewModel {}

class FakeDataSource extends CalendarDataSource {}

class FakeAppointmentResizeEndDetails extends Fake
    implements AppointmentResizeEndDetails {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class FakeAppointmentDragEndDetails extends Fake
    implements AppointmentDragEndDetails {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

class FakeCalendarTapDetails extends Fake implements CalendarTapDetails {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return super.toString();
  }
}

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

  testWidgets(
    'BookingCalendarView shows CircularProgressIndicator when snapshot has no data',
    (WidgetTester tester) async {
      when(
        () => mockViewModel.calendarViewState(),
      ).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: BookingCalendar(createViewModel: () => mockViewModel),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('BookingCalendarView shows SfCalendar when snapshot has data', (
    WidgetTester tester,
  ) async {
    final state = CalendarViewState(
      currentView: CalendarView.day,
      currentDate: DateTime.now(),
      allowDragAndDrop: true,
      allowAppointmentResize: true,
      dataSource: FakeDataSource(),
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
      MaterialApp(home: BookingCalendar(createViewModel: () => mockViewModel)),
    );

    await tester.pump();

    expect(find.byType(SfCalendar), findsOneWidget);
  });
}
