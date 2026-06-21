import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roombooker_core/data/entities/booking_amendment.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_portal/ui/widgets/booking_list/amendment_diff_widget.dart';

class MockBookingService extends Mock implements BookingService {}

void main() {
  late MockBookingService mockService;

  final now = DateTime(2025, 6, 1, 10, 0);
  final currentRequest = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room 1',
    eventStartTime: now,
    eventEndTime: now.add(const Duration(hours: 1)),
    status: RequestStatus.confirmed,
    recurrancePattern: RecurrancePattern.never(),
  );
  final proposedRequest = currentRequest.copyWith(
    roomID: 'room2',
    roomName: 'Room 2',
    eventStartTime: now.add(const Duration(hours: 2)),
    eventEndTime: now.add(const Duration(hours: 3)),
  );
  final proposedDetails = PrivateRequestDetails(
    eventName: 'Team Sync',
    name: 'Alice',
    email: 'alice@example.com',
    phone: '555-1234',
  );

  setUp(() {
    mockService = MockBookingService();
    registerFallbackValue(currentRequest);
    registerFallbackValue(
      BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
      ),
    );
  });

  Widget buildWidget(BookingAmendment amendment) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: AmendmentDiffWidget(
            orgID: 'org1',
            currentRequest: currentRequest,
            amendment: amendment,
            bookingService: mockService,
          ),
        ),
      ),
    );
  }

  group('AmendmentDiffWidget', () {
    testWidgets('shows proposer contact info', (tester) async {
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );

      await tester.pumpWidget(buildWidget(amendment));

      expect(find.text('Alice — alice@example.com'), findsOneWidget);
      expect(find.text('555-1234'), findsOneWidget);
    });

    testWidgets('shows changed fields in diff table', (tester) async {
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );

      await tester.pumpWidget(buildWidget(amendment));

      expect(find.text('Room 1'), findsOneWidget);
      expect(find.text('Room 2'), findsOneWidget);
    });

    testWidgets('shows thisAndFuture scope label for recurring amendment',
        (tester) async {
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisAndFuture,
        proposedAt: now,
      );

      await tester.pumpWidget(buildWidget(amendment));

      expect(find.text('Scope: This and future events'), findsOneWidget);
    });

    testWidgets('shows thisInstance scope label', (tester) async {
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );

      await tester.pumpWidget(buildWidget(amendment));

      expect(find.text('Scope: This event only'), findsOneWidget);
    });

    testWidgets('Apply Amendment button calls applyAmendment', (tester) async {
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );

      when(
        () => mockService.applyAmendment('org1', currentRequest, amendment),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget(amendment));
      await tester.tap(find.text('Apply Amendment'));
      await tester.pump();

      verify(
        () => mockService.applyAmendment('org1', currentRequest, amendment),
      ).called(1);
    });

    testWidgets('Reject button calls rejectAmendment', (tester) async {
      final amendment = BookingAmendment(
        proposedRequest: proposedRequest,
        proposedDetails: proposedDetails,
        scope: AmendmentScope.thisInstance,
        proposedAt: now,
        instanceStartDate: now,
      );

      when(
        () => mockService.rejectAmendment('org1', 'req1'),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(buildWidget(amendment));
      await tester.tap(find.text('Reject'));
      await tester.pump();

      verify(() => mockService.rejectAmendment('org1', 'req1')).called(1);
    });
  });
}
