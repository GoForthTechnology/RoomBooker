import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_kiosk/stage_ui.dart';

void main() {
  testWidgets('MeetingStageWidget renders room status', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: MeetingStageWidget(),
    ));

    expect(find.text('LOADING...'), findsOneWidget);
    expect(find.text('AVAILABLE'), findsOneWidget);
  });
}
