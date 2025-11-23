import 'package:flutter_test/flutter_test.dart';
import 'package:room_booker/data/entities/log_entry.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:intl/intl.dart';

void main() {
  group('RequestLogEntry', () {
    final tDateTime = DateTime.now();
    final tRequest = Request(
      eventStartTime: tDateTime,
      eventEndTime: tDateTime.add(const Duration(hours: 1)),
      roomID: 'room1',
      roomName: 'Room 1',
      publicName: 'Test Event',
      status: RequestStatus.pending,
      recurrancePattern: RecurrancePattern.never(),
      ignoreOverlaps: false,
    );

    test('copyWith returns a new object with updated id', () {
      final logEntry = RequestLogEntry(
        requestID: 'req1',
        timestamp: tDateTime,
        action: Action.create,
        before: null,
        after: tRequest,
      );

      final updatedLogEntry = logEntry.copyWith(id: 'newId');

      expect(updatedLogEntry.id, 'newId');
      expect(updatedLogEntry.requestID, logEntry.requestID);
      expect(updatedLogEntry.timestamp, logEntry.timestamp);
      expect(updatedLogEntry.action, logEntry.action);
      expect(updatedLogEntry.before, logEntry.before);
      expect(updatedLogEntry.after, logEntry.after);
    });

    group('serialization', () {
      test('toJson converts RequestLogEntry to JSON correctly', () {
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.create,
          adminEmail: 'admin@example.com',
          before: null,
          after: tRequest,
          id: 'log1',
        );

        final json = logEntry.toJson();

        expect(json['requestID'], 'req1');
        expect(json['timestamp'], tDateTime.toIso8601String());
        expect(json['action'], 'create');
        expect(json['adminEmail'], 'admin@example.com');
        expect(json['before'], null);
        expect(json['after'], tRequest.toJson());
      });

      test('fromJson converts JSON to RequestLogEntry correctly', () {
        final json = {
          'requestID': 'req1',
          'timestamp': tDateTime.toIso8601String(),
          'action': 'create',
          'adminEmail': 'admin@example.com',
          'before': null,
          'after': tRequest.toJson(),
        };

        final logEntry = RequestLogEntry.fromJson(json);

        expect(logEntry.requestID, 'req1');
        expect(logEntry.timestamp.toIso8601String(), tDateTime.toIso8601String());
        expect(logEntry.action, Action.create);
        expect(logEntry.adminEmail, 'admin@example.com');
        expect(logEntry.before, null);
        expect(logEntry.after?.publicName, tRequest.publicName);
      });
    });

    group('render', () {
      test('returns "No changes detected." when both before and after are null', () {
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.create,
          before: null,
          after: null,
        );

        expect(logEntry.render(), 'No changes detected.');
      });

      test('returns "No changes detected." when before and after are identical', () {
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: tRequest,
          after: tRequest,
        );

        expect(logEntry.render(), 'No changes detected.');
      });

      test('returns "Created:" message when only after is present', () {
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.create,
          before: null,
          after: tRequest,
        );

        final expected =
            'Created: Event "Test Event" in room "Room 1" from ${DateFormat.yMMMd().add_jm().format(tDateTime)} to ${DateFormat.yMMMd().add_jm().format(tDateTime.add(const Duration(hours: 1)))}. Status: Pending.';
        expect(logEntry.render(), expected);
      });

      test('returns "Deleted:" message when only before is present', () {
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.delete,
          before: tRequest,
          after: null,
        );

        final expected =
            'Deleted: Event "Test Event" in room "Room 1" from ${DateFormat.yMMMd().add_jm().format(tDateTime)} to ${DateFormat.yMMMd().add_jm().format(tDateTime.add(const Duration(hours: 1)))}. Status: Pending.';
        expect(logEntry.render(), expected);
      });

      test('returns diff message when publicName changes', () {
        final beforeRequest = tRequest;
        final afterRequest = tRequest.copyWith(publicName: 'New Event Name');
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(logEntry.render(),
            'Public Name changed from "Test Event" to "New Event Name"');
      });

      test('returns diff message when eventStartTime changes', () {
        final beforeRequest = tRequest;
        final newStartTime = tDateTime.add(const Duration(days: 1));
        final afterRequest = tRequest.copyWith(eventStartTime: newStartTime);
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(
            logEntry.render(),
            'Start Time changed from "${DateFormat.yMMMd().add_jm().format(tDateTime)}" to "${DateFormat.yMMMd().add_jm().format(newStartTime)}"');
      });

      test('returns diff message when eventEndTime changes', () {
        final beforeRequest = tRequest;
        final newEndTime = tDateTime.add(const Duration(days: 1, hours: 2));
        final afterRequest = tRequest.copyWith(eventEndTime: newEndTime);
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(
            logEntry.render(),
            'End Time changed from "${DateFormat.yMMMd().add_jm().format(tDateTime.add(const Duration(hours: 1)))}" to "${DateFormat.yMMMd().add_jm().format(newEndTime)}"');
      });

      test('returns diff message when roomName changes', () {
        final beforeRequest = tRequest;
        final afterRequest = tRequest.copyWith(roomName: 'New Room Name');
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(logEntry.render(),
            'Room changed from "Room 1" to "New Room Name"');
      });

      test('returns diff message when status changes', () {
        final beforeRequest = tRequest;
        final afterRequest = tRequest.copyWith(status: RequestStatus.confirmed);
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(logEntry.render(), 'Status changed from "Pending" to "Confirmed"');
      });

      test('returns diff message when recurrancePattern changes', () {
        final beforeRequest = tRequest;
        final afterRequest =
            tRequest.copyWith(recurrancePattern: RecurrancePattern.daily());
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(logEntry.render(), 'Recurrence changed from "Never" to "Daily"');
      });

      test('returns diff message when ignoreOverlaps changes', () {
        final beforeRequest = tRequest;
        final afterRequest = tRequest.copyWith(ignoreOverlaps: true);
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        expect(logEntry.render(), 'Ignore Overlaps changed from "false" to "true"');
      });

      test('returns multiple diff messages when multiple fields change', () {
        final beforeRequest = tRequest;
        final newStartTime = tDateTime.add(const Duration(days: 1));
        final afterRequest = tRequest.copyWith(
          publicName: 'New Event Name',
          eventStartTime: newStartTime,
          roomName: 'New Room Name',
        );
        final logEntry = RequestLogEntry(
          requestID: 'req1',
          timestamp: tDateTime,
          action: Action.update,
          before: beforeRequest,
          after: afterRequest,
        );

        final expected = [
          'Public Name changed from "Test Event" to "New Event Name"',
          'Start Time changed from "${DateFormat.yMMMd().add_jm().format(tDateTime)}" to "${DateFormat.yMMMd().add_jm().format(newStartTime)}"',
          'Room changed from "Room 1" to "New Room Name"',
        ].join('\n');

        expect(logEntry.render(), expected);
      });
    });
  });
}
