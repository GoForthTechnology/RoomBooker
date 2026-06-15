import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:roombooker_kiosk/quick_book_panel.dart';

void main() {
  final now = DateTime(2024, 1, 1, 12, 0);

  Request booking({required DateTime start, required DateTime end}) {
    return Request(
      eventStartTime: start,
      eventEndTime: end,
      roomID: 'room-1',
      roomName: 'Room 1',
    );
  }

  group('QuickBookPanel', () {
    testWidgets('enables all durations when there is no next booking', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuickBookPanel(
            bookings: const [],
            now: now,
            onBook: (_) {},
          ),
        ),
      );

      expect(tester.widget<ElevatedButton>(_button('15m')).onPressed,
          isNotNull);
      expect(tester.widget<ElevatedButton>(_button('30m')).onPressed,
          isNotNull);
      expect(tester.widget<ElevatedButton>(_button('60m')).onPressed,
          isNotNull);
    });

    testWidgets('disables durations that exceed the gap to the next booking', (
      tester,
    ) async {
      final nextBooking = booking(
        start: now.add(const Duration(minutes: 20)),
        end: now.add(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QuickBookPanel(
            bookings: [nextBooking],
            now: now,
            onBook: (_) {},
          ),
        ),
      );

      expect(tester.widget<ElevatedButton>(_button('15m')).onPressed,
          isNotNull);
      expect(tester.widget<ElevatedButton>(_button('30m')).onPressed, isNull);
      expect(tester.widget<ElevatedButton>(_button('60m')).onPressed, isNull);
    });

    testWidgets('tapping an enabled button fires onBook with the duration', (
      tester,
    ) async {
      Duration? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: QuickBookPanel(
            bookings: const [],
            now: now,
            onBook: (duration) => tapped = duration,
          ),
        ),
      );

      await tester.tap(_button('30m'));

      expect(tapped, const Duration(minutes: 30));
    });
  });
}

Finder _button(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(ElevatedButton),
    );
