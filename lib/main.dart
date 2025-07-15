import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/auth.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

bool useEmulator = false;

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (useEmulator && kDebugMode) {
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8081);
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }
  await SentryFlutter.init(
    (options) {
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
    },
    appRunner: () => runApp(SentryWidget(child: MyApp())),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logAppOpen();
    FirebaseUIAuth.configureProviders(providers);
    var logRepo = LogRepo();
    var bookingRepo = BookingRepo(logRepo: logRepo);
    var roomRepo = RoomRepo();
    var userRepo = UserRepo();
    var prefsRepo = PreferencesRepo();
    var orgRepo = OrgRepo(userRepo: userRepo, roomRepo: roomRepo);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => bookingRepo),
          ChangeNotifierProvider(create: (_) => userRepo),
          ChangeNotifierProvider(create: (_) => orgRepo),
          ChangeNotifierProvider(create: (_) => roomRepo),
          ChangeNotifierProvider(create: (_) => logRepo),
          ChangeNotifierProvider(create: (_) => prefsRepo),
        ],
        child: MaterialApp.router(
          title: 'Room Booker',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          routerConfig: _appRouter.config(),
        ));
  }
}
