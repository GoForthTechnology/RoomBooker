import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/widgets/room_list_widget.dart';

class MockRoomRepo extends Mock implements RoomRepo {}

// Fake class for Room since we might need to use it in specific matchers or just nice to have
class FakeRoom extends Fake implements Room {}

void main() {
  late MockRoomRepo mockRepo;
  late Organization testOrg;
  late StreamController<List<Room>> roomStreamController;

  setUp(() {
    mockRepo = MockRoomRepo();
    testOrg = Organization(
      id: 'org1',
      name: 'Test Org',
      ownerID: 'owner1',
      acceptingAdminRequests: true,
    );
    roomStreamController = StreamController<List<Room>>();

    // Register fallback values if needed
    registerFallbackValue(
        Room(name: 'Fallback Room', colorHex: '#000000', orderKey: 0));
    registerFallbackValue(
        <Room>[]); // For List<Room> if needed, though usually not for simple args
  });

  tearDown(() {
    roomStreamController.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<RoomRepo>.value(
          value: mockRepo,
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
}
