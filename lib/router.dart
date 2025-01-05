import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/auth.dart';
import 'package:room_booker/screens/new_booking_screen.dart';
import 'package:room_booker/screens/view_bookings_screen.dart';
import 'package:room_booker/screens/review_bookings_screen.dart';
import 'package:room_booker/screens/landing.dart';
import 'package:room_booker/screens/org_settings_screen.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: "/view/:orgID", page: ViewBookingsRoute.page),
        AutoRoute(path: "/request", page: NewBookingRoute.page),
        AutoRoute(
            page: LandingRoute.page, initial: true, guards: [AuthGuard()]),
        AutoRoute(
            path: "/org/:orgID",
            page: OrgSettingsRoute.page,
            guards: [AuthGuard()]),
        AutoRoute(
            path: "/review",
            page: ReviewBookingsRoute.page,
            guards: [AuthGuard()]),
        ...authRoutes,
      ];
}
