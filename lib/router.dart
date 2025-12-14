import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/auth.dart';
import 'package:room_booker/ui/screens/embed/embed_screen.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_screen.dart';
import 'package:room_booker/ui/screens/review_bookings/review_bookings_screen.dart';
import 'package:room_booker/ui/screens/landing/landing.dart';
import 'package:room_booker/ui/screens/org_settings/org_settings_screen.dart';
import 'package:room_booker/ui/screens/join_org/join_org_screen.dart';
import 'package:room_booker/ui/screens/view_bookings/view_bookings_view_model.dart';
import 'package:room_booker/ui/widgets/booking_calendar/view_model.dart';
import 'package:room_booker/ui/widgets/request_editor/request_editor_view_model.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(path: "/view/:orgID", page: ViewBookingsRoute.page),
    AutoRoute(page: LandingRoute.page, initial: true),
    AutoRoute(path: "/embed/:orgID", page: EmbedRoute.page),
    AutoRoute(
      path: "/join/:orgID",
      page: JoinOrgRoute.page,
      guards: [AuthGuard()],
    ),
    AutoRoute(
      path: "/org/:orgID",
      page: OrgSettingsRoute.page,
      guards: [AuthGuard()],
    ),
    AutoRoute(
      path: "/review/:orgID",
      page: ReviewBookingsRoute.page,
      guards: [AuthGuard()],
    ),
    ...authRoutes,
  ];
}
