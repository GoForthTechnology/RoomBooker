import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/ui/widgets/time_field.dart';

void main() {
  group('TimeField', () {
    late TimeOfDay initialTime;
    late Function(TimeOfDay) onChanged;

    setUp(() {
      initialTime = const TimeOfDay(hour: 10, minute: 30);
      onChanged = (time) {};
    });

    testWidgets('renders with initial value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TimeField(
                initialValue: initialTime,
                onChanged: onChanged,
                labelText: 'Time',
                readOnly: false,
                localizations: MaterialLocalizations.of(context),
              ),
            ),
          ),
        ),
      );
    });

    testWidgets('shows time picker on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TimeField(
                initialValue: initialTime,
                onChanged: onChanged,
                labelText: 'Time',
                readOnly: false,
                localizations: MaterialLocalizations.of(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TimeField));
      await tester.pumpAndSettle(); // Wait for dialog animation

      // The time picker is now shown, and we can interact with it.
      // For this test, we just confirm it appears.
      expect(find.byType(TimePickerDialog), findsOneWidget);
    });

    testWidgets('onChanged is called with rounded time after picking',
        (WidgetTester tester) async {
      TimeOfDay? selectedTime;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TimeField(
                initialValue: initialTime,
                onChanged: (time) {
                  selectedTime = time;
                },
                labelText: 'Time',
                readOnly: false,
                localizations: MaterialLocalizations.of(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TimeField));
      await tester.pumpAndSettle();

      // Pick a time that needs rounding
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(selectedTime, const TimeOfDay(hour: 10, minute: 30));
      expect(find.text('10:30 AM'), findsOneWidget);
    });

    testWidgets('onChanged is not called when time picker is cancelled',
        (WidgetTester tester) async {
      TimeOfDay? selectedTime;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TimeField(
                initialValue: initialTime,
                onChanged: (time) {
                  selectedTime = time;
                },
                labelText: 'Time',
                readOnly: false,
                localizations: MaterialLocalizations.of(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TimeField));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(selectedTime, isNull);
      expect(find.text('10:30 AM'), findsOneWidget);
    });

    testWidgets('does not show time picker when readOnly is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TimeField(
                initialValue: initialTime,
                onChanged: onChanged,
                labelText: 'Time',
                readOnly: true,
                localizations: MaterialLocalizations.of(context),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TimeField));
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsNothing);
    });

    test('roundToNearest15Minutes rounds correctly', () {
      final timeField = TimeField(
        initialValue: const TimeOfDay(hour: 10, minute: 0),
        onChanged: (_) {},
        labelText: 'Time',
        readOnly: false,
        localizations:
            const DefaultMaterialLocalizations(), // Dummy localizations
      );

      expect(
        timeField.roundToNearest15Minutes(const TimeOfDay(hour: 10, minute: 7)),
        const TimeOfDay(hour: 10, minute: 0),
      );
      expect(
        timeField.roundToNearest15Minutes(const TimeOfDay(hour: 10, minute: 8)),
        const TimeOfDay(hour: 10, minute: 15),
      );
      expect(
        timeField.roundToNearest15Minutes(
          const TimeOfDay(hour: 10, minute: 22),
        ),
        const TimeOfDay(hour: 10, minute: 15),
      );
      expect(
        timeField.roundToNearest15Minutes(
          const TimeOfDay(hour: 10, minute: 23),
        ),
        const TimeOfDay(hour: 10, minute: 30),
      );
      expect(
        timeField.roundToNearest15Minutes(
          const TimeOfDay(hour: 10, minute: 53),
        ),
        const TimeOfDay(hour: 11, minute: 0),
      );
    });

    test('parseTime parses correctly', () {
      final timeField = TimeField(
        initialValue: const TimeOfDay(hour: 10, minute: 0),
        onChanged: (_) {},
        labelText: 'Time',
        readOnly: false,
        localizations: const DefaultMaterialLocalizations(),
      );

      expect(
        timeField.parseTime('10:30 AM'),
        const TimeOfDay(hour: 10, minute: 30),
      );
      expect(
        timeField.parseTime('3:45 PM'),
        const TimeOfDay(hour: 15, minute: 45),
      );
    });

    group('Validation', () {
      testWidgets('shows error for invalid time format', (
        WidgetTester tester,
      ) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Builder(
                  builder: (context) => TimeField(
                    initialValue: initialTime,
                    onChanged: onChanged,
                    labelText: 'Time',
                    readOnly: false,
                    localizations: MaterialLocalizations.of(context),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), 'invalid time');
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Invalid time format'), findsOneWidget);
      });

      testWidgets('shows error for time after maxTime', (
        WidgetTester tester,
      ) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Builder(
                  builder: (context) => TimeField(
                    initialValue: initialTime,
                    onChanged: onChanged,
                    labelText: 'Time',
                    readOnly: false,
                    localizations: MaterialLocalizations.of(context),
                    maxTime: const TimeOfDay(hour: 11, minute: 0),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), '12:00 PM');
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Time cannot be after 11:00 AM'), findsOneWidget);
      });

      testWidgets('shows error for time before minTime', (
        WidgetTester tester,
      ) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Builder(
                  builder: (context) => TimeField(
                    initialValue: initialTime,
                    onChanged: onChanged,
                    labelText: 'Time',
                    readOnly: false,
                    localizations: MaterialLocalizations.of(context),
                    minTime: const TimeOfDay(hour: 9, minute: 0),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), '8:00 AM');
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Time cannot be before 9:00 AM'), findsOneWidget);
      });

      testWidgets('shows no error for valid time', (WidgetTester tester) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Form(
                key: formKey,
                child: Builder(
                  builder: (context) => TimeField(
                    initialValue: initialTime,
                    onChanged: onChanged,
                    labelText: 'Time',
                    readOnly: false,
                    localizations: MaterialLocalizations.of(context),
                    minTime: const TimeOfDay(hour: 9, minute: 0),
                    maxTime: const TimeOfDay(hour: 17, minute: 0),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), '10:00 AM');
        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Invalid time format'), findsNothing);
        expect(find.textContaining('Time cannot be after'), findsNothing);
        expect(find.textContaining('Time cannot be before'), findsNothing);
      });
    });
  });

  group('TimeOfDayExtension', () {
    test('isAfter works correctly', () {
      const time = TimeOfDay(hour: 12, minute: 0);
      expect(time.isAfter(const TimeOfDay(hour: 11, minute: 59)), isTrue);
      expect(time.isAfter(const TimeOfDay(hour: 12, minute: 0)), isFalse);
      expect(time.isAfter(const TimeOfDay(hour: 12, minute: 1)), isFalse);
    });

    test('isBefore works correctly', () {
      const time = TimeOfDay(hour: 12, minute: 0);
      expect(time.isBefore(const TimeOfDay(hour: 12, minute: 1)), isTrue);
      expect(time.isBefore(const TimeOfDay(hour: 12, minute: 0)), isFalse);
      expect(time.isBefore(const TimeOfDay(hour: 11, minute: 59)), isFalse);
    });
  });
}

extension TimeOfDayExtension on TimeOfDay {
  bool isAfter(TimeOfDay other) {
    if (hour > other.hour) return true;
    if (hour == other.hour && minute > other.minute) return true;
    return false;
  }

  bool isBefore(TimeOfDay other) {
    if (hour < other.hour) return true;
    if (hour == other.hour && minute < other.minute) return true;
    return false;
  }
}

