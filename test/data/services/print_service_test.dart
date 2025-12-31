import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/print_service.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PrintService', () {
    late PrintService printService;

    setUp(() {
      printService = PrintService();
    });

    test('generateDocument generates PDF without error for Day view', () async {
      final requests = [
        Request(
          id: '1',
          eventStartTime: DateTime(2023, 1, 1, 10, 0),
          eventEndTime: DateTime(2023, 1, 1, 11, 0),
          roomID: 'r1',
          roomName: 'Conference Room A',
          publicName: 'Meeting',
        ),
      ];

      final doc = printService.generateDocument(
        requests: requests,
        targetDate: DateTime(2023, 1, 1),
        view: CalendarView.day,
        orgName: 'Test Org',
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
    });

    test(
      'generateDocument generates PDF without error for Month view',
      () async {
        final requests = [
          Request(
            id: '1',
            eventStartTime: DateTime(2023, 1, 1, 10, 0),
            eventEndTime: DateTime(2023, 1, 1, 11, 0),
            roomID: 'r1',
            roomName: 'Conference Room A',
            publicName: 'Meeting',
          ),
        ];

        final doc = printService.generateDocument(
          requests: requests,
          targetDate: DateTime(2023, 1, 1),
          view: CalendarView.month,
          orgName: 'Test Org',
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
      },
    );

    test(
      'generateDocument generates PDF without error for Schedule view',
      () async {
        final requests = [
          Request(
            id: '1',
            eventStartTime: DateTime(2023, 1, 10, 10, 0),
            eventEndTime: DateTime(2023, 1, 10, 11, 0),
            roomID: 'r1',
            roomName: 'Conference Room A',
            publicName: 'Meeting',
          ),
          // Event 20 days later
          Request(
            id: '2',
            eventStartTime: DateTime(2023, 1, 25, 10, 0),
            eventEndTime: DateTime(2023, 1, 25, 11, 0),
            roomID: 'r1',
            roomName: 'Conference Room A',
            publicName: 'Later Meeting',
          ),
        ];

        final doc = printService.generateDocument(
          requests: requests,
          targetDate: DateTime(2023, 1, 1),
          view: CalendarView.schedule,
          orgName: 'Test Org',
        );

        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
      },
    );
  });
}
