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
  static const diagnosticChannel = MethodChannel('org.goforthtech.roombooker_kiosk/diagnostics');

  final TextEditingController _urlController = TextEditingController(text: 'https://meet.google.com/new');
  final List<String> _logs = [];
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    diagnosticChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final Map data = call.arguments;
        setState(() {
          if (data['type'] == 'SERVICE_CONNECTED') _isServiceRunning = true;
          _logs.insert(0, '[${data['type']}] ${data['message']}');
          if (_logs.length > 50) _logs.removeLast();
        });
      }
    });
  }

  Future<void> _checkServiceStatus() async {
    final bool isRunning = await platform.invokeMethod('checkServiceStatus');
    setState(() => _isServiceRunning = isRunning);
  }

  Future<void> _openAccessibilitySettings() async {
    await platform.invokeMethod('openAccessibilitySettings');
  }

  Future<void> _launchMeeting() async {
    try {
      setState(() {
        _logs.insert(0, '[FLUTTER] Launching meeting intent...');
      });
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
      appBar: AppBar(
        title: const Text('Kiosk Spike Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkServiceStatus,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text(
                  'Phase 2: Native Automation Spike',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Build: V5.8 One-Shot Auth (${DateTime.now().toIso8601String().substring(0, 16)})',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isServiceRunning ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _isServiceRunning ? Colors.green : Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isServiceRunning ? Icons.check_circle : Icons.warning,
                        color: _isServiceRunning ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isServiceRunning
                              ? 'Accessibility Service: ACTIVE'
                              : 'Accessibility Service: NOT FOUND',
                          style: TextStyle(
                            color: _isServiceRunning ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!_isServiceRunning)
                        TextButton(
                          onPressed: _openAccessibilitySettings,
                          child: const Text('ENABLE'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Meeting URL',
                    border: OutlineInputBorder(),
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
                const SizedBox(height: 24),
                const KioskStatusWidget(),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Diagnostic Console', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logs[index],
                    style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                  );
                },
              ),
            ),
          ),
        ],
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
