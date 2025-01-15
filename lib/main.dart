import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/repos/org_repo.dart';
import 'package:room_booker/repos/user_repo.dart';
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
    var userRepo = UserRepo();
    var orgRepo = OrgRepo(userRepo: userRepo);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => userRepo),
          ChangeNotifierProvider(create: (_) => orgRepo),
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
