import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_kiosk/main.dart';
import 'package:roombooker_kiosk/display_orchestrator.dart';
import 'package:roombooker_kiosk/kiosk_state_notifier.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mocks
class MockFirebaseCore extends Mock
    with MockPlatformInterfaceMixin
    implements FirebasePlatform {}

class MockFirebaseApp extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseAppPlatform {}

class MockDisplayOrchestrator extends Mock implements DisplayOrchestrator {}

class MockProvisioningService extends Mock implements ProvisioningService {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock Firebase
    final mockFirebase = MockFirebaseCore();
    FirebasePlatform.instance = mockFirebase;
    when(() => mockFirebase.initializeApp(
          name: any(named: 'name'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => MockFirebaseApp());

    // Mock Presentation Displays Platform Channel
    const channel = MethodChannel('presentation_displays');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'listDisplays') {
        return [];
      }
      return null;
    });

    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Kiosk App boots and renders ProvisioningScreen', (tester) async {
    final mockDisplayOrchestrator = MockDisplayOrchestrator();
    final mockProvisioningService = MockProvisioningService();
    final mockSecureStorage = MockSecureStorage();
    final prefs = await SharedPreferences.getInstance();

    // Setup default mock behaviors
    when(() => mockDisplayOrchestrator.displays).thenReturn([]);
    when(() => mockSecureStorage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          Provider<FlutterSecureStorage>.value(value: mockSecureStorage),
          Provider<ProvisioningService>.value(value: mockProvisioningService),
          ChangeNotifierProvider<DisplayOrchestrator>.value(
              value: mockDisplayOrchestrator),
          ChangeNotifierProvider(create: (_) => KioskStateNotifier()),
        ],
        child: const KioskApp(),
      ),
    );

    // Verify root MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);

    // Should start at ProvisioningGuard -> ProvisioningScreen
    await tester.pump(); // Start building guard
    await tester.pump(const Duration(milliseconds: 100)); // Finish async check
    await tester.pump(); // Build transition
    
    expect(find.byType(ProvisioningScreen), findsOneWidget);
  });
}
