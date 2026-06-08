import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:roombooker_portal/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockFirebaseCore extends Mock with MockPlatformInterfaceMixin implements FirebasePlatform {}
class MockLoggingService extends Mock implements LoggingService {}
class MockFirebaseApp extends Mock with MockPlatformInterfaceMixin implements FirebaseAppPlatform {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final mockFirebase = MockFirebaseCore();
    FirebasePlatform.instance = mockFirebase;
    
    when(() => mockFirebase.initializeApp(
      name: any(named: 'name'),
      options: any(named: 'options'),
    )).thenAnswer((_) async => MockFirebaseApp());

    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Portal App boots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final loggingService = MockLoggingService();
    
    when(() => loggingService.startColdStartTrace(any())).thenReturn(null);
    when(() => loggingService.stopColdStartTrace()).thenReturn(null);
    when(() => loggingService.debug(any())).thenReturn(null);
    
    await tester.pumpWidget(
      MyApp(prefs: prefs, loggingService: loggingService),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
