import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/providers.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/auth.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:room_booker/app_router_observer.dart';

bool useEmulator = false;

void main() {
  // Capture cold start time as early as possible
  final coldStartTime = DateTime.now();

  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppInitializer(coldStartTime: coldStartTime));
}

class AppInitializer extends StatefulWidget {
  final DateTime coldStartTime;

  const AppInitializer({super.key, required this.coldStartTime});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<({SharedPreferences prefs, LoggingService loggingService})>
  _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  Future<({SharedPreferences prefs, LoggingService loggingService})>
  _initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(
        '6Lej2S0sAAAAAKBEX9lCwb1g4RBlAMb3dXeJHWv-',
      ),
    );

    final loggingService = getLoggingService();
    final prefs = await SharedPreferences.getInstance();
    loggingService.startColdStartTrace(widget.coldStartTime);

    if (useEmulator && kDebugMode) {
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      } catch (e) {
        // ignore: avoid_print
        print(e);
      }
    }

    if (!kDebugMode) {
      await SentryFlutter.init((options) {
        options.enableLogs = true;
        options.dsn =
            'https://c5ed84ffedec25c193d642e9a8e6ba0f@o4509504243630080.ingest.us.sentry.io/4509504245071872';
        options.sendDefaultPii = true;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
        options.attachScreenshot = true;
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;
      });
    } else {
      loggingService.debug(
        'App is running in debug mode, not initializing Sentry',
      );
    }

    FirebaseUIAuth.configureProviders(providers);
    FirebaseAnalytics.instance.logAppOpen();

    return (prefs: prefs, loggingService: loggingService);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({SharedPreferences prefs, LoggingService loggingService})>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final data = snapshot.data!;
          final myApp = MyApp(
            prefs: data.prefs,
            loggingService: data.loggingService,
          );

          if (kDebugMode) {
            return myApp;
          } else {
            return SentryWidget(child: myApp);
          }
        }

        // Native-like splash screen while loading
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF673AB7), // Match CSS splash
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Room Booker',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

LoggingService getLoggingService() {
  if (kDebugMode) {
    return DebugLoggingService();
  }
  return SentryLoggingService();
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final LoggingService loggingService;

  MyApp({super.key, required this.prefs, required this.loggingService});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loggingService.stopColdStartTrace();
    });

    return AppProviders(
      prefs: prefs,
      loggingService: loggingService,
      child: MaterialApp.router(
        title: 'Room Booker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: _appRouter.config(
          navigatorObservers: () => [AppRouterObserver(loggingService)],
        ),
      ),
    );
  }
}
