import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/auth.dart';
import 'package:room_booker/screens/view_bookings_screen.dart';
import 'package:room_booker/screens/review_bookings_screen.dart';
import 'package:room_booker/screens/landing.dart';
import 'package:room_booker/screens/org_settings_screen.dart';
import 'package:room_booker/screens/join_org_screen.dart';
import 'package:room_booker/screens/schedule_screen.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: "/view/:orgID", page: ViewBookingsRoute.page),
        AutoRoute(
            page: LandingRoute.page, initial: true, guards: [AuthGuard()]),
        AutoRoute(
            path: "/schedule/:orgID",
            page: ScheduleRoute.page,
            guards: [AuthGuard()]),
        AutoRoute(
            path: "/join/:orgID",
            page: JoinOrgRoute.page,
            guards: [AuthGuard()]),
        AutoRoute(
            path: "/org/:orgID",
            page: OrgSettingsRoute.page,
            guards: [AuthGuard()]),
        AutoRoute(
            path: "/review/:orgID",
            page: ReviewBookingsRoute.page,
            guards: [AuthGuard()]),
        ...authRoutes,
      ];
}
