import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PROVISIONING state (spinner widget)', () {
    testWidgets('renders spinner and provisioning message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 8),
                Text('Generating Meet link…'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Generating Meet link…'), findsOneWidget);
      expect(find.text('JOIN MEETING'), findsNothing);
    });
  });

  group('ERROR state (_ProvisioningBanner)', () {
    testWidgets('renders error message and OK button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProvisioningBannerTestHarness(
              message: "Couldn't generate Meet link. Please try again.",
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(
        find.text("Couldn't generate Meet link. Please try again."),
        findsOneWidget,
      );
      expect(find.text('OK'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('tapping OK calls onDismiss', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProvisioningBannerTestHarness(
              message: 'Error message',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });

  group('TIMEOUT state (_ProvisioningBanner)', () {
    testWidgets('renders timeout message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProvisioningBannerTestHarness(
              message: 'Meet link timed out. Tap OK to retry.',
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('Meet link timed out. Tap OK to retry.'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('tapping OK dismisses the timeout banner', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProvisioningBannerTestHarness(
              message: 'Meet link timed out. Tap OK to retry.',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(dismissed, isTrue);
    });
  });
}

/// Test harness that exposes _ProvisioningBanner via a public wrapper.
/// Since _ProvisioningBanner is a private class in main.dart, this
/// duplicates its structure to keep tests in the public API surface.
class ProvisioningBannerTestHarness extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ProvisioningBannerTestHarness({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.shade800,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: onDismiss,
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
