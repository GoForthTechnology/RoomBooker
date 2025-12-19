import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/auth_service.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/entities/user_profile.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:room_booker/ui/widgets/org_state_provider.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockUserRepo extends Mock implements UserRepo {}

class FakeFirebaseAuthService extends ChangeNotifier
    implements FirebaseAuthService {
  String? _userID;

  @override
  String? getCurrentUserID() => _userID;

  @override
  String? getCurrentUserEmail() => _userID == null ? null : 'test@example.com';

  @override
  void logout() {
    _userID = null;
    notifyListeners();
  }

  void login(String userID) {
    _userID = userID;
    notifyListeners();
  }
}

void main() {
  late MockOrgRepo mockOrgRepo;
  late MockUserRepo mockUserRepo;
  late FakeFirebaseAuthService fakeAuthService;

  setUp(() {
    mockOrgRepo = MockOrgRepo();
    mockUserRepo = MockUserRepo();
    fakeAuthService = FakeFirebaseAuthService();

    // Stub addListener/removeListener for ChangeNotifierProvider
    when(() => mockOrgRepo.addListener(any())).thenReturn(null);
    when(() => mockOrgRepo.removeListener(any())).thenReturn(null);
    when(() => mockUserRepo.addListener(any())).thenReturn(null);
    when(() => mockUserRepo.removeListener(any())).thenReturn(null);
  });

  testWidgets('OrgStateProvider updates when auth state changes', (
    WidgetTester tester,
  ) async {
    const orgID = 'test_org_id';
    const userID = 'test_user_id';

    final organization = Organization(
      id: orgID,
      name: 'Test Org',
      ownerID: 'owner_id',
      acceptingAdminRequests: true,
    );

    final userProfile = UserProfile(orgIDs: [orgID]);

    when(
      () => mockOrgRepo.getOrg(orgID),
    ).thenAnswer((_) => Stream.value(organization));
    when(
      () => mockUserRepo.getUser(userID),
    ).thenAnswer((_) => Future.value(userProfile));

    // Helper widget to read OrgState
    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<OrgRepo>.value(value: mockOrgRepo),
          ChangeNotifierProvider<UserRepo>.value(value: mockUserRepo),
          ChangeNotifierProvider<FirebaseAuthService>.value(
            value: fakeAuthService,
          ),
        ],
        child: MaterialApp(
          home: OrgStateProvider(
            orgID: orgID,
            child: Builder(
              builder: (context) {
                // We can access OrgState here
                final orgState = Provider.of<OrgState>(context);
                return Text(
                  'Admin: ${orgState.currentUserIsAdmin}',
                  textDirection: TextDirection.ltr,
                );
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildTestWidget());

    // Initial pump starts the FutureBuilder, which is in waiting state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Pump to allow Future.delayed to complete
    await tester.pump(Duration.zero);
    // Pump again to allow the FutureBuilder to rebuild with data
    await tester.pump();

    // Initial state: Not logged in
    expect(find.text('Admin: false'), findsOneWidget);

    // Log in
    fakeAuthService.login(userID);
    await tester.pump(); // Rebuilds Consumer, FutureBuilder starts new future
    await tester.pump(Duration.zero); // Future completes
    await tester.pump(); // FutureBuilder rebuilds with data

    // Should be admin now
    expect(find.text('Admin: true'), findsOneWidget);

    // Log out
    fakeAuthService.logout();
    await tester.pump(); // Rebuilds Consumer, FutureBuilder starts new future
    await tester.pump(Duration.zero); // Future completes
    await tester.pump(); // FutureBuilder rebuilds with data

    // Should not be admin anymore
    expect(find.text('Admin: false'), findsOneWidget);
  });
}
