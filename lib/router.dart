import 'package:auto_route/auto_route.dart';
import 'package:room_booker/screens/new_booking_screen.dart';
import 'package:room_booker/screens/homepage.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: HomeRoute.page, initial: true),
        AutoRoute(page: NewBookingRoute.page),
      ];
}
