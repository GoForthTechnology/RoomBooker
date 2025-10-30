import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/analytics_service.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/screens/landing_viewmodel.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockPreferencesRepo extends Mock implements PreferencesRepo {}

class MockOrgRepo extends Mock implements OrgRepo {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('LandingViewModel', () {
    late MockFirebaseAuth mockAuth;
    late MockPreferencesRepo mockPrefsRepo;
    late MockOrgRepo mockOrgRepo;
    late MockAnalyticsService mockAnalyticsService;
    late MockUser mockUser;
    late StreamController<User?> authController;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockPrefsRepo = MockPreferencesRepo();
      mockOrgRepo = MockOrgRepo();
      mockAnalyticsService = MockAnalyticsService();
      mockUser = MockUser();
      authController = StreamController<User?>.broadcast();

      // Default mock behaviors
      when(() => mockAuth.authStateChanges())
          .thenAnswer((_) => authController.stream);
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockPrefsRepo.isLoaded).thenReturn(true);
      when(() => mockPrefsRepo.lastOpenedOrgId).thenReturn(null);
      when(() => mockAnalyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'))).thenAnswer((_) {});
      when(() => mockOrgRepo.addOrgForCurrentUser(any()))
          .thenAnswer((_) async => 'new-org-id');
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      when(() => mockPrefsRepo.setLastOpenedOrgId(any()))
          .thenAnswer((_) async {});
    });

    LandingViewModel createSut() {
      return LandingViewModel(
        auth: mockAuth,
        prefsRepo: mockPrefsRepo,
        orgRepo: mockOrgRepo,
        analyticsService: mockAnalyticsService,
      );
    }

    test('initial isLoggedIn is false when currentUser is null', () {
      final sut = createSut();
      expect(sut.isLoggedIn, isFalse);
      sut.dispose();
    });

    test('initial isLoggedIn is true when currentUser is not null', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      final sut = createSut();
      expect(sut.isLoggedIn, isTrue);
      sut.dispose();
    });

    test('init logs screen view and handles initial navigation', () async {
      final completer = Completer<NavigationEvent>();
      when(() => mockPrefsRepo.lastOpenedOrgId).thenReturn('test-org');
      final sut = createSut();
      sut.navigationEvents.listen(completer.complete);

      sut.init();

      final event = await completer.future;
      expect(event, isA<NavigationEvent>());
      verify(() => mockAnalyticsService.logEvent(
          name: 'screen_view',
          parameters: {'screen_name': 'Landing'})).called(1);
      sut.dispose();
    });

    test('isLoggedIn updates and notifies listeners on auth state change',
        () async {
      final sut = createSut();
      int callCount = 0;
      sut.addListener(() => callCount++);

      authController.add(mockUser);
      await Future.value();

      expect(sut.isLoggedIn, isTrue);
      expect(callCount, 1);
      sut.dispose();
    });

    test('signOut calls auth', () async {
      final sut = createSut();
      await sut.signOut();
      verify(() => mockAuth.signOut()).called(1);
      sut.dispose();
    });

    test('onOrgTapped saves prefs and navigates', () async {
      final sut = createSut();
      final completer = Completer<NavigationEvent>();
      sut.navigationEvents.listen(completer.complete);

      sut.onOrgTapped('test-org', 'Day');

      final event = await completer.future;
      expect(event, isA<NavigationEvent>());
      verify(() => mockPrefsRepo.setLastOpenedOrgId('test-org')).called(1);
      sut.dispose();
    });

    test('createOrg calls repo', () async {
      final sut = createSut();
      await sut.createOrg('New Org');
      verify(() => mockOrgRepo.addOrgForCurrentUser('New Org')).called(1);
      sut.dispose();
    });

    test('navigateToLogin fires navigation event', () async {
      final sut = createSut();
      final completer = Completer<NavigationEvent>();
      sut.navigationEvents.listen(completer.complete);

      sut.navigateToLogin();

      final event = await completer.future;
      expect(event.route, isA<LoginRoute>());
      sut.dispose();
    });
  });
}
