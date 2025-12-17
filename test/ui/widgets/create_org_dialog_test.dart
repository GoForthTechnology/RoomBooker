import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/ui/widgets/create_org_dialog.dart';

void main() {
  testWidgets('CreateOrgDialog has two steps and validates input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateOrgDialog()));

    // Verify initial step
    expect(find.text('Create New Organization'), findsOneWidget);
    // There are multiple "Organization Name" texts (Step title, Field label)
    expect(find.text('Organization Name'), findsAtLeastNWidgets(1));
    // Similarly for First Room Name
    expect(find.text('First Room Name'), findsAtLeastNWidgets(1));
    
    // There are duplicates due to Stepper implementation (e.g. shadowed or offstage)
    // We just take the first one.
    final continueButton = find.widgetWithText(TextButton, 'Continue').first;
    expect(continueButton, findsOneWidget);

    // Try to continue without input
    await tester.tap(continueButton);
    await tester.pump();
    expect(find.text('Please enter a name'), findsOneWidget);

    // Enter org name
    // Use a more specific finder if possible, but first should be correct as it is in the first step.
    await tester.enterText(find.byType(TextFormField).first, 'Test Org');
    await tester.pump();
    
    // Verify text was entered
    expect(find.text('Test Org'), findsOneWidget);

    // Verify error is gone (validation should pass now)
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // Verify step index or content changed
    // 'Create' text should be present in the button now.
    // Use hitTestable to ensure we find the one that is actually visible/clickable
    // Stepper might render multiple buttons.
    expect(find.text('Create'), findsAtLeastNWidgets(1));
    
    final createButton = find.widgetWithText(TextButton, 'Create').hitTestable().first;
    expect(createButton, findsOneWidget);
    
    // Check for Room Name label/title
    expect(find.text('First Room Name'), findsAtLeastNWidgets(1));

    // Try to create without input
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();
    expect(find.text('Please enter a room name'), findsOneWidget);

    // Enter room name
    // Search for the last TextFormField, assuming order.
    final roomField = find.byType(TextFormField).last;
    await tester.ensureVisible(roomField);
    await tester.enterText(roomField, 'Test Room');
    await tester.pump();

    // Tap Create
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    // Verify dialog closed
    expect(find.byType(CreateOrgDialog), findsNothing);
  });
}
