import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:room_booker/ui/widgets/org_settings/app_info.dart';

void main() {
  group('AppInfoWidget', () {
    testWidgets('shows app info when data is available',
        (WidgetTester tester) async {
      PackageInfo.setMockInitialValues(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'test_signature',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppInfoWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('App Name: Test App'), findsOneWidget);
      expect(find.text('App Version: 1.0.0'), findsOneWidget);
      expect(find.text('Build Number: 1'), findsOneWidget);
    });

    testWidgets('shows empty container while loading',
        (WidgetTester tester) async {
      // Don't set mock values to keep the future pending
      PackageInfo.setMockInitialValues(
        appName: 'Test App',
        packageName: 'com.test.app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: 'test_signature',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppInfoWidget(),
          ),
        ),
      );

      // Before pumpAndSettle, it should be in the loading state
      expect(find.byType(Container), findsOneWidget);
      expect(find.textContaining('App Name'), findsNothing);
    });

    // Note: Testing the error state of the FutureBuilder is difficult here
    // because we cannot easily make `PackageInfo.fromPlatform()` throw an error
    // without more complex mocking (e.g., mocking platform channels).
  });
}
