import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/booking_repo.dart';
import 'package:room_booker/router.dart';
import 'package:room_booker/auth.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    FirebaseUIAuth.configureProviders(providers);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BookingRepo()),
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
