import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/auth.dart';
import 'package:room_booker/ui/view_bookings/view_bookings_screen.dart';
import 'package:room_booker/ui/review_bookings/review_bookings_screen.dart';
import 'package:room_booker/ui/landing/landing.dart';
import 'package:room_booker/ui/org_settings/org_settings_screen.dart';
import 'package:room_booker/ui/join_org/join_org_screen.dart';
import 'package:room_booker/ui/schedule/schedule_screen.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(path: "/view/:orgID", page: ViewBookingsRoute.page),
        AutoRoute(page: LandingRoute.page, initial: true),
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
