import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/request_editor/logs_widget.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:room_booker/ui/widgets/room_selector.dart';

import '../../../utils/fake_logging_service.dart';

class MockRequestEditorViewModel extends Mock
    implements RequestEditorViewModel {}

class MockOrgState extends Mock implements OrgState {}

class MockRoomState extends Mock implements RoomState {}

class MockRepeatBookingsViewModel extends Mock
    implements RepeatBookingsViewModel {}

class MockRoomRepo extends Mock implements RoomRepo {}

void main() {
  late MockRequestEditorViewModel mockViewModel;
  late MockOrgState mockOrgState;
  late MockRoomState mockRoomState;
  late MockRepeatBookingsViewModel mockRepeatBookingsViewModel;
  late MockRoomRepo mockRoomRepo;

  setUp(() {
    mockViewModel = MockRequestEditorViewModel();
    mockOrgState = MockOrgState();
    mockRoomState = MockRoomState();
    mockRepeatBookingsViewModel = MockRepeatBookingsViewModel();
    mockRoomRepo = MockRoomRepo();

    // Setup default behaviors for ViewModel
    when(() => mockViewModel.editorTitle).thenReturn('Test Editor');
    when(() => mockViewModel.orgID).thenReturn('test-org');
    when(() => mockViewModel.formKey).thenReturn(GlobalKey<FormState>());

    // Text Controllers
    when(
      () => mockViewModel.eventNameContoller,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.phoneNumberController,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.contactNameController,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.contactEmailController,
    ).thenReturn(TextEditingController());
    when(
      () => mockViewModel.additionalInfoController,
    ).thenReturn(TextEditingController());
    when(() => mockViewModel.idController).thenReturn(TextEditingController());

    // Streams
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(
        EditorViewState(
          true, // readOnly
          showIgnoreOverlapsToggle: false,
          showEventLog: false,
          showID: false,
          actions: [],
        ),
      ),
    );
    when(
      () => mockViewModel.isPublicStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      () => mockViewModel.ignoreOverlapsStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      () => mockViewModel.eventStartStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(() => mockViewModel.eventTimeStream).thenAnswer(
      (_) => Stream.value((
        DateTime.now(),
        DateTime.now().add(const Duration(hours: 1)),
      )),
    );
    when(
      () => mockViewModel.currentDataStream(),
    ).thenAnswer((_) => Stream.value((null, null)));

    // Important: Stub room streams to return a room present in the list
    // RoomDropdownSelector will select initialRoomID if provided (passed to it)
    // or we select via onChanged.
    // The RequestEditor widget doesn't pass an initialRoomID to RoomDropdownSelector directly,
    // RoomDropdownSelector handles its own selection via RoomRepo or similar?
    // Wait, RoomDropdownSelector signature:
    // RoomDropdownSelector({this.initialRoomID, ...})
    // In RequestEditor: _roomSelector just calls RoomDropdownSelector(...).
    // It doesn't pass initialRoomID.
    // So it defaults to null selection or first available.
    // But if I mocked `listRooms` to return empty list, `firstWhere` fails if it tries to select something?
    // Or maybe RoomDropdownSelector logic is faulty for empty list.
    // Let's provide a room.

    when(
      () => mockViewModel.roomIDStream,
    ).thenAnswer((_) => Stream.value('room1'));
    when(
      () => mockViewModel.roomNameStream,
    ).thenAnswer((_) => Stream.value('Room 1'));
    when(() => mockViewModel.roomID).thenReturn('room1');

    // RepeatBookingsViewModel
    when(
      () => mockViewModel.repeatBookingsViewModel,
    ).thenReturn(mockRepeatBookingsViewModel);
    when(
      () => mockRepeatBookingsViewModel.patternStream,
    ).thenAnswer((_) => Stream.value(RecurrancePattern.never()));
    when(
      () => mockRepeatBookingsViewModel.isCustomStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      () => mockRepeatBookingsViewModel.startTimeStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(
      () => mockRepeatBookingsViewModel.readOnlyStream,
    ).thenAnswer((_) => Stream.value(true));

    // OrgState
    when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
    when(() => mockOrgState.org).thenReturn(
      Organization(
        id: 'test-org',
        name: 'Test Org',
        ownerID: 'owner',
        acceptingAdminRequests: true,
      ),
    );

    // RoomRepo
    when(
      () => mockRoomRepo.listRooms(any()),
    ).thenAnswer((_) => Stream.value([Room(id: 'room1', name: 'Room 1')]));
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
        ChangeNotifierProvider<LoggingService>.value(
          value: FakeLoggingService(),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: RequestEditor())),
    );
  }

  testWidgets('RequestEditor renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Test Editor'), findsOneWidget);
    expect(find.text('Event Name'), findsOneWidget);
    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('End Time'), findsOneWidget);
  });

  testWidgets('Close button calls closeEditor and onClose callback', (
    tester,
  ) async {
    bool onCloseCalled = false;
    when(() => mockViewModel.closeEditor()).thenAnswer((_) async => "");

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OrgState>.value(value: mockOrgState),
          ChangeNotifierProvider<RoomState>.value(value: mockRoomState),
          ChangeNotifierProvider<RequestEditorViewModel>.value(
            value: mockViewModel,
          ),
          ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
          ChangeNotifierProvider<LoggingService>.value(
            value: FakeLoggingService(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RequestEditor(
              onClose: () {
                onCloseCalled = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    verify(() => mockViewModel.closeEditor()).called(1);
    expect(onCloseCalled, true);
  });

  testWidgets('Shows ignore overlaps toggle when visible in state', (
    tester,
  ) async {
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(
        EditorViewState(
          true,
          showIgnoreOverlapsToggle: true,
          showEventLog: false,
          showID: false,
          actions: [],
        ),
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Ignore overlapping events'), findsOneWidget);
  });

  testWidgets('Initializes room selector with viewModel.roomID', (
    tester,
  ) async {
    // Setup specific mocks for this test
    when(() => mockViewModel.roomID).thenReturn('room2');
    when(() => mockRoomRepo.listRooms(any())).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1'),
        Room(id: 'room2', name: 'Room 2'),
      ]),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Find the dropdown and verify it shows 'Room 2'
    expect(find.text('Room 2'), findsOneWidget);
  });

  testWidgets('Toggles public setting calls updateIsPublic', (tester) async {
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(
        EditorViewState(
          false,
          actions: [],
          showIgnoreOverlapsToggle: false,
          showEventLog: false,
          showID: false,
        ),
      ),
    );
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show name on parish calendar'));
    verify(() => mockViewModel.updateIsPublic(any())).called(1);
  });

  testWidgets('Toggles ignore overlaps calls updateIgnoreOverlaps', (
    tester,
  ) async {
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(
        EditorViewState(
          false,
          showIgnoreOverlapsToggle: true,
          actions: [],
          showEventLog: false,
          showID: false,
        ),
      ),
    );
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ignore overlapping events'));
    verify(() => mockViewModel.updateIgnoreOverlaps(any())).called(1);
  });

  testWidgets('Changing room calls updateRoom', (tester) async {
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(
        EditorViewState(
          false,
          actions: [],
          showIgnoreOverlapsToggle: false,
          showEventLog: false,
          showID: false,
        ),
      ),
    );
    // Setup multiple rooms
    var room1 = Room(id: 'room1', name: 'Room 1');
    var room2 = Room(id: 'room2', name: 'Room 2');
    when(
      () => mockRoomRepo.listRooms(any()),
    ).thenAnswer((_) => Stream.value([room1, room2]));

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Open dropdown
    await tester.tap(find.text('Room 1'));
    await tester.pumpAndSettle();

    // Select Room 2
    // Use last because both the selected item and the menu item might be found
    await tester.tap(find.text('Room 2').last);
    await tester.pump();

    verify(() => mockViewModel.updateRoom(room2)).called(1);
  });

  group('Admin Functions', () {
    testWidgets(
      'Shows "Use My Info" for admins and calls useAdminContactInfo',
      (tester) async {
        when(() => mockOrgState.currentUserIsAdmin).thenReturn(true);
        when(() => mockViewModel.useAdminContactInfo()).thenReturn(null);
        when(() => mockViewModel.viewStateStream).thenAnswer(
          (_) => Stream.value(
            EditorViewState(
              false,
              actions: [],
              showIgnoreOverlapsToggle: false,
              showEventLog: false,
              showID: false,
            ),
          ),
        );
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Use My Info'), findsOneWidget);
        await tester.ensureVisible(find.text('Use My Info'));
        await tester.tap(find.text('Use My Info'));
        verify(() => mockViewModel.useAdminContactInfo()).called(1);
      },
    );

    testWidgets('Hides "Use My Info" for non-admins', (tester) async {
      when(() => mockOrgState.currentUserIsAdmin).thenReturn(false);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Use My Info'), findsNothing);
    });
  });

  group('Conditional Elements', () {
    testWidgets('Shows Request ID when enabled', (tester) async {
      when(() => mockViewModel.viewStateStream).thenAnswer(
        (_) => Stream.value(
          EditorViewState(
            false,
            actions: [],
            showID: true,
            showIgnoreOverlapsToggle: false,
            showEventLog: false,
          ),
        ),
      );
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Request ID'), findsOneWidget);
    });

    testWidgets('Shows Event Log when enabled', (tester) async {
      when(() => mockViewModel.viewStateStream).thenAnswer(
        (_) => Stream.value(
          EditorViewState(
            false,
            actions: [],
            showID: false,
            showIgnoreOverlapsToggle: false,
            showEventLog: true,
          ),
        ),
      );

      // Provide data for LogsWidget
      var request = Request(
        id: 'req1',
        eventStartTime: DateTime.now(),
        eventEndTime: DateTime.now().add(const Duration(hours: 1)),
        roomID: 'room1',
        roomName: 'Room 1',
      );
      when(
        () => mockViewModel.currentDataStream(),
      ).thenAnswer((_) => Stream.value((request, null)));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(LogsWidget), findsOneWidget);
    });
  });

  group('Action Buttons', () {
    testWidgets('Renders action buttons from state', (tester) async {
      var action = EditorAction('Test Action', () async {
        return ActionResult(true, "Success", false);
      });

      when(() => mockViewModel.viewStateStream).thenAnswer(
        (_) => Stream.value(
          EditorViewState(
            false,
            actions: [action],
            showIgnoreOverlapsToggle: false,
            showEventLog: false,
            showID: false,
          ),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Test Action'), findsOneWidget);
    });

    testWidgets('Tapping action button calls onPressed', (tester) async {
      bool actionCalled = false;
      var action = EditorAction('Test Action', () async {
        actionCalled = true;
        return ActionResult(true, "Success", false);
      });

      when(() => mockViewModel.viewStateStream).thenAnswer(
        (_) => Stream.value(
          EditorViewState(
            false,
            actions: [action],
            showIgnoreOverlapsToggle: false,
            showEventLog: false,
            showID: false,
          ),
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Test Action'));
      await tester.tap(find.text('Test Action'));
      expect(actionCalled, true);
    });

    testWidgets('Action button closes editor if result says so', (
      tester,
    ) async {
      bool onCloseCalled = false;
      var action = EditorAction('Close Action', () async {
        return ActionResult(true, "Success", true);
      });

      when(() => mockViewModel.viewStateStream).thenAnswer(
        (_) => Stream.value(
          EditorViewState(
            false,
            actions: [action],
            showIgnoreOverlapsToggle: false,
            showEventLog: false,
            showID: false,
          ),
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrgState>.value(value: mockOrgState),
            ChangeNotifierProvider<RoomState>.value(value: mockRoomState),
            ChangeNotifierProvider<RequestEditorViewModel>.value(
              value: mockViewModel,
            ),
            ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
            ChangeNotifierProvider<LoggingService>.value(
              value: FakeLoggingService(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: RequestEditor(
                onClose: () {
                  onCloseCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Close Action'));
      await tester.tap(find.text('Close Action'));
      await tester.pump(); // For the async action
      await tester.pump(); // For the snackbar and close callback

      expect(onCloseCalled, true);
    });
  });

  group('Validation', () {
    testWidgets('Validates Event Name (required)', (tester) async {
      final realFormKey = GlobalKey<FormState>();
      when(() => mockViewModel.formKey).thenReturn(realFormKey);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Trigger validation
      realFormKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('Please provide a name'), findsOneWidget);
    });

    testWidgets('Validates Email (format)', (tester) async {
      final realFormKey = GlobalKey<FormState>();
      when(() => mockViewModel.formKey).thenReturn(realFormKey);

      final emailController = TextEditingController(text: "invalid-email");
      when(
        () => mockViewModel.contactEmailController,
      ).thenReturn(emailController);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Trigger validation
      realFormKey.currentState!.validate();
      await tester.pumpAndSettle();

      expect(find.text('Please provide your email'), findsOneWidget);
    });
  });
}
