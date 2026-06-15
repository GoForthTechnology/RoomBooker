import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:roombooker_kiosk/agenda_list.dart';

void main() {
  final now = DateTime(2024, 1, 1, 12, 0);

  Request booking({
    required String publicName,
    required DateTime start,
    required DateTime end,
  }) {
    return Request(
      publicName: publicName,
      eventStartTime: start,
      eventEndTime: end,
      roomID: 'room-1',
      roomName: 'Room 1',
    );
  }

  group('AgendaListView', () {
    testWidgets('shows empty state when there are no bookings', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AgendaListView(bookings: const [], now: now),
        ),
      );

      expect(find.text('No meetings scheduled'), findsOneWidget);
    });

    testWidgets('lists bookings in chronological order', (tester) async {
      final later = booking(
        publicName: 'Later Meeting',
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 3)),
      );
      final earlier = booking(
        publicName: 'Earlier Meeting',
        start: now.subtract(const Duration(hours: 2)),
        end: now.subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgendaListView(bookings: [later, earlier], now: now),
        ),
      );

      final earlierCenter = tester.getCenter(find.text('Earlier Meeting'));
      final laterCenter = tester.getCenter(find.text('Later Meeting'));
      expect(earlierCenter.dy, lessThan(laterCenter.dy));
    });

    testWidgets('falls back to "Private Meeting" when publicName is null', (
      tester,
    ) async {
      final unnamed = Request(
        eventStartTime: now,
        eventEndTime: now.add(const Duration(hours: 1)),
        roomID: 'room-1',
        roomName: 'Room 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgendaListView(bookings: [unnamed], now: now),
        ),
      );

      expect(find.text('Private Meeting'), findsOneWidget);
    });

    testWidgets('highlights the booking currently in progress', (
      tester,
    ) async {
      final current = booking(
        publicName: 'Current Meeting',
        start: now.subtract(const Duration(minutes: 30)),
        end: now.add(const Duration(minutes: 30)),
      );
      final upcoming = booking(
        publicName: 'Upcoming Meeting',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AgendaListView(bookings: [current, upcoming], now: now),
        ),
      );

      Container containerFor(String text) => tester.widget<Container>(
            find.ancestor(
              of: find.text(text),
              matching: find.byType(Container),
            ),
          );

      final currentDecoration =
          containerFor('Current Meeting').decoration as BoxDecoration;
      final upcomingDecoration =
          containerFor('Upcoming Meeting').decoration as BoxDecoration;

      expect(currentDecoration.border, isNotNull);
      expect(upcomingDecoration.border, isNull);
    });
  });
}
