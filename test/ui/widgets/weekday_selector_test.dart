import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/ui/widgets/weekday_selector.dart';

void main() {
  group('WeekdaySelector', () {
    late Set<Weekday> selectedDays;
    late Function(Weekday) toggleDay;
    Weekday? toggledDay;

    setUp(() {
      selectedDays = {Weekday.monday, Weekday.friday};
      toggleDay = (day) {
        toggledDay = day;
      };
    });

    testWidgets('renders all 7 day buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              startTime: DateTime.now(),
              selectedDays: selectedDays,
              toggleDay: toggleDay,
            ),
          ),
        ),
      );

      expect(find.byType(DayButton), findsNWidgets(7));
    });

    testWidgets('calls toggleDay with correct weekday on tap',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WeekdaySelector(
              startTime: DateTime.now(),
              selectedDays: selectedDays,
              toggleDay: toggleDay,
            ),
          ),
        ),
      );

      await tester.tap(find.widgetWithText(DayButton, 'M'));
      expect(toggledDay, Weekday.monday);

      await tester.tap(find.widgetWithText(DayButton, 'W'));
      expect(toggledDay, Weekday.wednesday);
    });
  });

  group('DayButton', () {
    testWidgets('renders correctly when selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayButton(
              label: 'M',
              selected: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.descendant(
          of: find.byType(DayButton), matching: find.byType(Container)));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue);

      final text = tester.widget<Text>(find.text('M'));
      expect(text.style?.color, Colors.white);
    });

    testWidgets('renders correctly when not selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayButton(
              label: 'T',
              selected: false,
              onPressed: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.descendant(
          of: find.byType(DayButton), matching: find.byType(Container)));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.grey[200]);

      final text = tester.widget<Text>(find.text('T'));
      expect(text.style?.color, Colors.blue);
    });

    testWidgets('calls onPressed on tap', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DayButton(
              label: 'S',
              selected: false,
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DayButton));
      expect(pressed, isTrue);
    });
  });
}
