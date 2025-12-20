import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:room_booker/data/logging_service.dart';
import 'package:room_booker/providers.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/auth.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:room_booker/app_router_observer.dart';

bool useEmulator = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    providerWeb: ReCaptchaV3Provider(
      '6Lej2S0sAAAAAKBEX9lCwb1g4RBlAMb3dXeJHWv-',
    ),
  );
  final prefs = await SharedPreferences.getInstance();

  if (useEmulator && kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }
  var loggingService = SentryLoggingService();
  if (kDebugMode) {
    // App is running in debug mode
    loggingService.debug(
      'App is running in debug mode, not initializing Sentry',
    );
    runApp(MyApp(prefs: prefs, loggingService: loggingService));
  } else {
    await SentryFlutter.init(
      (options) {
        options.enableLogs = true;
        options.dsn =
            'https://c5ed84ffedec25c193d642e9a8e6ba0f@o4509504243630080.ingest.us.sentry.io/4509504245071872';
        // Adds request headers and IP for users, for more info visit:
        // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
        options.sendDefaultPii = true;
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
        // The sampling rate for profiling is relative to tracesSampleRate
        // Setting to 1.0 will profile 100% of sampled transactions:
        options.profilesSampleRate = 1.0;
        options.attachScreenshot = true;
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;
      },
      appRunner: () => runApp(
        SentryWidget(
          child: MyApp(prefs: prefs, loggingService: loggingService),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final LoggingService loggingService;

  MyApp({super.key, required this.prefs, required this.loggingService});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    try {
      FirebaseAnalytics.instance.logAppOpen();
      FirebaseUIAuth.configureProviders(providers);
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
    } catch (e) {
      loggingService.error("Error initializing MyApp: $e");
      return Text("Error initializing app");
    }
  }
}
