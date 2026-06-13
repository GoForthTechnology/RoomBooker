import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:roombooker_kiosk/main.dart';
import 'package:roombooker_kiosk/display_orchestrator.dart';
import 'package:roombooker_kiosk/kiosk_state_notifier.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
class MockDisplayOrchestrator extends Mock implements DisplayOrchestrator {}
class MockProvisioningService extends Mock implements ProvisioningService {}
class MockBookingRepo extends Mock implements BookingRepo {}
class MockBookingService extends Mock implements BookingService {}

void main() {
  testWidgets('Kiosk App boots to provisioning guard', (WidgetTester tester) async {
    final mockStorage = MockSecureStorage();
    final mockOrchestrator = MockDisplayOrchestrator();
    final mockProvisioning = MockProvisioningService();
    final mockBookingRepo = MockBookingRepo();
    final mockBookingService = MockBookingService();
    
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(() => mockOrchestrator.displays).thenReturn([]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SharedPreferences>.value(value: prefs),
          Provider<FlutterSecureStorage>.value(value: mockStorage),
          Provider<ProvisioningService>.value(value: mockProvisioning),
          Provider<BookingRepo>.value(value: mockBookingRepo),
          Provider<BookingService>.value(value: mockBookingService),
          ChangeNotifierProvider<DisplayOrchestrator>.value(value: mockOrchestrator),
          ChangeNotifierProvider(create: (_) => KioskStateNotifier()),
        ],
        child: const KioskApp(),
      ),
    );

    expect(find.byType(ProvisioningGuard), findsOneWidget);
  });
}
