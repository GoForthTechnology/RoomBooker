import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

class MockRequestEditorViewModel extends Mock
    implements RequestEditorViewModel {
  @override
  bool readOnly = false;
}

class MockOrgState extends Mock implements OrgState {}

class MockRoomState extends Mock implements RoomState {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockRoom extends Mock implements Room {}

void main() {
  late MockRequestEditorViewModel mockViewModel;
  late MockOrgState mockOrgState;
  late MockRoomState mockRoomState;
  late MockRoomRepo mockRoomRepo;
  late StreamController<(DateTime, DateTime)> eventTimeController;

  setUp(() {
    mockViewModel = MockRequestEditorViewModel();
    mockOrgState = MockOrgState();
    mockRoomState = MockRoomState();
    mockRoomRepo = MockRoomRepo();

    // Default stubs for ViewModel
    when(() => mockViewModel.editorTitle).thenReturn('New Request');
    when(() => mockViewModel.closeEditor()).thenAnswer((_) async => '');
    when(() => mockViewModel.orgID).thenReturn('org1');
    when(() => mockViewModel.initialRequest).thenReturn(
      Request(
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'room1',
        roomName: 'Room 1',
      ),
    );
    when(
      () => mockViewModel.eventNameContoller,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.contactNameController,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.contactEmailController,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.phoneNumberController,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.additionalInfoController,
    ).thenReturn(TextEditingController());
    when(() => mockViewModel.idController).thenReturn(TextEditingController());
    when(() => mockViewModel.formKey).thenReturn(GlobalKey<FormState>());

    when(
      () => mockViewModel.isPublicStream,
    ).thenAnswer((_) => BehaviorSubject.seeded(false));
    when(
      () => mockViewModel.ignoreOverlapsStream,
    ).thenAnswer((_) => BehaviorSubject.seeded(false));

    when(
      () => mockViewModel.eventStartStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(() => mockViewModel.eventEndStream).thenAnswer(
      (_) => Stream.value(DateTime.now().add(const Duration(hours: 1))),
    );
    eventTimeController = StreamController<(DateTime, DateTime)>.broadcast();

    when(
      () => mockViewModel.eventTimeStream,
    ).thenAnswer((_) => eventTimeController.stream);
    final mockRoom = MockRoom();
    when(() => mockRoom.id).thenReturn('room1');
    when(() => mockRoom.name).thenReturn('Room 1');

    when(
      () => mockRoomRepo.listRooms(any()),
    ).thenAnswer((_) => BehaviorSubject.seeded([mockRoom]));

    when(() => mockViewModel.showIgnoreOverlapsToggle()).thenReturn(false);
    when(() => mockViewModel.showID()).thenReturn(false);
    when(() => mockViewModel.showEventLog()).thenReturn(false);
    when(() => mockViewModel.getActions()).thenReturn([]);

    // Default stubs for OrgState
    when(() => mockOrgState.currentUserIsAdmin()).thenReturn(false);
    when(() => mockOrgState.org).thenReturn(
      Organization(
        id: 'org1',
        name: 'Test Org',
        ownerID: 'owner1',
        acceptingAdminRequests: true,
      ),
    );

    // Default stubs for RoomState
    when(() => mockRoomState.allRooms()).thenReturn([]);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgState>.value(value: mockOrgState),
        ChangeNotifierProvider<RoomState>.value(value: mockRoomState),
        ChangeNotifierProvider<RequestEditorViewModel>.value(
          value: mockViewModel,
        ),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
      ],
      child: const MaterialApp(home: Scaffold(body: RequestEditor())),
    );
  }

  testWidgets('RequestEditor renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    eventTimeController.add((
      DateTime.now(),
      DateTime.now().add(const Duration(hours: 1)),
    ));
    await tester.pump();

    expect(find.text('New Request'), findsOneWidget);
    expect(find.text('Event Name'), findsOneWidget);
    expect(find.text('Show name on parish calendar'), findsOneWidget);
    expect(find.text('Event Date'), findsOneWidget);
    expect(find.text('Event Name'), findsOneWidget);
    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('End Time'), findsOneWidget);
    expect(find.text('Your Name'), findsOneWidget);
    expect(find.text('Your Email'), findsOneWidget);
    expect(find.text('Your Phone Number'), findsOneWidget);
    expect(find.text('Additional Info'), findsOneWidget);
  });

  testWidgets('RequestEditor shows admin controls when user is admin', (
    WidgetTester tester,
  ) async {
    when(() => mockOrgState.currentUserIsAdmin()).thenReturn(true);
    when(() => mockViewModel.showIgnoreOverlapsToggle()).thenReturn(true);
    when(() => mockViewModel.showID()).thenReturn(true);
    when(() => mockViewModel.showEventLog()).thenReturn(true);
    when(() => mockViewModel.initialRequest).thenReturn(
      Request(
        id: 'req1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'room1',
        roomName: 'Room 1',
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Ignore overlapping events'), findsOneWidget);
    expect(find.text('Use My Info'), findsOneWidget);
    expect(find.text('Request ID'), findsOneWidget);
    // LogsWidget might need more setup or just check for its presence if it has text
  });

  testWidgets('RequestEditor calls closeEditor on close button tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.close));
    verify(() => mockViewModel.closeEditor()).called(1);
  });

  test('Rx.combineLatest2 works', () async {
    final s1 = BehaviorSubject.seeded(1);
    final s2 = BehaviorSubject.seeded(2);
    final combined = Rx.combineLatest2(s1, s2, (a, b) => (a, b));
    expect(await combined.first, (1, 2));
  });
}
