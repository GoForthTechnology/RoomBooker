import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/action_button.dart';
import 'package:room_booker/ui/widgets/org_settings/admin_widget.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockStackRouter extends Mock implements StackRouter {}

class MockAdminEntry extends Mock implements AdminEntry {}

void main() {
  setUpAll(() {
    registerFallbackValue(JoinOrgRoute(orgID: 'any'));
  });

  group('AdminWidget', () {
    late MockOrgRepo mockOrgRepo;
    late Organization testOrg;
    late MockStackRouter mockStackRouter;

    setUp(() {
      mockOrgRepo = MockOrgRepo();
      testOrg = Organization(
        id: 'org1',
        name: 'Test Org',
        ownerID: 'owner1',
        acceptingAdminRequests: false,
      );
      mockStackRouter = MockStackRouter();

      when(
        () => mockOrgRepo.adminRequests(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockOrgRepo.activeAdmins(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockOrgRepo.approveAdminRequest(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockOrgRepo.denyAdminRequest(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockOrgRepo.removeAdmin(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockStackRouter.push(any())).thenAnswer((_) async {
        return null;
      });
    });

    Widget createWidgetUnderTest({required Organization org}) {
      return MaterialApp(
        home: Scaffold(
          body: StackRouterScope(
            controller: mockStackRouter,
            stateHash: 0,
            child: AdminWidget(org: org, repo: mockOrgRepo),
          ),
        ),
      );
    }

    testWidgets(
      'shows CircularProgressIndicator for admin requests while loading',
      (WidgetTester tester) async {
        when(
          () => mockOrgRepo.adminRequests(any()),
        ).thenAnswer((_) => const Stream.empty()); // Simulate loading

        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));

        expect(
          find.byType(CircularProgressIndicator),
          findsNWidgets(2),
        ); // One for each stream builder
      },
    );

    testWidgets(
      'shows "Error loading requests" when adminRequests stream errors',
      (WidgetTester tester) async {
        when(
          () => mockOrgRepo.adminRequests(any()),
        ).thenAnswer((_) => Stream.error(Exception('Failed to load')));

        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
        await tester.pumpAndSettle();

        expect(find.text('Error loading requests'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "No pending requests" when adminRequests stream is empty',
      (WidgetTester tester) async {
        when(
          () => mockOrgRepo.adminRequests(any()),
        ).thenAnswer((_) => Stream.value([]));

        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
        await tester.pumpAndSettle();

        expect(find.text('No pending requests'), findsOneWidget);
      },
    );

    testWidgets('displays pending admin requests and handles actions', (
      WidgetTester tester,
    ) async {
      final mockAdminEntry1 = MockAdminEntry();
      when(() => mockAdminEntry1.id).thenReturn('req1');
      when(() => mockAdminEntry1.email).thenReturn('pending1@example.com');

      when(
        () => mockOrgRepo.adminRequests(any()),
      ).thenAnswer((_) => Stream.value([mockAdminEntry1]));

      await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
      await tester.pumpAndSettle();

      expect(find.text('pending1@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.approval_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.byIcon(Icons.approval_rounded));
      await tester.pumpAndSettle();
      verify(() => mockOrgRepo.approveAdminRequest('org1', 'req1')).called(1);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      verify(() => mockOrgRepo.denyAdminRequest('org1', 'req1')).called(1);
    });

    testWidgets(
      'shows "Error loading admins" when activeAdmins stream errors',
      (WidgetTester tester) async {
        when(
          () => mockOrgRepo.activeAdmins(any()),
        ).thenAnswer((_) => Stream.error(Exception('Failed to load')));

        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
        await tester.pumpAndSettle();

        expect(find.text('Error loading admins'), findsOneWidget);
      },
    );

    testWidgets('shows "No active admins" when activeAdmins stream is empty', (
      WidgetTester tester,
    ) async {
      when(
        () => mockOrgRepo.activeAdmins(any()),
      ).thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
      await tester.pumpAndSettle();

      expect(find.text('No active admins'), findsOneWidget);
    });

    testWidgets('displays active admins and handles removal', (
      WidgetTester tester,
    ) async {
      final mockAdminEntry1 = MockAdminEntry();
      when(() => mockAdminEntry1.id).thenReturn('admin1');
      when(() => mockAdminEntry1.email).thenReturn('active1@example.com');

      when(
        () => mockOrgRepo.activeAdmins(any()),
      ).thenAnswer((_) => Stream.value([mockAdminEntry1]));

      await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
      await tester.pumpAndSettle();

      expect(find.text('active1@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      verify(() => mockOrgRepo.removeAdmin('org1', 'admin1')).called(1);
    });

    testWidgets('shows "Admin requests are open" and "View Join Link" button', (
      WidgetTester tester,
    ) async {
      final orgWithRequests = testOrg.copyWith(acceptingAdminRequests: true);

      await tester.pumpWidget(createWidgetUnderTest(org: orgWithRequests));
      await tester.pumpAndSettle();

      expect(find.text('Admin requests are open'), findsOneWidget);
      expect(
        find.widgetWithText(ActionButton, 'View Join Link'),
        findsOneWidget,
      );
    });

    testWidgets('tapping "View Join Link" navigates to JoinOrgRoute', (
      WidgetTester tester,
    ) async {
      final orgWithRequests = testOrg.copyWith(acceptingAdminRequests: true);

      await tester.pumpWidget(createWidgetUnderTest(org: orgWithRequests));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionButton, 'View Join Link'));
      await tester.pumpAndSettle();

      verify(() => mockStackRouter.push(JoinOrgRoute(orgID: 'org1'))).called(1);
    });

    testWidgets(
      'shows "Admin requests are closed" when not accepting requests',
      (WidgetTester tester) async {
        final orgClosedRequests = testOrg.copyWith(
          acceptingAdminRequests: false,
        );

        await tester.pumpWidget(createWidgetUnderTest(org: orgClosedRequests));
        await tester.pumpAndSettle();

        expect(find.text('Admin requests are closed'), findsOneWidget);
        expect(
          find.widgetWithText(ActionButton, 'View Join Link'),
          findsNothing,
        );
      },
    );
  });

  group('Subheading', () {
    testWidgets('renders text with titleMedium style', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Subheading('Test Subheading'))),
      );

      final textWidget = tester.widget<Text>(find.text('Test Subheading'));
      expect(
        textWidget.style?.fontSize,
        Theme.of(
          tester.element(find.byType(Subheading)),
        ).textTheme.titleMedium?.fontSize,
      );
    });
  });
}
