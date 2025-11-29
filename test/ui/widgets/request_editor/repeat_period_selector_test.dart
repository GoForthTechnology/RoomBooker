import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_period_selector.dart';

void main() {
  testWidgets('RepeatPeriodSelector updates text when interval changes', (
    WidgetTester tester,
  ) async {
    int interval = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return RepeatPeriodSelector(
                frequency: Frequency.weekly,
                interval: interval,
                onFrequencyChanged: (_) {},
                onIntervalChanged: (newInterval) {
                  setState(() {
                    interval = newInterval;
                  });
                },
                readOnly: false,
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    // Simulate external update (though here we are driving it via the widget's own callback for convenience of test structure)
    // Let's find the add button and tap it
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(interval, 2);

    // Test manual entry
    await tester.enterText(find.byType(TextFormField), '5');
    await tester.pump();
    // Note: onChanged updates state, which rebuilds widget with new interval, which updates controller text again to "5".

    expect(find.text('5'), findsOneWidget);
    expect(interval, 5);
  });

  testWidgets('RepeatPeriodSelector respects external interval updates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepeatPeriodSelector(
            frequency: Frequency.weekly,
            interval: 1,
            onFrequencyChanged: (_) {},
            onIntervalChanged: (_) {},
            readOnly: false,
          ),
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepeatPeriodSelector(
            frequency: Frequency.weekly,
            interval: 10,
            onFrequencyChanged: (_) {},
            onIntervalChanged: (_) {},
            readOnly: false,
          ),
        ),
      ),
    );

    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('RepeatPeriodSelector disables inputs when readOnly is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepeatPeriodSelector(
            frequency: Frequency.weekly,
            interval: 5,
            onFrequencyChanged: (_) {},
            onIntervalChanged: (_) {},
            readOnly: true,
          ),
        ),
      ),
    );

    // Verify TextFormField's child TextField is readOnly
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.readOnly, true);
    expect(textField.enabled, false);

    // Verify DropdownButton is disabled (onChanged should be null)
    final dropdown = tester.widget<DropdownButton<Frequency>>(
      find.byType(DropdownButton<Frequency>),
    );
    expect(dropdown.onChanged, isNull);

    // Verify IconButton (Add) is disabled (onPressed should be null)
    final addIcon = find.byIcon(Icons.add);
    final addButton = tester.widget<IconButton>(
      find.ancestor(of: addIcon, matching: find.byType(IconButton)),
    );
    expect(addButton.onPressed, isNull);

    // Verify IconButton (Remove) is disabled (onPressed should be null)
    final removeIcon = find.byIcon(Icons.remove);
    final removeButton = tester.widget<IconButton>(
      find.ancestor(of: removeIcon, matching: find.byType(IconButton)),
    );
    expect(removeButton.onPressed, isNull);
  });
}
