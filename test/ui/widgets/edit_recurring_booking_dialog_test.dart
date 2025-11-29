import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/ui/widgets/edit_recurring_booking_dialog.dart';

void main() {
  group('EditRecurringBookingDialog', () {
    testWidgets('renders correctly with default selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditRecurringBookingDialog(),
        ),
      );

      expect(find.text('Edit Recurring Booking'), findsOneWidget);
      expect(find.text('This instance only'), findsOneWidget);
      expect(find.text('This and future instances'), findsOneWidget);
      expect(find.text('All instances'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Check default selection
      final radio = tester.widget<Radio<RecurringBookingEditChoice>>(
        find.byWidgetPredicate((widget) =>
            widget is Radio<RecurringBookingEditChoice> &&
            widget.value == RecurringBookingEditChoice.thisInstance),
      );
      expect(radio.groupValue, RecurringBookingEditChoice.thisInstance);
    });

    testWidgets('allows changing selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EditRecurringBookingDialog(),
        ),
      );

      // Tap on "All instances"
      await tester.tap(find.text('All instances'));
      await tester.pump();

      // Check updated selection
      final radio = tester.widget<Radio<RecurringBookingEditChoice>>(
        find.byWidgetPredicate((widget) =>
            widget is Radio<RecurringBookingEditChoice> &&
            widget.value == RecurringBookingEditChoice.all),
      );
      expect(radio.groupValue, RecurringBookingEditChoice.all);
    });

    testWidgets('returns null when Cancel is pressed', (tester) async {
      RecurringBookingEditChoice? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<RecurringBookingEditChoice>(
                  context: context,
                  builder: (context) => const EditRecurringBookingDialog(),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('returns selected choice when OK is pressed', (tester) async {
      RecurringBookingEditChoice? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<RecurringBookingEditChoice>(
                  context: context,
                  builder: (context) => const EditRecurringBookingDialog(),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Change selection to "This and future instances"
      await tester.tap(find.text('This and future instances'));
      await tester.pump();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, RecurringBookingEditChoice.thisAndFuture);
    });
  });
}
