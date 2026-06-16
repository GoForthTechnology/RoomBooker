import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_core/data/repos/room_repo.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:roombooker_portal/ui/widgets/room_list_widget.dart';

class MockRoomRepo extends Mock implements RoomRepo {}

class MockProvisioningService extends Mock implements ProvisioningService {}

class FakeRoom extends Fake implements Room {}

void main() {
  late MockRoomRepo mockRepo;
  late MockProvisioningService mockProvisioningService;
  late Organization testOrg;
  late StreamController<List<Room>> roomStreamController;

  setUp(() {
    mockRepo = MockRoomRepo();
    mockProvisioningService = MockProvisioningService();
    testOrg = Organization(
      id: 'org1',
      name: 'Test Org',
      ownerID: 'owner1',
      acceptingAdminRequests: true,
    );
    roomStreamController = StreamController<List<Room>>();

    registerFallbackValue(
        Room(name: 'Fallback Room', colorHex: '#000000', orderKey: 0));
    registerFallbackValue(<Room>[]);

  });

  tearDown(() {
    roomStreamController.close();
  });

  void stubKioskGrants(List<KioskGrantRecord> grants) {
    when(() => mockProvisioningService.listKioskGrants(
          orgID: any(named: 'orgID'),
          roomID: any(named: 'roomID'),
        )).thenAnswer((_) => Stream.value(grants));
  }

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiProvider(
          providers: [
            ChangeNotifierProvider<RoomRepo>.value(value: mockRepo),
            Provider<ProvisioningService>.value(
                value: mockProvisioningService),
          ],
          child: RoomListWidget(
            org: testOrg,
            repo: mockRepo,
          ),
        ),
      ),
    );
  }

  testWidgets('displays loading indicator when stream is waiting',
      (WidgetTester tester) async {
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => roomStreamController.stream);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('displays "No rooms found" when list is empty',
      (WidgetTester tester) async {
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value([])); // Immediate empty list

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Process stream

    expect(find.text('No rooms found. Please add one.'), findsOneWidget);
  });

  testWidgets('displays list of rooms', (WidgetTester tester) async {
    final rooms = [
      Room(name: 'Room A', id: '1', colorHex: '#FF0000'),
      Room(name: 'Room B', id: '2', colorHex: '#00FF00'),
    ];
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value(rooms));
    stubKioskGrants([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Room A'), findsOneWidget);
    expect(find.text('Room B'), findsOneWidget);
    expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));
  });

  testWidgets('adds a room', (WidgetTester tester) async {
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value([]));
    when(() => mockRepo.addRoom(any(), any()))
        .thenAnswer((_) async => 'new_id');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Tap "Add Room"
    await tester.tap(find.text('Add Room'));
    await tester.pumpAndSettle();

    // Enter room name
    await tester.enterText(find.byType(TextFormField), 'New Room');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.addRoom(testOrg.id!, any(that: isA<Room>().having((r) => r.name, 'name', 'New Room')))).called(1);
  });

  testWidgets('deletes a room', (WidgetTester tester) async {
    final room = Room(name: 'Room A', id: '1');
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value([room]));
    when(() => mockRepo.removeRoom(any(), any())).thenAnswer((_) async {});
    stubKioskGrants([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Tap delete icon
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle(); // Dialog appears

    // Confirm delete
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.removeRoom(testOrg.id!, room.id!)).called(1);
  });

  testWidgets('edits a room', (WidgetTester tester) async {
    final room = Room(name: 'Room A', id: '1', colorHex: '#000000');
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value([room]));
    when(() => mockRepo.updateRoom(any(), any())).thenAnswer((_) async {});
    stubKioskGrants([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Tap edit icon
    await tester.tap(find.byIcon(Icons.edit).first);
    await tester.pumpAndSettle(); // Dialog appears

    // Change name
    await tester.enterText(find.byType(TextFormField), 'Updated Room');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.updateRoom(testOrg.id!, any(that: isA<Room>().having((r) => r.name, 'name', 'Updated Room')))).called(1);
  });

  testWidgets('shows Link Kiosk button when no grant exists',
      (WidgetTester tester) async {
    final room = Room(name: 'Room A', id: '1');
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value([room]));
    stubKioskGrants([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.screenshot_monitor), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsNothing);
  });

  testWidgets('shows Revoke button when a grant exists',
      (WidgetTester tester) async {
    final room = Room(name: 'Room A', id: '1');
    when(() => mockRepo.listRooms(any()))
        .thenAnswer((_) => Stream.value([room]));
    stubKioskGrants([
      KioskGrantRecord(
        uid: 'uid-1',
        deviceID: 'device-abc123',
        createdAt: DateTime(2026, 1, 15),
      ),
    ]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // settle room list stream
    await tester.pump(); // settle kiosk-grants stream

    expect(find.byIcon(Icons.link_off), findsOneWidget);
    // connected state shows small green screenshot_monitor + link_off (revoke) side by side
  });
}
