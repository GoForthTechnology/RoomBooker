import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/auth.dart';
import 'package:room_booker/screens/new_booking_screen.dart';
import 'package:room_booker/screens/homepage.dart';
import 'package:room_booker/screens/review_bookings_screen.dart';
import 'package:room_booker/screens/landing.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
            page: LandingRoute.page, initial: true, guards: [AuthGuard()]),
        AutoRoute(path: "/book", page: HomeRoute.page),
        AutoRoute(path: "/request", page: NewBookingRoute.page),
        AutoRoute(
            path: "/review",
            page: ReviewBookingsRoute.page,
            guards: [AuthGuard()]),
        ...authRoutes,
      ];
}
