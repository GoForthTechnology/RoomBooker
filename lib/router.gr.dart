// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [EmailVerifyScreen]
class EmailVerifyRoute extends PageRouteInfo<void> {
  const EmailVerifyRoute({List<PageRouteInfo>? children})
      : super(
          EmailVerifyRoute.name,
          initialChildren: children,
        );

  static const String name = 'EmailVerifyRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmailVerifyScreen();
    },
  );
}

/// generated route for
/// [LandingScreen]
class LandingRoute extends PageRouteInfo<void> {
  const LandingRoute({List<PageRouteInfo>? children})
      : super(
          LandingRoute.name,
          initialChildren: children,
        );

  static const String name = 'LandingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LandingScreen();
    },
  );
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [NewBookingScreen]
class NewBookingRoute extends PageRouteInfo<NewBookingRouteArgs> {
  NewBookingRoute({
    Key? key,
    DateTime? startTime,
    String? roomID,
    List<PageRouteInfo>? children,
  }) : super(
          NewBookingRoute.name,
          args: NewBookingRouteArgs(
            key: key,
            startTime: startTime,
            roomID: roomID,
          ),
          initialChildren: children,
        );

  static const String name = 'NewBookingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<NewBookingRouteArgs>(
          orElse: () => const NewBookingRouteArgs());
      return NewBookingScreen(
        key: args.key,
        startTime: args.startTime,
        roomID: args.roomID,
      );
    },
  );
}

class NewBookingRouteArgs {
  const NewBookingRouteArgs({
    this.key,
    this.startTime,
    this.roomID,
  });

  final Key? key;

  final DateTime? startTime;

  final String? roomID;

  @override
  String toString() {
    return 'NewBookingRouteArgs{key: $key, startTime: $startTime, roomID: $roomID}';
  }
}

/// generated route for
/// [ReviewBookingsScreen]
class ReviewBookingsRoute extends PageRouteInfo<void> {
  const ReviewBookingsRoute({List<PageRouteInfo>? children})
      : super(
          ReviewBookingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'ReviewBookingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ReviewBookingsScreen();
    },
  );
}

/// generated route for
/// [ViewBookingsScreen]
class ViewBookingsRoute extends PageRouteInfo<ViewBookingsRouteArgs> {
  ViewBookingsRoute({
    Key? key,
    required String orgID,
    List<PageRouteInfo>? children,
  }) : super(
          ViewBookingsRoute.name,
          args: ViewBookingsRouteArgs(
            key: key,
            orgID: orgID,
          ),
          rawPathParams: {'orgID': orgID},
          initialChildren: children,
        );

  static const String name = 'ViewBookingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ViewBookingsRouteArgs>(
          orElse: () =>
              ViewBookingsRouteArgs(orgID: pathParams.getString('orgID')));
      return ViewBookingsScreen(
        key: args.key,
        orgID: args.orgID,
      );
    },
  );
}

class ViewBookingsRouteArgs {
  const ViewBookingsRouteArgs({
    this.key,
    required this.orgID,
  });

  final Key? key;

  final String orgID;

  @override
  String toString() {
    return 'ViewBookingsRouteArgs{key: $key, orgID: $orgID}';
  }
}
