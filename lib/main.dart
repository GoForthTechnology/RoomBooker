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

Future<void> main() async {
  // Capture cold start time as early as possible
  final coldStartTime = DateTime.now();

  WidgetsFlutterBinding.ensureInitialized();

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
  }

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
    try {
      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(
          '6Lej2S0sAAAAAKBEX9lCwb1g4RBlAMb3dXeJHWv-',
        ),
      );
    } catch (e) {
      // ReCAPTCHA error or AppCheck exception usually indicates abusive traffic
      // on Web if configuration is correct.
      // We use captureMessage with a custom level and tag to track these rejections
      // without triggering unhandled exception alerts in Sentry.
      Sentry.captureMessage(
        'AppCheck Security Rejection',
        level: SentryLevel.warning,
        withScope: (scope) {
          scope.setTag('security', 'abusive_traffic');
          scope.setContexts('error', {'message': e.toString()});
        },
      );
      throw AbusiveTrafficException(e.toString());
    }

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

    FirebaseUIAuth.configureProviders(providers);
    FirebaseAnalytics.instance.logAppOpen();

    return (prefs: prefs, loggingService: loggingService);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({SharedPreferences prefs, LoggingService loggingService})>(
      future: _initFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (snapshot.hasError) {
          final error = snapshot.error;
          final isAbusive = error is AbusiveTrafficException;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              backgroundColor: const Color(0xFF673AB7),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.security, color: Colors.white, size: 64),
                      const SizedBox(height: 24),
                      Text(
                        isAbusive
                            ? 'Access Denied: Abusive Traffic Detected'
                            : 'Initialization Failed',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!isAbusive) ...[
                        const SizedBox(height: 16),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _initFuture = _initialize();
                            });
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done && data != null) {
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

class AbusiveTrafficException implements Exception {
  final String message;
  AbusiveTrafficException(this.message);

  @override
  String toString() => 'AbusiveTrafficException: $message';
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
