import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/repos/room_repo.dart';
import 'package:room_booker/repos/user_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/auth.dart';
import 'firebase_options.dart';

bool useEmulator = true;

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
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics.instance.logAppOpen();
    FirebaseUIAuth.configureProviders(providers);
    var bookingRepo = BookingRepo();
    var roomRepo = RoomRepo();
    var userRepo = UserRepo();
    var orgRepo = OrgRepo(userRepo: userRepo);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => bookingRepo),
          ChangeNotifierProvider(create: (_) => userRepo),
          ChangeNotifierProvider(create: (_) => orgRepo),
          ChangeNotifierProvider(create: (_) => roomRepo),
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
