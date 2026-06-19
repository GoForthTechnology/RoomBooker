import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:roombooker_core/roombooker_core.dart';
import 'package:roombooker_kiosk/firebase_options.dart';

import 'package:flutter/foundation.dart';
import 'package:roombooker_kiosk/agenda_list.dart';
import 'package:roombooker_kiosk/quick_book_panel.dart';
import 'package:roombooker_kiosk/stage_ui.dart';
import 'package:roombooker_kiosk/display_orchestrator.dart';
import 'package:roombooker_kiosk/display_wrapper.dart';
import 'package:roombooker_kiosk/kiosk_state_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();

  if (FirebaseAuth.instance.currentUser == null) {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint('Kiosk: Anonymous sign-in failed: $e');
    }
  }

  const storage = FlutterSecureStorage();
  try {
    if (await storage.read(key: 'deviceID') == null) {
      await storage.write(key: 'deviceID', value: const Uuid().v4());
    }
  } catch (e) {
    debugPrint('Kiosk: Failed to read/write deviceID: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<FlutterSecureStorage>(create: (_) => storage),
        Provider<SharedPreferences>(create: (_) => prefs),
        Provider<ProvisioningService>(create: (_) => ProvisioningService()),
        ChangeNotifierProvider<LoggingService>(create: (_) => DebugLoggingService()),
        ChangeNotifierProxyProvider<LoggingService, AnalyticsService>(
          create: (context) => FirebaseAnalyticsService(context.read<LoggingService>()),
          update: (_, logging, _) => FirebaseAnalyticsService(logging),
        ),
        ChangeNotifierProvider<LogRepo>(create: (_) => LogRepo()),
        ProxyProvider3<LogRepo, AnalyticsService, LoggingService, BookingRepo>(
          update: (_, logRepo, analytics, logging, _) => BookingRepo(
            logRepo: logRepo,
            analytics: analytics,
            logging: logging,
          ),
        ),
        ProxyProvider<BookingRepo, BookingService>(
          update: (_, repo, _) => BookingService(bookingRepo: repo),
        ),
        ChangeNotifierProvider<DisplayOrchestrator>(
          create: (_) => DisplayOrchestrator(
            wrapper: !kIsWeb && defaultTargetPlatform == TargetPlatform.android 
              ? MethodChannelDisplayWrapper() 
              : StubDisplayWrapper(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => KioskStateNotifier()),
      ],
      child: const KioskApp(),
    ),
  );
}

@pragma('vm:entry-point')
void secondaryDisplayMain() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MeetingStageWidget(),
  ));
}

class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoomBooker Kiosk',
      onGenerateRoute: (settings) {
        if (settings.name == 'presentation') {
          return MaterialPageRoute(builder: (_) => const MeetingStageWidget());
        }
        return null;
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ProvisioningGuard(),
    );
  }
}

class ProvisioningGuard extends StatefulWidget {
  const ProvisioningGuard({super.key});

  @override
  State<ProvisioningGuard> createState() => _ProvisioningGuardState();
}

class _ProvisioningGuardState extends State<ProvisioningGuard> {
  bool _isLoading = true;
  bool _isProvisioned = false;
  String? _roomID;
  String? _orgID;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Check local provisioning
    final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
    final roomID = await storage.read(key: 'roomID');
    final orgID = await storage.read(key: 'orgID');

    if (mounted) {
      setState(() {
        _roomID = roomID;
        _orgID = orgID;
        _isProvisioned = roomID != null && orgID != null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing Kiosk...'),
            ],
          ),
        ),
      );
    }

    if (_isProvisioned && _roomID != null && _orgID != null) {
      return KioskDashboard(orgID: _orgID!, roomID: _roomID!);
    }

    return const ProvisioningScreen();
  }
}

class ProvisioningScreen extends StatefulWidget {
  const ProvisioningScreen({super.key});

  @override
  State<ProvisioningScreen> createState() => _ProvisioningScreenState();
}

class _ProvisioningScreenState extends State<ProvisioningScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isSubmitting = false;

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_controllers.every((c) => c.text.length == 1)) {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final code = _controllers.map((c) => c.text).join();
    
    try {
      debugPrint('Kiosk: Claiming grant for code $code...');
      final provisioningService = Provider.of<ProvisioningService>(context, listen: false);
      final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
      final deviceID = await storage.read(key: 'deviceID');
      final grant = await provisioningService.claimKioskGrant(
        code: code,
        deviceID: deviceID ?? '',
      );

      debugPrint('Kiosk: Grant claimed for Room ID: ${grant.roomID}');
      await storage.write(key: 'roomID', value: grant.roomID);
      await storage.write(key: 'orgID', value: grant.orgID);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProvisioningGuard()),
      );
    } catch (e) {
      debugPrint('Kiosk: Provisioning error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      for (var c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Activate Kiosk', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Enter the activation code from the Portal app.', textAlign: TextAlign.center),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                    onChanged: (v) => _onChanged(v, index),
                    decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ''),
                  ),
                )),
              ),
              const SizedBox(height: 48),
              if (_isSubmitting) const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class JoinMeetingButton extends StatelessWidget {
  final String? meetingUrl;
  final Color foregroundColor;
  final void Function(String url) onLaunch;

  const JoinMeetingButton({
    super.key,
    required this.meetingUrl,
    required this.foregroundColor,
    required this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final url = meetingUrl;
    if (url == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 300,
      height: 80,
      child: ElevatedButton(
        onPressed: () => onLaunch(url),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('JOIN MEETING', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class KioskDashboard extends StatefulWidget {
  final String orgID;
  final String roomID;
  const KioskDashboard({super.key, required this.orgID, required this.roomID});

  @override
  State<KioskDashboard> createState() => _KioskDashboardState();
}

class _KioskDashboardState extends State<KioskDashboard> {
  static const platform = MethodChannel('org.goforthtech.roombooker_kiosk/automation');
  static const diagnosticChannel = MethodChannel('org.goforthtech.roombooker_kiosk/diagnostics');

  bool _isServiceRunning = false;
  late final BookingService _bookingService;
  
  late final Stream<List<Request>> _bookingsStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _roomStream;

  @override
  void initState() {
    super.initState();
    _bookingService = context.read<BookingService>();
    _checkServiceStatus();
    
    // Memoize streams so they don't recreate on every rebuild
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    _bookingsStream = _bookingService.listRequests(
      orgID: widget.orgID,
      startTime: startOfDay,
      endTime: startOfDay.add(const Duration(days: 1)),
      includeRoomIDs: {widget.roomID},
      includeStatuses: {RequestStatus.confirmed},
    );
    
    _roomStream = FirebaseFirestore.instance
        .collection('orgs')
        .doc(widget.orgID)
        .collection('rooms')
        .doc(widget.roomID)
        .snapshots();

    diagnosticChannel.setMethodCallHandler((call) async {
      if (call.method == 'log') {
        final Map data = call.arguments;
        if (data['type'] == 'SERVICE_CONNECTED') {
          setState(() => _isServiceRunning = true);
        }
      }
    });
  }

  Future<void> _checkServiceStatus() async {
    try {
      final bool isRunning = await platform.invokeMethod('checkServiceStatus');
      setState(() => _isServiceRunning = isRunning);
    } catch (_) {}
  }

  Future<void> _launchMeeting(String url) async {
    final orchestrator = context.read<DisplayOrchestrator>();
    await orchestrator.refresh();
    
    if (orchestrator.secondaryDisplay != null) {
      await platform.invokeMethod('launchMeeting', {
        'url': url,
        'displayId': orchestrator.secondaryDisplay!.displayId,
      });
    } else {
      await platform.invokeMethod('launchMeeting', {
        'url': url,
        'displayId': null,
      });
    }
  }

  Future<void> _onQuickBook(Duration duration, String roomName) async {
    final now = DateTime.now();
    try {
      await _bookingService.addBooking(
        widget.orgID,
        Request(
          eventStartTime: now,
          eventEndTime: now.add(duration),
          roomID: widget.roomID,
          roomName: roomName,
          publicName: 'In-Room Booking',
          status: RequestStatus.confirmed,
          bookedVia: BookingSource.kiosk,
          recurrancePattern: RecurrancePattern.never(),
        ),
        PrivateRequestDetails(
          name: 'In-Room Hub',
          email: '',
          phone: '',
          message: '',
          eventName: 'In-Room Booking',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to book room: $e')),
      );
    }
  }

  Future<void> _showInfoDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final orgDoc = await FirebaseFirestore.instance.collection('orgs').doc(widget.orgID).get();
      final roomDoc = await orgDoc.reference.collection('rooms').doc(widget.roomID).get();
      
      final orgName = orgDoc.data()?['name'] ?? 'Unknown Organization';
      final roomName = roomDoc.data()?['name'] ?? 'Unknown Room';

      if (!mounted) return;
      Navigator.pop(context); 

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Provisioning Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Organization: $orgName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('ID: ${widget.orgID}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 16),
              Text('Room: $roomName', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('ID: ${widget.roomID}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Text('DANGER ZONE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('De-provision Kiosk?'),
                        content: const Text('This will clear all local identity and require a new activation code.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true), 
                            child: const Text('DE-PROVISION', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      if (!context.mounted) return;
                      final provisioningService = Provider.of<ProvisioningService>(context, listen: false);
                      final storage = Provider.of<FlutterSecureStorage>(context, listen: false);
                      try {
                        await provisioningService.revokeKioskGrant(
                          orgID: widget.orgID,
                          roomID: widget.roomID,
                        );
                      } catch (e) {
                        debugPrint('Kiosk: Failed to revoke grant: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to revoke kiosk access: $e')),
                          );
                        }
                      }
                      await storage.deleteAll();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const ProvisioningGuard()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('DE-PROVISION TERMINAL', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load info: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Request>>(
      stream: _bookingsStream,
      builder: (context, bookingsSnapshot) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _roomStream,
          builder: (context, roomSnapshot) {
            final now = DateTime.now();
            final bookings = bookingsSnapshot.data ?? [];
            final roomData = roomSnapshot.data?.data();
            final roomName = roomData?['name'] ?? 'LOADING...';
            
            // Find current meeting
            Request? currentBooking;
            for (var b in bookings) {
              if (b.eventStartTime.isBefore(now) && b.eventEndTime.isAfter(now)) {
                currentBooking = b;
                break;
              }
            }

            // Persistence: Use previous state while loading new stream data to prevent flickering
            final status = currentBooking != null ? RoomStatus.busy : RoomStatus.available;
            final backgroundColor = _getBackgroundColor(status);

            return Scaffold(
              backgroundColor: backgroundColor,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('Kiosk Dashboard'),
                actions: [
                  StreamBuilder<KioskMode>(
                    stream: watchKioskMode(),
                    builder: (context, snapshot) {
                      final isLocked = snapshot.data == KioskMode.enabled;
                      return IconButton(
                        icon: Icon(isLocked ? Icons.lock : Icons.lock_open),
                        tooltip: isLocked ? 'Unlock Kiosk' : 'Lock Kiosk',
                        onPressed: () async {
                          if (isLocked) {
                            await stopKioskMode();
                          } else {
                            final success = await startKioskMode();
                            if (!success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to lock. Ensure Device Admin is enabled.'))
                              );
                            }
                          }
                        },
                      );
                    }
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Device Info',
                    onPressed: _showInfoDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.monitor),
                    tooltip: 'TV Preview',
                    onPressed: () async {
                      final orchestrator = context.read<DisplayOrchestrator>();
                      await orchestrator.refresh();
                      if (orchestrator.secondaryDisplay != null) {
                        await orchestrator.showOnStage('presentation');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Projecting to Secondary Display...'))
                          );
                        }
                      } else {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => const Dialog.fullscreen(child: MeetingStageWidget()),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No Secondary Display found. Showing local preview.'))
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
              body: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 24, 48, 24),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            roomName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 32, color: Colors.white60, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            status == RoomStatus.available ? 'AVAILABLE' : 'OCCUPIED',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                        if (currentBooking != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            currentBooking.publicName ?? 'Private Meeting',
                            style: const TextStyle(fontSize: 28, color: Colors.white70),
                          ),
                          const SizedBox(height: 16),
                          if (currentBooking.id == null)
                            const SizedBox.shrink()
                          else
                            StreamBuilder<PrivateRequestDetails?>(
                              stream: _bookingService.getRequestDetails(
                                widget.orgID,
                                currentBooking.id!,
                              ),
                              builder: (context, detailsSnapshot) {
                                return JoinMeetingButton(
                                  meetingUrl: detailsSnapshot.data?.meetingUrl,
                                  foregroundColor: backgroundColor,
                                  onLaunch: _launchMeeting,
                                );
                              },
                            ),
                        ],
                        const SizedBox(height: 16),
                        if (!_isServiceRunning)
                          ElevatedButton(
                            onPressed: () => platform.invokeMethod('openAccessibilitySettings'),
                            child: const Text('ENABLE AUTOMATION SERVICE'),
                          ),
                        if (status == RoomStatus.available) ...[
                          const SizedBox(height: 16),
                          QuickBookPanel(
                            bookings: bookings,
                            now: now,
                            onBook: (duration) =>
                                _onQuickBook(duration, roomName),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: AgendaListView(bookings: bookings, now: now),
                  ),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Color _getBackgroundColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available: return Colors.green.shade900;
      case RoomStatus.busy: return Colors.red.shade900;
      case RoomStatus.transitioning: return Colors.orange.shade900;
    }
  }
}
