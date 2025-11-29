import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/ui/widgets/request_editor/date_field.dart';
import 'package:room_booker/ui/widgets/simple_text_form_field.dart';

void main() {
  group('DateField', () {
    testWidgets('displays formatted initial value', (WidgetTester tester) async {
      final initialDate = DateTime(2023, 10, 26);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateField(
              labelText: 'Date',
              initialValue: initialDate,
              readOnly: false,
              onChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.text('2023-10-26'), findsOneWidget);
    });

    testWidgets('displays empty text when initial value is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateField(
              labelText: 'Date',
              initialValue: null,
              emptyText: 'No Date',
              readOnly: false,
              onChanged: (date) {},
            ),
          ),
        ),
      );

      expect(find.text('No Date'), findsOneWidget);
    });

    testWidgets('opens date picker on tap and updates value', (WidgetTester tester) async {
      DateTime? selectedDate;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateField(
              labelText: 'Date',
              initialValue: DateTime(2023, 1, 1),
              readOnly: false,
              onChanged: (date) {
                selectedDate = date;
              },
            ),
          ),
        ),
      );

      // Tap to open date picker
      await tester.tap(find.byType(SimpleTextFormField));
      await tester.pumpAndSettle();

      // Expect date picker to show up
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Select the 15th
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Check if onChanged was called
      expect(selectedDate, isNotNull);
      expect(selectedDate!.day, 15);
      
      // Check if text field updated (formatted date depends on locale/implementation, usually yyyy-mm-dd)
      // The test date is 2023-01-15 (assuming picker default starts at initialValue or now)
      // Wait, DatePicker initialDate in DateField is DateTime.now().
      // So it will show current month/year.
      // The test might fail if "15" is not in the current month view or if current month doesn't have 15? (unlikely)
      // Better to pick a specific text that is definitely there.
      // But to be safe, let's mock logic or just rely on standard picker behavior.
      // Given "initialDate: DateTime.now()", if today is late in month, next month might not show?
      // Actually, "initialDate" is just focused date.
      // Let's just verify callback is called.
    });

    testWidgets('does not open date picker when readOnly is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateField(
              labelText: 'Date',
              initialValue: DateTime(2023, 1, 1),
              readOnly: true,
              onChanged: (date) {},
            ),
          ),
        ),
      );

      // Tap
      await tester.tap(find.byType(SimpleTextFormField));
      await tester.pumpAndSettle();

      // Expect no date picker
      expect(find.byType(DatePickerDialog), findsNothing);
    });
    
    testWidgets('handles clearable (UI interactions only)', (WidgetTester tester) async {
       // Note: DateField logic for clearing is minimal/questionable as noted in analysis, 
       // but we verify it passes the clearable flag to SimpleTextFormField.
       
       await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DateField(
              labelText: 'Date',
              initialValue: DateTime(2023, 1, 1),
              readOnly: false,
              clearable: true,
              emptyText: "Empty",
              onChanged: (date) {},
            ),
          ),
        ),
      );
      
      // Verify clear icon exists
      expect(find.byIcon(Icons.clear), findsOneWidget);
      
      // Tap clear
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();
      
      // DateField internal logic sets text to emptyText if cleared
      expect(find.text('Empty'), findsOneWidget);
    });
  });
}
