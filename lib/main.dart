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

void main() async {
  // Capture cold start time as early as possible
  final coldStartTime = DateTime.now();

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // AppCheck configuration - using debug provider for debug builds
  // If you want to disable AppCheck entirely for testing, comment this out.
  await FirebaseAppCheck.instance.activate(
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider:
        kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider(
      '6Lej2S0sAAAAAKBEX9lCwb1g4RBlAMb3dXeJHWv-',
    ),
  );

  FirebaseUIAuth.configureProviders(providers);

  final loggingService = getLoggingService();
  final prefs = await SharedPreferences.getInstance();
  loggingService.startColdStartTrace(coldStartTime);

  if (useEmulator && kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      loggingService.info('Using Firebase Emulators');
    } catch (e, stack) {
      loggingService.error('Error connecting to emulators', e, stack);
    }
  }

  // Initialize Sentry
  // We enable it in debug mode too if specifically requested or for debugging auth issues.
  const bool enableSentryInDebug = true;

  if (kDebugMode && !enableSentryInDebug) {
    loggingService.debug(
      'App is running in debug mode, Sentry is disabled',
    );
    runApp(MyApp(prefs: prefs, loggingService: loggingService));
  } else {
    await SentryFlutter.init(
      (options) {
        options.enableLogs = true;
        options.dsn =
            'https://c5ed84ffedec25c193d642e9a8e6ba0f@o4509504243630080.ingest.us.sentry.io/4509504245071872';
        options.sendDefaultPii = true;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
        options.attachScreenshot = true;
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;

        if (kDebugMode) {
          options.debug = true;
          options.environment = 'development';
        } else {
          options.environment = 'production';
        }
      },
      appRunner: () => runZonedGuarded(
        () {
          runApp(
            SentryWidget(
              child: MyApp(prefs: prefs, loggingService: loggingService),
            ),
          );
        },
        (error, stackTrace) {
          loggingService.error("Uncaught top-level error", error, stackTrace);
        },
      ),
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
    try {
      FirebaseAnalytics.instance.logAppOpen();
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
    } catch (e, stack) {
      loggingService.error("Error initializing MyApp", e, stack);
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text("Error initializing app. Please check Sentry/Logs."),
          ),
        ),
      );
    }
  }
}
