import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/ui/screens/landing/landing.dart';
import 'package:room_booker/ui/screens/landing/landing_viewmodel.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

// Mocks
class MockLandingViewModel extends Mock implements LandingViewModel {}

class MockPreferencesRepo extends Mock implements PreferencesRepo {}

class MockOrgRepo extends Mock implements OrgRepo {}

class MockBookingRepo extends Mock implements BookingRepo {}

class MockStackRouter extends Mock implements StackRouter {}

void main() {
  late MockLandingViewModel mockViewModel;
  late MockPreferencesRepo mockPrefsRepo;
  late MockOrgRepo mockOrgRepo;
  late MockBookingRepo mockBookingRepo;
  late MockStackRouter mockRouter;

  setUp(() {
    mockViewModel = MockLandingViewModel();
    mockPrefsRepo = MockPreferencesRepo();
    mockOrgRepo = MockOrgRepo();
    mockBookingRepo = MockBookingRepo();
    mockRouter = MockStackRouter();

    // Stub view model methods and streams
    when(() => mockViewModel.shouldShowRedirecting).thenReturn(false);
    when(() => mockViewModel.isLoggedIn).thenReturn(false);
    when(() => mockViewModel.ownedOrgsStream)
        .thenAnswer((_) => Stream.value([]));
    when(() => mockViewModel.otherOrgsStream)
        .thenAnswer((_) => Stream.value([]));
    when(() => mockViewModel.navigationEvents)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockViewModel.signOut()).thenAnswer((_) async {});
    when(() => mockViewModel.navigateToLogin()).thenAnswer((_) {});

    // Stub prefs repo
    when(() => mockPrefsRepo.defaultCalendarView)
        .thenReturn(CalendarView.month);

    // Stub org repo
    when(() => mockOrgRepo.adminRequests(any()))
        .thenAnswer((_) => Stream.value([]));

    // Stub booking repo
    when(() => mockBookingRepo.listRequests(
          orgID: any(named: 'orgID'),
          startTime: any(named: 'startTime'),
          endTime: any(named: 'endTime'),
          includeStatuses: any(named: 'includeStatuses'),
          includeRoomIDs: any(named: 'includeRoomIDs'),
        )).thenAnswer((_) => Stream.value([]));
    when(() => mockBookingRepo.findOverlappingBookings(any(), any(), any()))
        .thenAnswer((_) => Stream.value([]));
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LandingViewModel>.value(value: mockViewModel),
        ChangeNotifierProvider<PreferencesRepo>.value(value: mockPrefsRepo),
        ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
        ChangeNotifierProvider<BookingRepo>.value(value: mockBookingRepo),
      ],
      child: MaterialApp(
        home: StackRouterScope(
          controller: mockRouter,
          stateHash: 0,
          child: const LandingScreenView(),
        ),
      ),
    );
  }

  group('LandingScreenView', () {
    testWidgets('shows loading indicator when redirecting', (tester) async {
      // Arrange
      when(() => mockViewModel.shouldShowRedirecting).thenReturn(true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Your Organizations section when logged in',
        (tester) async {
      // Arrange
      when(() => mockViewModel.isLoggedIn).thenReturn(true);
      when(() => mockViewModel.ownedOrgsStream).thenAnswer((_) => Stream.value([
            Organization(
                id: '1',
                name: 'My Org',
                ownerID: 'owner',
                acceptingAdminRequests: true)
          ]));

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Let stream deliver data

      // Assert
      expect(find.text("Your Organizations"), findsOneWidget);
      expect(find.text('My Org'), findsOneWidget);
    });

    testWidgets('does not show Your Organizations section when logged out',
        (tester) async {
      // Arrange
      when(() => mockViewModel.isLoggedIn).thenReturn(false);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.text("Your Organizations"), findsNothing);
    });

    testWidgets('tapping FAB navigates to login when logged out',
        (tester) async {
      // Arrange
      when(() => mockViewModel.isLoggedIn).thenReturn(false);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byType(FloatingActionButton));

      // Assert
      verify(() => mockViewModel.navigateToLogin()).called(1);
    });

    testWidgets('tapping sign out button calls signOut on viewmodel',
        (tester) async {
      // Arrange
      when(() => mockViewModel.isLoggedIn).thenReturn(true);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byIcon(Icons.logout));

      // Assert
      verify(() => mockViewModel.signOut()).called(1);
    });
  });
}
