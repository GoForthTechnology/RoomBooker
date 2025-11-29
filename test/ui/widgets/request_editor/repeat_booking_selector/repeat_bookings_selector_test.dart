import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_selector.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_period_selector.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/weekday_selector.dart';
import 'package:rxdart/rxdart.dart';

class MockRepeatBookingsViewModel extends Mock implements RepeatBookingsViewModel {}

void main() {
  late MockRepeatBookingsViewModel mockViewModel;
  late BehaviorSubject<RecurrancePattern> patternSubject;
  late BehaviorSubject<bool> isCustomSubject;
  late BehaviorSubject<DateTime> startTimeSubject;
  late BehaviorSubject<bool> readOnlySubject;

  setUpAll(() {
    registerFallbackValue(Frequency.daily);
    registerFallbackValue(Weekday.monday);
  });

  setUp(() {
    mockViewModel = MockRepeatBookingsViewModel();
    patternSubject = BehaviorSubject.seeded(RecurrancePattern.never());
    isCustomSubject = BehaviorSubject.seeded(false);
    startTimeSubject = BehaviorSubject.seeded(DateTime(2023, 1, 1));
    readOnlySubject = BehaviorSubject.seeded(false);

    when(() => mockViewModel.patternStream).thenAnswer((_) => patternSubject.stream);
    when(() => mockViewModel.isCustomStream).thenAnswer((_) => isCustomSubject.stream);
    when(() => mockViewModel.startTimeStream).thenAnswer((_) => startTimeSubject.stream);
    when(() => mockViewModel.readOnlyStream).thenAnswer((_) => readOnlySubject.stream);
    
    // Mock void methods
    when(() => mockViewModel.onFrequencyChanged(any())).thenReturn(null);
    when(() => mockViewModel.onIntervalChanged(any())).thenReturn(null);
    when(() => mockViewModel.toggleWeekday(any())).thenReturn(null);
  });

  tearDown(() {
    patternSubject.close();
    isCustomSubject.close();
    startTimeSubject.close();
    readOnlySubject.close();
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepeatBookingsSelector(viewModel: mockViewModel),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders frequency dropdown with default "Never"', (tester) async {
    await pumpWidget(tester);

    // Check for the Label
    expect(find.text('Repeats'), findsOneWidget);
    // Check for the initial value text
    expect(find.text('Never'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<Frequency>), findsOneWidget);
  });

  testWidgets('renders RepeatPeriodSelector when frequency is Daily', (tester) async {
    patternSubject.add(RecurrancePattern.daily());
    isCustomSubject.add(true); // Needs to be custom or handled by loop
    // RepeatBookingsSelector logic: if (!isCustom || pattern.frequency == Frequency.never) return [];
    // So we need isCustom=true for Daily/Weekly etc to show extra widgets?
    // Let's check the source:
    // if (!isCustom || pattern.frequency == Frequency.never) { return []; }
    // Wait, standard Daily/Weekly usually don't show "Repeat every" in Google Calendar unless you go to custom.
    // But here, if I select "Daily", does it become custom?
    // In VM: onFrequencyChanged(Frequency.daily) -> standard -> isCustom=false.
    // So if I select "Daily", isCustom is false.
    // Then _additionalWidgets returns empty list.
    // So RepeatPeriodSelector should NOT be visible for standard Daily.
    
    isCustomSubject.add(false);
    patternSubject.add(RecurrancePattern.daily());
    await pumpWidget(tester);
    expect(find.byType(RepeatPeriodSelector), findsNothing);

    // Now if I have a Custom Daily pattern
    isCustomSubject.add(true);
    await pumpWidget(tester);
    expect(find.byType(RepeatPeriodSelector), findsOneWidget);
  });

  testWidgets('renders RepeatPeriodSelector and WeekdaySelector when frequency is Weekly and Custom', (tester) async {
    isCustomSubject.add(true);
    patternSubject.add(RecurrancePattern.weekly(on: Weekday.monday));
    await pumpWidget(tester);

    expect(find.byType(RepeatPeriodSelector), findsOneWidget);
    expect(find.byType(WeekdaySelector), findsOneWidget);
  });

  testWidgets('renders month interval selector when frequency is Monthly and Custom', (tester) async {
    isCustomSubject.add(true);
    patternSubject.add(RecurrancePattern.monthlyOnNth(1, Weekday.sunday));
    await pumpWidget(tester);

    // The month interval selector is a DropdownButtonFormField<String>
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
  });

  testWidgets('calling onFrequencyChanged on VM when dropdown changes', (tester) async {
    await pumpWidget(tester);

    // Open dropdown
    await tester.tap(find.byType(DropdownButtonFormField<Frequency>));
    await tester.pumpAndSettle();

    // Select Daily
    // There might be multiple 'Daily' texts if one is already selected? No default is Never.
    await tester.tap(find.text('Daily').last);
    await tester.pump();

    verify(() => mockViewModel.onFrequencyChanged(Frequency.daily)).called(1);
  });
  
  testWidgets('disabled when readOnly', (tester) async {
    readOnlySubject.add(true);
    await pumpWidget(tester);
    
    // Dropdown should be disabled
    final dropdown = tester.widget<DropdownButtonFormField>(find.byType(DropdownButtonFormField<Frequency>));
    expect(dropdown.onChanged, isNull);
  });
}
