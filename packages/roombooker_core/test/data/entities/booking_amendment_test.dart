import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_core/data/entities/booking_amendment.dart';
import 'package:roombooker_core/data/entities/request.dart';

void main() {
  final now = DateTime(2025, 6, 1, 10, 0);
  final baseRequest = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room 1',
    eventStartTime: now,
    eventEndTime: now.add(const Duration(hours: 1)),
    status: RequestStatus.confirmed,
  );
  final baseDetails = PrivateRequestDetails(
    eventName: 'Team Meeting',
    name: 'Alice',
    email: 'alice@example.com',
    phone: '555-1234',
  );

  group('AmendmentScope serialization', () {
    test('thisInstance survives BookingAmendment JSON round-trip', () {
      final amendment = BookingAmendment(
        proposedRequest: baseRequest,
        proposedDetails: baseDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );
      final restored = BookingAmendment.fromJson(amendment.toJson());
      expect(restored.scope, AmendmentScope.thisInstance);
    });

    test('thisAndFuture survives BookingAmendment JSON round-trip', () {
      final amendment = BookingAmendment(
        proposedRequest: baseRequest,
        proposedDetails: baseDetails,
        scope: AmendmentScope.thisAndFuture,
        proposedAt: now,
      );
      final restored = BookingAmendment.fromJson(amendment.toJson());
      expect(restored.scope, AmendmentScope.thisAndFuture);
    });
  });

  group('BookingAmendment serialization', () {
    test('round-trips through JSON for one-off amendment', () {
      final amendment = BookingAmendment(
        proposedRequest: baseRequest,
        proposedDetails: baseDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );

      final json = amendment.toJson();
      final restored = BookingAmendment.fromJson(json);

      expect(restored.scope, AmendmentScope.thisInstance);
      expect(restored.proposedRequest.roomID, 'room1');
      expect(restored.proposedDetails.eventName, 'Team Meeting');
      expect(restored.instanceStartDate, now);
    });

    test('round-trips through JSON for thisAndFuture amendment', () {
      final amendment = BookingAmendment(
        proposedRequest: baseRequest,
        proposedDetails: baseDetails,
        scope: AmendmentScope.thisAndFuture,
        proposedAt: now,
      );

      final json = amendment.toJson();
      final restored = BookingAmendment.fromJson(json);

      expect(restored.scope, AmendmentScope.thisAndFuture);
      expect(restored.instanceStartDate, isNull);
    });

    test('null instanceStartDate round-trips as null', () {
      final amendment = BookingAmendment(
        proposedRequest: baseRequest,
        proposedDetails: baseDetails,
        scope: AmendmentScope.thisAndFuture,
        proposedAt: now,
      );

      final json = amendment.toJson();
      expect(json['instanceStartDate'], isNull);
      final restored = BookingAmendment.fromJson(json);
      expect(restored.instanceStartDate, isNull);
    });
  });

  group('Request.hasPendingAmendment', () {
    test('defaults to false when absent from JSON', () {
      final json = {
        'eventStartTime': now.toIso8601String(),
        'eventEndTime': now.add(const Duration(hours: 1)).toIso8601String(),
        'roomID': 'room1',
        'roomName': 'Room 1',
        'ignoreOverlaps': false,
      };
      final request = Request.fromJson(json);
      expect(request.hasPendingAmendment, isFalse);
    });

    test('reads true from JSON when present', () {
      final json = {
        'eventStartTime': now.toIso8601String(),
        'eventEndTime': now.add(const Duration(hours: 1)).toIso8601String(),
        'roomID': 'room1',
        'roomName': 'Room 1',
        'ignoreOverlaps': false,
        'hasPendingAmendment': true,
      };
      final request = Request.fromJson(json);
      expect(request.hasPendingAmendment, isTrue);
    });

    test('is excluded from toJson output', () {
      final request = baseRequest.copyWith(hasPendingAmendment: true);
      final json = request.toJson();
      expect(json.containsKey('hasPendingAmendment'), isFalse);
    });
  });
}
