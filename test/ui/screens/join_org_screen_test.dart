import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/entities/organization.dart';
import 'package:room_booker/ui/screens/join_org_screen.dart';
import 'package:room_booker/ui/screens/join_org_view.dart';
import 'package:room_booker/ui/screens/join_org_viewmodel.dart';

class MockJoinOrgViewModel extends Mock implements JoinOrgViewModel {}

void main() {
  late MockJoinOrgViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockJoinOrgViewModel();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<JoinOrgViewModel>.value(
        value: mockViewModel,
        child: const JoinOrgScreenView(),
      ),
    );
  }

  group('JoinOrgScreenView', () {
    testWidgets('displays JoinOrgView with data from stream', (tester) async {
      // Arrange
      final org = Organization(
          id: 'test-org-id', name: 'Test Org', ownerID: 'owner', acceptingAdminRequests: true);
      final streamController = StreamController<Organization?>();
      when(() => mockViewModel.orgStream).thenAnswer((_) => streamController.stream);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      streamController.add(org);
      await tester.pump();

      // Assert
      expect(find.byType(JoinOrgView), findsOneWidget);
      expect(find.text('Join Test Org?'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Join'), findsOneWidget);

      // Clean up
      streamController.close();
    });

    testWidgets('shows loading indicator when stream has no data', (tester) async {
      // Arrange
      when(() => mockViewModel.orgStream).thenAnswer((_) => const Stream.empty());

      // Act
      await tester.pumpWidget(createWidgetUnderTest());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'calls joinOrganization and shows SnackBar when Join button is tapped',
        (tester) async {
      // Arrange
      final org = Organization(
          id: 'test-org-id', name: 'Test Org', ownerID: 'owner', acceptingAdminRequests: true);
      when(() => mockViewModel.orgStream).thenAnswer((_) => Stream.value(org));
      when(() => mockViewModel.joinOrganization()).thenAnswer((_) async {});

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Let the stream deliver the data

      await tester.tap(find.widgetWithText(ElevatedButton, 'Join'));
      await tester.pump(); // First pump for the state change
      await tester.pump(); // Second pump for snackbar animation

      // Assert
      verify(() => mockViewModel.joinOrganization()).called(1);
      expect(find.text('Request has been submitted'), findsOneWidget);
    });
  });
}
