import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/request.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_screen.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/booking_calendar/booking_calendar.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/navigation_drawer.dart';
import 'package:room_booker/ui/widgets/request_editor/repeat_booking_selector/repeat_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockRoomRepo extends Mock implements RoomRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockPreferencesRepo extends Mock implements PreferencesRepo {}

class MockFirebaseAuthService extends Mock implements FirebaseAuthService {}

class MockFirebaseAnalyticsService extends Mock
    implements FirebaseAnalyticsService {}

class MockStackRouter extends Mock implements StackRouter {}

class MockViewBookingsViewModel extends Mock implements ViewBookingsViewModel {}

class MockCalendarViewModel extends Mock implements CalendarViewModel {}

class MockRequestEditorViewModel extends Mock
    implements RequestEditorViewModel {}

class MockRepeatBookingsViewModel extends Mock
    implements RepeatBookingsViewModel {}

class FakeBuildContext extends Fake implements BuildContext {}

class FakeDataSource extends CalendarDataSource {
  FakeDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class FakeAppointmentResizeEndDetails extends Fake
    implements AppointmentResizeEndDetails {}

class FakeAppointmentDragEndDetails extends Fake
    implements AppointmentDragEndDetails {}

class FakeCalendarTapDetails extends Fake implements CalendarTapDetails {}

class FakeRequestStream extends Fake
    implements Stream<(Request?, PrivateRequestDetails?)> {}

void main() {
  Provider.debugCheckInvalidValueType = null;

  setUpAll(() {
    registerFallbackValue(FakeBuildContext());
    registerFallbackValue(FakeAppointmentResizeEndDetails());
    registerFallbackValue(FakeAppointmentDragEndDetails());
    registerFallbackValue(FakeCalendarTapDetails());
    registerFallbackValue(FakeRequestStream());
  });

  late MockOrgRepo mockOrgRepo;
  late MockRoomRepo mockRoomRepo;
  late MockBookingRepo mockBookingRepo;
  late MockPreferencesRepo mockPreferencesRepo;
  late MockFirebaseAuthService mockAuthService;
  late MockFirebaseAnalyticsService mockAnalyticsService;
  late MockStackRouter mockRouter;

  late MockViewBookingsViewModel mockViewModel;
  late MockCalendarViewModel mockCalendarViewModel;
  late MockRequestEditorViewModel mockRequestEditorViewModel;
  late MockRepeatBookingsViewModel mockRepeatBookingsViewModel;

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockRoomRepo = MockRoomRepo();
    mockBookingRepo = MockBookingRepo();
    mockPreferencesRepo = MockPreferencesRepo();
    mockAuthService = MockFirebaseAuthService();
    mockAnalyticsService = MockFirebaseAnalyticsService();
    mockRouter = MockStackRouter();

    mockViewModel = MockViewBookingsViewModel();
    mockCalendarViewModel = MockCalendarViewModel();
    mockRequestEditorViewModel = MockRequestEditorViewModel();
    mockRepeatBookingsViewModel = MockRepeatBookingsViewModel();

    // Default stubs
    when(
      () => mockAnalyticsService.logScreenView(
        screenName: any(named: 'screenName'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(ViewState(showRoomSelector: true, showEditor: false)),
    );
    when(() => mockViewModel.isSmallView()).thenReturn(false);
    when(() => mockViewModel.getActions(any())).thenReturn([]);
    when(() => mockViewModel.toggleRoomSelector()).thenReturn(null);
    when(() => mockViewModel.onAddNewBooking()).thenReturn(null);

    // Mock RequestEditorViewModel
    when(
      () => mockRequestEditorViewModel.repeatBookingsViewModel,
    ).thenReturn(mockRepeatBookingsViewModel);
    when(
      () => mockRequestEditorViewModel.editorTitle,
    ).thenReturn("Test Editor");
    when(() => mockRequestEditorViewModel.orgID).thenReturn("org1");
    when(
      () => mockRequestEditorViewModel.eventNameContoller,
    ).thenReturn(TextEditingController());
    when(
      () => mockRequestEditorViewModel.contactNameController,
    ).thenReturn(TextEditingController());
    when(
      () => mockRequestEditorViewModel.contactEmailController,
    ).thenReturn(TextEditingController());
    when(
      () => mockRequestEditorViewModel.phoneNumberController,
    ).thenReturn(TextEditingController());
    when(
      () => mockRequestEditorViewModel.additionalInfoController,
    ).thenReturn(TextEditingController());
    when(
      () => mockRequestEditorViewModel.idController,
    ).thenReturn(TextEditingController());

    when(
      () => mockRequestEditorViewModel.isPublicStream,
    ).thenAnswer((_) => Stream.value(true));
    when(
      () => mockRequestEditorViewModel.ignoreOverlapsStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      () => mockRequestEditorViewModel.eventStartStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(() => mockRequestEditorViewModel.eventEndStream).thenAnswer(
      (_) => Stream.value(DateTime.now().add(const Duration(hours: 1))),
    );
    when(() => mockRequestEditorViewModel.eventTimeStream).thenAnswer(
      (_) => Stream.value((
        DateTime.now(),
        DateTime.now().add(const Duration(hours: 1)),
      )),
    );
    when(
      () => mockRequestEditorViewModel.roomIDStream,
    ).thenAnswer((_) => Stream.value("room1"));
    when(
      () => mockRequestEditorViewModel.roomNameStream,
    ).thenAnswer((_) => Stream.value("Room 1"));

    when(() => mockRequestEditorViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(
        EditorViewState(
          false,
          showIgnoreOverlapsToggle: false,
          showEventLog: false,
          showID: false,
          actions: [],
        ),
      ),
    );
    when(
      () => mockRequestEditorViewModel.formKey,
    ).thenReturn(GlobalKey<FormState>());

    // Mock RepeatBookingsViewModel
    when(
      () => mockRepeatBookingsViewModel.patternStream,
    ).thenAnswer((_) => Stream.value(RecurrancePattern.daily()));
    when(
      () => mockRepeatBookingsViewModel.isCustomStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      () => mockRepeatBookingsViewModel.startTimeStream,
    ).thenAnswer((_) => Stream.value(DateTime.now()));
    when(
      () => mockRepeatBookingsViewModel.readOnlyStream,
    ).thenAnswer((_) => Stream.value(false));

    when(
      () => mockCalendarViewModel.controller,
    ).thenReturn(CalendarController());
    when(() => mockCalendarViewModel.calendarViewState()).thenAnswer(
      (_) => Stream.value(
        CalendarViewState(
          dataSource: FakeDataSource([]),
          allowDragAndDrop: false,
          allowAppointmentResize: false,
          specialRegions: [],
          currentView: CalendarView.month,
          currentDate: DateTime.now(),
        ),
      ),
    );
    when(() => mockCalendarViewModel.allowViewNavigation).thenReturn(true);
    when(() => mockCalendarViewModel.minDate).thenReturn(DateTime(2020));
    when(() => mockCalendarViewModel.showNavigationArrow).thenReturn(true);
    when(() => mockCalendarViewModel.showTodayButton).thenReturn(true);
    when(() => mockCalendarViewModel.showDatePickerButton).thenReturn(true);
    when(
      () => mockCalendarViewModel.allowedViews,
    ).thenReturn([CalendarView.month]);
    when(() => mockCalendarViewModel.handleResizeEnd(any())).thenReturn(null);
    when(() => mockCalendarViewModel.handleDragEnd(any())).thenReturn(null);
    when(() => mockCalendarViewModel.handleTap(any())).thenReturn(null);

    // Mock OrgRepo
    when(() => mockOrgRepo.getOrg(any())).thenAnswer(
      (_) => Stream.value(
        Organization(
          id: 'org1',
          name: 'Test Org',
          ownerID: 'owner1',
          acceptingAdminRequests: true,
        ),
      ),
    );
    when(
      () => mockOrgRepo.activeAdmins(any()),
    ).thenAnswer((_) => Stream.value([]));

    // Mock RoomRepo
    when(() => mockRoomRepo.listRooms(any())).thenAnswer(
      (_) => Stream.value([
        Room(id: 'room1', name: 'Room 1', colorHex: '#0000FF'),
      ]),
    );
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
        ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
        ChangeNotifierProvider<PreferencesRepo>.value(
          value: mockPreferencesRepo,
        ),
        Provider<FirebaseAuthService>.value(value: mockAuthService),
        ChangeNotifierProvider<FirebaseAnalyticsService>.value(
          value: mockAnalyticsService,
        ),
      ],
      child: MaterialApp(
        home: StackRouterScope(
          controller: mockRouter,
          stateHash: 0,
          child: ViewBookingsScreen(
            orgID: 'org1',
            createViewModel: (_) => mockViewModel,
            createCalendarViewModel: (_, __) => mockCalendarViewModel,
            createRequestEditorViewModel: (_) => mockRequestEditorViewModel,
          ),
        ),
      ),
    );
  }

  testWidgets('ViewBookingsScreen renders correctly', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Test Org'), findsOneWidget);
    expect(find.byType(ViewBookingsScreen), findsOneWidget);
  });

  testWidgets('ViewBookingsScreen shows FAB and calls onAddNewBooking', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    verify(() => mockViewModel.onAddNewBooking()).called(1);
  });

  testWidgets('ViewBookingsScreen toggles room selector', (tester) async {
    when(() => mockViewModel.isSmallView()).thenReturn(false);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final menuButton = find.byIcon(Icons.menu);
    expect(menuButton, findsOneWidget);

    await tester.tap(menuButton);
    verify(() => mockViewModel.toggleRoomSelector()).called(1);
  });

  testWidgets('ViewBookingsScreen animates drawer visibility', (tester) async {
    final viewStateSubject = BehaviorSubject<ViewState>.seeded(
      ViewState(showRoomSelector: false, showEditor: false),
    );
    when(
      () => mockViewModel.viewStateStream,
    ).thenAnswer((_) => viewStateSubject.stream);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify drawer width is 0
    var drawerFinder = find.byType(MyDrawer);
    var drawerContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: drawerFinder, matching: find.byType(AnimatedContainer))
          .first,
    );
    expect(drawerContainer.constraints!.maxWidth, 0.0);

    // Show drawer
    viewStateSubject.add(ViewState(showRoomSelector: true, showEditor: false));
    await tester.pump(); // Start animation
    await tester.pumpAndSettle(); // Finish animation

    // Verify drawer width is panelWidth (800 / 4 = 200)
    drawerContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: drawerFinder, matching: find.byType(AnimatedContainer))
          .first,
    );
    // AnimatedContainer uses constraints to animate width if width is provided
    // But wait, if width is 0, constraints.maxWidth is 0.
    // If width is 200, constraints.maxWidth is 200.
    // However, AnimatedContainer passes `width` to `Container`, which creates `BoxConstraints.tightFor(width: width)`.
    // So checking constraints.maxWidth is correct.
    expect(drawerContainer.constraints!.maxWidth, 200.0);
  });

  testWidgets('ViewBookingsScreen animates editor visibility', (tester) async {
    final viewStateSubject = BehaviorSubject<ViewState>.seeded(
      ViewState(showRoomSelector: false, showEditor: false),
    );
    when(
      () => mockViewModel.viewStateStream,
    ).thenAnswer((_) => viewStateSubject.stream);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify editor width is 0
    var editorFinder = find.byType(RequestEditor);
    var editorContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: editorFinder, matching: find.byType(AnimatedContainer))
          .first,
    );
    expect(editorContainer.constraints!.maxWidth, 0.0);

    // Show editor
    viewStateSubject.add(ViewState(showRoomSelector: false, showEditor: true));
    await tester.pump(); // Start animation
    await tester.pumpAndSettle(); // Finish animation

    // Verify editor width is panelWidth (800 / 4 = 200)
    editorContainer = tester.widget<AnimatedContainer>(
      find
          .ancestor(of: editorFinder, matching: find.byType(AnimatedContainer))
          .first,
    );
    expect(editorContainer.constraints!.maxWidth, 200.0);
  });

  testWidgets('ViewBookingsScreen does not show editor in small view', (
    tester,
  ) async {
    when(() => mockViewModel.isSmallView()).thenReturn(true);
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(ViewState(showRoomSelector: false, showEditor: true)),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(RequestEditor), findsNothing);
  });

  testWidgets('ViewBookingsScreen shows editor in large view', (tester) async {
    when(() => mockViewModel.isSmallView()).thenReturn(false);
    when(() => mockViewModel.viewStateStream).thenAnswer(
      (_) => Stream.value(ViewState(showRoomSelector: false, showEditor: true)),
    );

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(RequestEditor), findsOneWidget);
  });

  testWidgets(
    'ViewBookingsScreen shows editor as dialog in small view when new request is loaded',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;

      when(
        () => mockRequestEditorViewModel.initializeNewRequest(any()),
      ).thenReturn(null);
      when(
        () => mockRequestEditorViewModel.initialRequestStream,
      ).thenAnswer((_) => Stream.value(null));
      when(
        () => mockRequestEditorViewModel.currentDataStream(),
      ).thenAnswer((_) => Stream.value((null, null)));
      when(
        () => mockCalendarViewModel.registerNewAppointmentStream(any()),
      ).thenReturn(null);
      when(
        () => mockCalendarViewModel.dateTapStream,
      ).thenAnswer((_) => Stream.empty());
      when(
        () => mockCalendarViewModel.requestTapStream,
      ).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
            ChangeNotifierProvider<RoomRepo>.value(value: mockRoomRepo),
            ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
            ChangeNotifierProvider<PreferencesRepo>.value(
              value: mockPreferencesRepo,
            ),
            Provider<FirebaseAuthService>.value(value: mockAuthService),
            ChangeNotifierProvider<FirebaseAnalyticsService>.value(
              value: mockAnalyticsService,
            ),
          ],
          child: MaterialApp(
            home: StackRouterScope(
              controller: mockRouter,
              stateHash: 0,
              child: ViewBookingsScreen(
                orgID: 'org1',
                createCalendarViewModel: (_, __) => mockCalendarViewModel,
                createRequestEditorViewModel: (_) => mockRequestEditorViewModel,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final ViewBookingsViewModel viewModel =
          Provider.of<ViewBookingsViewModel>(
            tester.element(find.byType(BookingCalendarView)),
            listen: false,
          );

      await viewModel.loadNewRequest(DateTime.now());
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(RequestEditor), findsOneWidget);

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );
}
