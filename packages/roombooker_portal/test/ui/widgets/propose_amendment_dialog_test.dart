import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/entities/organization.dart';
import 'package:roombooker_core/data/entities/request.dart';
import 'package:roombooker_core/data/repos/room_repo.dart';
import 'package:roombooker_core/data/services/booking_service.dart';
import 'package:roombooker_portal/ui/widgets/propose_amendment_dialog.dart';

class MockBookingService extends Mock implements BookingService {}

class MockRoomRepo extends Mock implements RoomRepo {}

void main() {
  late MockBookingService mockBookingService;
  late MockRoomRepo mockRoomRepo;

  // A future recurring booking — both conditions for "Propose Change" to show.
  final recurringRequest = Request(
    id: 'req1',
    roomID: 'room1',
    roomName: 'Room 1',
    eventStartTime: DateTime.now().add(const Duration(days: 7)),
    eventEndTime: DateTime.now().add(
      const Duration(days: 7, hours: 1),
    ),
    status: RequestStatus.confirmed,
    recurrancePattern: RecurrancePattern.weekly(on: Weekday.monday),
  );

  setUp(() {
    mockBookingService = MockBookingService();
    mockRoomRepo = MockRoomRepo();
    when(() => mockRoomRepo.listRooms(any())).thenAnswer(
      (_) => Stream.value([Room(id: 'room1', name: 'Room 1')]),
    );
  });

  // Builds a widget that has a button which:
  // 1. Opens an info dialog (simulating _showRequestDialog)
  // 2. From within that dialog's onPressed, pops it and calls
  //    showProposeAmendmentDialog with the OUTER (screen) context.
  Widget buildTestWidget() {
    return MultiProvider(
      providers: [
        Provider<BookingService>.value(value: mockBookingService),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (screenContext) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: screenContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Info'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          // Mirrors the fixed _showRequestDialog flow:
                          // pop with dialogContext, propose with screenContext.
                          Navigator.pop(dialogContext);
                          showProposeAmendmentDialog(
                            context: screenContext,
                            orgID: 'org1',
                            request: recurringRequest,
                            bookingService: mockBookingService,
                          );
                        },
                        child: const Text('Propose Change'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'scope picker appears then amendment form shows after selecting scope',
    (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Open the info dialog.
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Info'), findsOneWidget);

      // Tap "Propose Change" — info dialog pops, scope picker opens.
      await tester.tap(find.text('Propose Change'));
      await tester.pumpAndSettle();
      expect(find.text('Which events to change?'), findsOneWidget);

      // Select "This event only".
      await tester.tap(find.text('This event only'));
      await tester.pumpAndSettle();

      // Amendment form must now be visible.
      expect(find.text('Propose a Change'), findsOneWidget);
    },
  );

  testWidgets(
    'amendment form shows directly for non-recurring booking (no scope picker)',
    (tester) async {
      final oneOffRequest = Request(
        id: 'req2',
        roomID: 'room1',
        roomName: 'Room 1',
        eventStartTime: DateTime.now().add(const Duration(days: 7)),
        eventEndTime: DateTime.now().add(const Duration(days: 7, hours: 1)),
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern.never(),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<BookingService>.value(value: mockBookingService),
            ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (screenContext) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: screenContext,
                      builder: (dialogContext) => AlertDialog(
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              showProposeAmendmentDialog(
                                context: screenContext,
                                orgID: 'org1',
                                request: oneOffRequest,
                                bookingService: mockBookingService,
                              );
                            },
                            child: const Text('Propose Change'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Propose Change'));
      await tester.pumpAndSettle();

      // No scope picker for non-recurring — form appears directly.
      expect(find.text('Which events to change?'), findsNothing);
      expect(find.text('Propose a Change'), findsOneWidget);
    },
  );

  // Helper that opens the amendment form for a non-recurring request directly.
  Widget buildOneOffTestWidget(Request request) {
    return MultiProvider(
      providers: [
        Provider<BookingService>.value(value: mockBookingService),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (screenContext) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: screenContext,
                  builder: (dialogContext) => AlertDialog(
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          showProposeAmendmentDialog(
                            context: screenContext,
                            orgID: 'org1',
                            request: request,
                            bookingService: mockBookingService,
                          );
                        },
                        child: const Text('Propose Change'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'amendment form uses fullscreen layout on narrow viewport',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final oneOffRequest = Request(
        id: 'req3',
        roomID: 'room1',
        roomName: 'Room 1',
        eventStartTime: DateTime.now().add(const Duration(days: 7)),
        eventEndTime: DateTime.now().add(const Duration(days: 7, hours: 1)),
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern.never(),
      );

      await tester.pumpWidget(buildOneOffTestWidget(oneOffRequest));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Propose Change'));
      await tester.pumpAndSettle();

      // Narrow viewport → fullscreen scaffold with AppBar, no AlertDialog.
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'amendment form uses AlertDialog layout on wide viewport',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final oneOffRequest = Request(
        id: 'req4',
        roomID: 'room1',
        roomName: 'Room 1',
        eventStartTime: DateTime.now().add(const Duration(days: 7)),
        eventEndTime: DateTime.now().add(const Duration(days: 7, hours: 1)),
        status: RequestStatus.confirmed,
        recurrancePattern: RecurrancePattern.never(),
      );

      await tester.pumpWidget(buildOneOffTestWidget(oneOffRequest));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Propose Change'));
      await tester.pumpAndSettle();

      // Wide viewport → constrained AlertDialog, no fullscreen AppBar.
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
    },
  );
}
