import 'package:flutter_test/flutter_test.dart';
import 'package:roombooker_kiosk/main.dart';

void main() {
  testWidgets('Kiosk Spike Dashboard renders', (WidgetTester tester) async {
    await tester.pumpWidget(const KioskApp());

    expect(find.text('Kiosk Spike Dashboard'), findsOneWidget);
    expect(find.text('Phase 2: Native Automation Spike'), findsOneWidget);
  });
}
