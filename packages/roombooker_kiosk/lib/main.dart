import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed (expected in spike if no config): $e');
  }
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: prefs),
      ],
      child: const KioskApp(),
    ),
  );
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomBooker Kiosk Spike',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SpikeDashboard(),
    );
  }
}

class SpikeDashboard extends StatefulWidget {
  const SpikeDashboard({super.key});

  @override
  State<SpikeDashboard> createState() => _SpikeDashboardState();
}

class _SpikeDashboardState extends State<SpikeDashboard> {
  static const platform = MethodChannel('org.goforthtech.roombooker_kiosk/automation');
  final TextEditingController _urlController = TextEditingController(text: 'https://meet.google.com/new');

  Future<void> _launchMeeting() async {
    try {
      await platform.invokeMethod('launchMeeting', {'url': _urlController.text});
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching meeting: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kiosk Spike Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Phase 2: Native Automation Spike',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Meeting URL',
                  border: OutlineInputBorder(),
                  helperText: 'Default launches a new Google Meet',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _launchMeeting,
                icon: const Icon(Icons.video_call),
                label: const Text('Launch & Auto-Join'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 48),
              const KioskStatusWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class KioskStatusWidget extends StatelessWidget {
  const KioskStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<KioskMode>(
      stream: watchKioskMode(),
      builder: (context, snapshot) {
        final mode = snapshot.data ?? KioskMode.disabled;
        final isActive = mode == KioskMode.enabled;

        return Column(
          children: [
            Text(
              'Kiosk Mode: ${mode.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                fontSize: 18,
                color: isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                if (isActive) {
                  final success = await stopKioskMode();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text((success ?? false) ? 'Kiosk Mode Stopped' : 'Failed to stop Kiosk Mode')),
                  );
                } else {
                  final success = await startKioskMode();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Kiosk Mode Started' : 'Failed to start Kiosk Mode')),
                  );
                }
              },
              child: Text(isActive ? 'Stop Kiosk Mode' : 'Start Kiosk Mode'),
            ),
          ],
        );
      },
    );
  }
}
