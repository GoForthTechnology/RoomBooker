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
/// [JoinOrgScreen]
class JoinOrgRoute extends PageRouteInfo<JoinOrgRouteArgs> {
  JoinOrgRoute({
    Key? key,
    required String orgID,
    List<PageRouteInfo>? children,
  }) : super(
          JoinOrgRoute.name,
          args: JoinOrgRouteArgs(
            key: key,
            orgID: orgID,
          ),
          rawPathParams: {'orgID': orgID},
          initialChildren: children,
        );

  static const String name = 'JoinOrgRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<JoinOrgRouteArgs>(
          orElse: () => JoinOrgRouteArgs(orgID: pathParams.getString('orgID')));
      return JoinOrgScreen(
        key: args.key,
        orgID: args.orgID,
      );
    },
  );
}

class JoinOrgRouteArgs {
  const JoinOrgRouteArgs({
    this.key,
    required this.orgID,
  });

  final Key? key;

  final String orgID;

  @override
  String toString() {
    return 'JoinOrgRouteArgs{key: $key, orgID: $orgID}';
  }
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
    required String orgID,
    List<PageRouteInfo>? children,
  }) : super(
          NewBookingRoute.name,
          args: NewBookingRouteArgs(
            key: key,
            startTime: startTime,
            roomID: roomID,
            orgID: orgID,
          ),
          rawPathParams: {'orgID': orgID},
          initialChildren: children,
        );

  static const String name = 'NewBookingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<NewBookingRouteArgs>(
          orElse: () =>
              NewBookingRouteArgs(orgID: pathParams.getString('orgID')));
      return NewBookingScreen(
        key: args.key,
        startTime: args.startTime,
        roomID: args.roomID,
        orgID: args.orgID,
      );
    },
  );
}

class NewBookingRouteArgs {
  const NewBookingRouteArgs({
    this.key,
    this.startTime,
    this.roomID,
    required this.orgID,
  });

  final Key? key;

  final DateTime? startTime;

  final String? roomID;

  final String orgID;

  @override
  String toString() {
    return 'NewBookingRouteArgs{key: $key, startTime: $startTime, roomID: $roomID, orgID: $orgID}';
  }
}

/// generated route for
/// [OrgSettingsScreen]
class OrgSettingsRoute extends PageRouteInfo<OrgSettingsRouteArgs> {
  OrgSettingsRoute({
    Key? key,
    required String orgID,
    List<PageRouteInfo>? children,
  }) : super(
          OrgSettingsRoute.name,
          args: OrgSettingsRouteArgs(
            key: key,
            orgID: orgID,
          ),
          rawPathParams: {'orgID': orgID},
          initialChildren: children,
        );

  static const String name = 'OrgSettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<OrgSettingsRouteArgs>(
          orElse: () =>
              OrgSettingsRouteArgs(orgID: pathParams.getString('orgID')));
      return OrgSettingsScreen(
        key: args.key,
        orgID: args.orgID,
      );
    },
  );
}

class OrgSettingsRouteArgs {
  const OrgSettingsRouteArgs({
    this.key,
    required this.orgID,
  });

  final Key? key;

  final String orgID;

  @override
  String toString() {
    return 'OrgSettingsRouteArgs{key: $key, orgID: $orgID}';
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
