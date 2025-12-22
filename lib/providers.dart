import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:room_booker/data/services/analytics_service.dart';
import 'package:room_booker/data/services/auth_service.dart';
import 'package:room_booker/data/services/logging_service.dart';
import 'package:room_booker/data/repos/booking_repo.dart';
import 'package:room_booker/data/repos/log_repo.dart';
import 'package:room_booker/data/repos/org_repo.dart';
import 'package:room_booker/data/repos/prefs_repo.dart';
import 'package:room_booker/data/repos/room_repo.dart';
import 'package:room_booker/data/repos/user_repo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProviders extends StatelessWidget {
  final SharedPreferences prefs;
  final LoggingService loggingService;
  final Widget child;
  const AppProviders({
    super.key,
    required this.child,
    required this.loggingService,
    required this.prefs,
  });

  @override
  Widget build(BuildContext context) {
    var logRepo = LogRepo();
    var analyticsService = FirebaseAnalyticsService(loggingService);
    var bookingRepo = BookingRepo(
      logRepo: logRepo,
      analytics: analyticsService,
      logging: loggingService,
    );
    var roomRepo = RoomRepo();
    var userRepo = UserRepo();
    var prefsRepo = PreferencesRepo(prefs);
    var orgRepo = OrgRepo(
      userRepo: userRepo,
      roomRepo: roomRepo,
      logging: loggingService,
      analytics: analyticsService,
    );
    var authService = FirebaseAuthService();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => bookingRepo),
        ChangeNotifierProvider(create: (_) => userRepo),
        ChangeNotifierProvider(create: (_) => orgRepo),
        ChangeNotifierProvider(create: (_) => roomRepo),
        ChangeNotifierProvider(create: (_) => logRepo),
        ChangeNotifierProvider(create: (_) => prefsRepo),
        ChangeNotifierProvider<AnalyticsService>(
          create: (_) => analyticsService,
        ),
        ChangeNotifierProvider<LoggingService>(create: (_) => loggingService),
        ChangeNotifierProvider<AuthService>(create: (_) => authService),
      ],
      child: child,
    );
  }
}
