import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roombooker_core/data/services/analytics_service.dart';
import 'package:roombooker_core/data/repos/org_repo.dart';
import 'package:roombooker_core/data/repos/prefs_repo.dart';
import 'package:roombooker_portal/router.dart';
import 'package:roombooker_portal/ui/screens/landing/landing_viewmodel.dart';

import 'package:roombooker_core/data/services/auth_service.dart';
import 'package:roombooker_core/data/repos/user_repo.dart';

// Mocks
class MockAuthService extends Mock implements AuthService {}

class MockUserRepo extends Mock implements UserRepo {}

class MockPreferencesRepo extends Mock implements PreferencesRepo {}

class MockOrgRepo extends Mock implements OrgRepo {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('LandingViewModel', () {
    late MockAuthService mockAuthService;
    late MockUserRepo mockUserRepo;
    late MockPreferencesRepo mockPrefsRepo;
    late MockOrgRepo mockOrgRepo;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockUserRepo = MockUserRepo();
      mockPrefsRepo = MockPreferencesRepo();
      mockOrgRepo = MockOrgRepo();
      mockAnalyticsService = MockAnalyticsService();

      // Default mock behaviors
      when(() => mockAuthService.getCurrentUserID()).thenReturn(null);
      when(() => mockAuthService.addListener(any())).thenReturn(null);
      when(() => mockAuthService.removeListener(any())).thenReturn(null);
      when(() => mockPrefsRepo.lastOpenedOrgId).thenReturn(null);
      when(
        () => mockAnalyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) {});
      when(
        () => mockOrgRepo.addOrgForCurrentUser(any(), any()),
      ).thenAnswer((_) async => 'new-org-id');
      when(() => mockAuthService.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.deleteAccount(any())).thenAnswer((_) async {});
      when(
        () => mockPrefsRepo.setLastOpenedOrgId(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockOrgRepo.claimPendingInvites(),
      ).thenAnswer((_) async {});
    });

    LandingViewModel createSut() {
      return LandingViewModel(
        authService: mockAuthService,
        userRepo: mockUserRepo,
        prefsRepo: mockPrefsRepo,
        orgRepo: mockOrgRepo,
        analyticsService: mockAnalyticsService,
      );
    }

    test('initial isLoggedIn is false when currentUID is null', () {
      final sut = createSut();
      expect(sut.isLoggedIn, isFalse);
      sut.dispose();
    });

    test('initial isLoggedIn is true when currentUID is not null', () {
      when(() => mockAuthService.getCurrentUserID()).thenReturn('test-uid');
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
      verify(
        () => mockAnalyticsService.logEvent(
          name: 'screen_view',
          parameters: {'screen_name': 'Landing'},
        ),
      ).called(1);
      sut.dispose();
    });

    test(
      'isLoggedIn updates and notifies listeners when auth listener is called',
      () async {
        late void Function() capturedListener;
        when(() => mockAuthService.addListener(any())).thenAnswer((invocation) {
          capturedListener = invocation.positionalArguments[0] as void Function();
        });

        final sut = createSut();
        int callCount = 0;
        sut.addListener(() => callCount++);

        when(() => mockAuthService.getCurrentUserID()).thenReturn('test-uid');
        capturedListener();

        expect(sut.isLoggedIn, isTrue);
        expect(callCount, 1);
        sut.dispose();
      },
    );

    test('signOut calls auth service', () async {
      final sut = createSut();
      await sut.signOut();
      verify(() => mockAuthService.logout()).called(1);
      sut.dispose();
    });

    test('deleteAccount calls auth service with user repo method', () async {
      final sut = createSut();
      await sut.deleteAccount();
      verify(() => mockAuthService.deleteAccount(mockUserRepo.deleteUserData)).called(1);
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
      await sut.createOrg('New Org', 'Room 1');
      verify(
        () => mockOrgRepo.addOrgForCurrentUser('New Org', 'Room 1'),
      ).called(1);
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
