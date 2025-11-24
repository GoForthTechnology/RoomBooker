import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/ui/widgets/action_button.dart';
import 'package:room_booker/ui/widgets/org_settings/org_actions.dart';

class MockOrgRepo extends Mock implements OrgRepo {}

class MockStackRouter extends Mock implements StackRouter {}

void main() {
  group('OrgActions', () {
    late MockOrgRepo mockOrgRepo;
    late Organization testOrg;
    late MockStackRouter mockStackRouter;

    setUpAll(() {
      registerFallbackValue(JoinOrgRoute(orgID: 'any'));
      Provider.debugCheckInvalidValueType = null;
    });

    setUp(() {
      mockOrgRepo = MockOrgRepo();
      testOrg = Organization(
        id: 'org1',
        name: 'Test Org',
        ownerID: 'owner1',
        acceptingAdminRequests: false,
        publiclyVisible: false,
      );
      mockStackRouter = MockStackRouter();

      when(() => mockOrgRepo.hideOrg(any())).thenAnswer((_) async {});
      when(() => mockOrgRepo.publishOrg(any())).thenAnswer((_) async {});
      when(() => mockOrgRepo.disableAdminRequests(any()))
          .thenAnswer((_) async {});
      when(() => mockOrgRepo.enableAdminRequests(any()))
          .thenAnswer((_) async {});
      when(() => mockOrgRepo.removeOrg(any())).thenAnswer((_) async {});
      when(() => mockStackRouter.popUntilRoot()).thenAnswer((_) async {});
    });

    Widget createWidgetUnderTest({required Organization org}) {
      return MaterialApp(
        home: Scaffold(
          body: Provider.value(
            value: mockOrgRepo,
            child: Builder(
              builder: (context) => StackRouterScope(
                controller: mockStackRouter,
                stateHash: 0,
                child: OrgActions(org: org, repo: mockOrgRepo),
              ),
            ),
          ),
        ),
      );
    }

    group('_publishButton', () {
      testWidgets('shows "Hide Organization" when publiclyVisible is true',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(publiclyVisible: true);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        expect(find.widgetWithText(ActionButton, 'Hide Organization'), findsOneWidget);
        expect(find.widgetWithText(ActionButton, 'Publish Organization'), findsNothing);
      });

      testWidgets('calls repo.hideOrg when "Hide Organization" is pressed',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(publiclyVisible: true);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        await tester.tap(find.widgetWithText(ActionButton, 'Hide Organization'));
        verify(() => mockOrgRepo.hideOrg('org1')).called(1);
      });

      testWidgets('shows "Publish Organization" when publiclyVisible is false',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(publiclyVisible: false);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        expect(find.widgetWithText(ActionButton, 'Publish Organization'), findsOneWidget);
        expect(find.widgetWithText(ActionButton, 'Hide Organization'), findsNothing);
      });

      testWidgets('calls repo.publishOrg when "Publish Organization" is pressed',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(publiclyVisible: false);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        await tester.tap(find.widgetWithText(ActionButton, 'Publish Organization'));
        verify(() => mockOrgRepo.publishOrg('org1')).called(1);
      });
    });

    group('_adminRegistrationButton', () {
      testWidgets('shows "Stop Admin Requests" when acceptingAdminRequests is true',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(acceptingAdminRequests: true);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        expect(find.widgetWithText(ActionButton, 'Stop Admin Requests'), findsOneWidget);
        expect(find.widgetWithText(ActionButton, 'Share Organization'), findsNothing);
      });

      testWidgets('calls repo.disableAdminRequests when "Stop Admin Requests" is pressed',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(acceptingAdminRequests: true);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        await tester.tap(find.widgetWithText(ActionButton, 'Stop Admin Requests'));
        verify(() => mockOrgRepo.disableAdminRequests('org1')).called(1);
      });

      testWidgets('shows "Share Organization" when acceptingAdminRequests is false',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(acceptingAdminRequests: false);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        expect(find.widgetWithText(ActionButton, 'Share Organization'), findsOneWidget);
        expect(find.widgetWithText(ActionButton, 'Stop Admin Requests'), findsNothing);
      });

      testWidgets('calls repo.enableAdminRequests when "Share Organization" is pressed',
          (WidgetTester tester) async {
        final org = testOrg.copyWith(acceptingAdminRequests: false);
        await tester.pumpWidget(createWidgetUnderTest(org: org));
        await tester.tap(find.widgetWithText(ActionButton, 'Share Organization'));
        verify(() => mockOrgRepo.enableAdminRequests('org1')).called(1);
      });
    });

    group('_removeOrgButton', () {
      testWidgets('shows "Remove Organization" button', (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
        expect(find.widgetWithText(ActionButton, 'Remove Organization'), findsOneWidget);
      });

      testWidgets('calls repo.removeOrg and router.popUntilRoot when confirmed',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
        await tester.tap(find.widgetWithText(ActionButton, 'Remove Organization'));
        await tester.pumpAndSettle(); // Show dialog

        expect(find.text('Delete Organization?'), findsOneWidget);
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        verify(() => mockOrgRepo.removeOrg('org1')).called(1);
        verify(() => mockStackRouter.popUntilRoot()).called(1);
      });

      testWidgets('does not call repo.removeOrg or router.popUntilRoot when cancelled',
          (WidgetTester tester) async {
        await tester.pumpWidget(createWidgetUnderTest(org: testOrg));
        await tester.tap(find.widgetWithText(ActionButton, 'Remove Organization'));
        await tester.pumpAndSettle(); // Show dialog

        expect(find.text('Delete Organization?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        verifyNever(() => mockOrgRepo.removeOrg(any()));
        verifyNever(() => mockStackRouter.popUntilRoot());
      });
    });
  });

  group('confirmOrgDeletion', () {
    testWidgets('shows correct title and content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmOrgDeletion(context),
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Organization?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this organization?'), findsOneWidget);
    });

    testWidgets('returns false when Cancel is tapped', (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmOrgDeletion(context);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns true when Delete is tapped', (WidgetTester tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmOrgDeletion(context);
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
