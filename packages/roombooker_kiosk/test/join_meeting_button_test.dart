import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_kiosk/main.dart';

void main() {
  group('JoinMeetingButton', () {
    testWidgets('renders nothing when meetingUrl is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinMeetingButton(
            meetingUrl: null,
            foregroundColor: Colors.red,
            onLaunch: (_) {},
          ),
        ),
      );

      expect(find.text('JOIN MEETING'), findsNothing);
    });

    testWidgets('renders Join Meeting button when meetingUrl is set', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinMeetingButton(
            meetingUrl: 'https://meet.example.com/test',
            foregroundColor: Colors.red,
            onLaunch: (_) {},
          ),
        ),
      );

      expect(find.text('JOIN MEETING'), findsOneWidget);
    });

    testWidgets('tapping the button launches the meeting URL', (
      tester,
    ) async {
      String? launchedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: JoinMeetingButton(
            meetingUrl: 'https://meet.example.com/test',
            foregroundColor: Colors.red,
            onLaunch: (url) => launchedUrl = url,
          ),
        ),
      );

      await tester.tap(find.text('JOIN MEETING'));
      await tester.pump();

      expect(launchedUrl, 'https://meet.example.com/test');
    });
  });
}
