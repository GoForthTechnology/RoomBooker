// dart format width=80
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
    : super(EmailVerifyRoute.name, initialChildren: children);

  static const String name = 'EmailVerifyRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const EmailVerifyScreen();
    },
  );
}

/// generated route for
/// [EmbedScreen]
class EmbedRoute extends PageRouteInfo<EmbedRouteArgs> {
  EmbedRoute({
    Key? key,
    String? view,
    required String orgID,
    List<PageRouteInfo>? children,
  }) : super(
         EmbedRoute.name,
         args: EmbedRouteArgs(key: key, view: view, orgID: orgID),
         rawPathParams: {'orgID': orgID},
         rawQueryParams: {'v': view},
         initialChildren: children,
       );

  static const String name = 'EmbedRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<EmbedRouteArgs>(
        orElse: () => EmbedRouteArgs(
          view: queryParams.optString('v'),
          orgID: pathParams.getString('orgID'),
        ),
      );
      return EmbedScreen(key: args.key, view: args.view, orgID: args.orgID);
    },
  );
}

class EmbedRouteArgs {
  const EmbedRouteArgs({this.key, this.view, required this.orgID});

  final Key? key;

  final String? view;

  final String orgID;

  @override
  String toString() {
    return 'EmbedRouteArgs{key: $key, view: $view, orgID: $orgID}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EmbedRouteArgs) return false;
    return key == other.key && view == other.view && orgID == other.orgID;
  }

  @override
  int get hashCode => key.hashCode ^ view.hashCode ^ orgID.hashCode;
}

/// generated route for
/// [JoinOrgScreen]
class JoinOrgRoute extends PageRouteInfo<JoinOrgRouteArgs> {
  JoinOrgRoute({Key? key, required String orgID, List<PageRouteInfo>? children})
    : super(
        JoinOrgRoute.name,
        args: JoinOrgRouteArgs(key: key, orgID: orgID),
        rawPathParams: {'orgID': orgID},
        initialChildren: children,
      );

  static const String name = 'JoinOrgRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<JoinOrgRouteArgs>(
        orElse: () => JoinOrgRouteArgs(orgID: pathParams.getString('orgID')),
      );
      return JoinOrgScreen(key: args.key, orgID: args.orgID);
    },
  );
}

class JoinOrgRouteArgs {
  const JoinOrgRouteArgs({this.key, required this.orgID});

  final Key? key;

  final String orgID;

  @override
  String toString() {
    return 'JoinOrgRouteArgs{key: $key, orgID: $orgID}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JoinOrgRouteArgs) return false;
    return key == other.key && orgID == other.orgID;
  }

  @override
  int get hashCode => key.hashCode ^ orgID.hashCode;
}

/// generated route for
/// [LandingScreen]
class LandingRoute extends PageRouteInfo<void> {
  const LandingRoute({List<PageRouteInfo>? children})
    : super(LandingRoute.name, initialChildren: children);

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
class LoginRoute extends PageRouteInfo<LoginRouteArgs> {
  LoginRoute({Key? key, String? orgID, List<PageRouteInfo>? children})
    : super(
        LoginRoute.name,
        args: LoginRouteArgs(key: key, orgID: orgID),
        rawPathParams: {'orgID': orgID},
        initialChildren: children,
      );

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () => LoginRouteArgs(orgID: pathParams.optString('orgID')),
      );
      return LoginScreen(key: args.key, orgID: args.orgID);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.orgID});

  final Key? key;

  final String? orgID;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, orgID: $orgID}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && orgID == other.orgID;
  }

  @override
  int get hashCode => key.hashCode ^ orgID.hashCode;
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
         args: OrgSettingsRouteArgs(key: key, orgID: orgID),
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
            OrgSettingsRouteArgs(orgID: pathParams.getString('orgID')),
      );
      return OrgSettingsScreen(key: args.key, orgID: args.orgID);
    },
  );
}

class OrgSettingsRouteArgs {
  const OrgSettingsRouteArgs({this.key, required this.orgID});

  final Key? key;

  final String orgID;

  @override
  String toString() {
    return 'OrgSettingsRouteArgs{key: $key, orgID: $orgID}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OrgSettingsRouteArgs) return false;
    return key == other.key && orgID == other.orgID;
  }

  @override
  int get hashCode => key.hashCode ^ orgID.hashCode;
}

/// generated route for
/// [ReviewBookingsScreen]
class ReviewBookingsRoute extends PageRouteInfo<ReviewBookingsRouteArgs> {
  ReviewBookingsRoute({
    Key? key,
    required String orgID,
    List<PageRouteInfo>? children,
  }) : super(
         ReviewBookingsRoute.name,
         args: ReviewBookingsRouteArgs(key: key, orgID: orgID),
         rawPathParams: {'orgID': orgID},
         initialChildren: children,
       );

  static const String name = 'ReviewBookingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<ReviewBookingsRouteArgs>(
        orElse: () =>
            ReviewBookingsRouteArgs(orgID: pathParams.getString('orgID')),
      );
      return ReviewBookingsScreen(key: args.key, orgID: args.orgID);
    },
  );
}

class ReviewBookingsRouteArgs {
  const ReviewBookingsRouteArgs({this.key, required this.orgID});

  final Key? key;

  final String orgID;

  @override
  String toString() {
    return 'ReviewBookingsRouteArgs{key: $key, orgID: $orgID}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ReviewBookingsRouteArgs) return false;
    return key == other.key && orgID == other.orgID;
  }

  @override
  int get hashCode => key.hashCode ^ orgID.hashCode;
}

/// generated route for
/// [ViewBookingsScreen]
class ViewBookingsRoute extends PageRouteInfo<ViewBookingsRouteArgs> {
  ViewBookingsRoute({
    Key? key,
    required String orgID,
    String? requestID,
    bool showPrivateBookings = true,
    bool readOnlyMode = false,
    bool createRequest = false,
    DateTime? targetDate,
    String? view,
    List<PageRouteInfo>? children,
  }) : super(
         ViewBookingsRoute.name,
         args: ViewBookingsRouteArgs(
           key: key,
           orgID: orgID,
           requestID: requestID,
           showPrivateBookings: showPrivateBookings,
           readOnlyMode: readOnlyMode,
           createRequest: createRequest,
           targetDate: targetDate,
           view: view,
         ),
         rawPathParams: {'orgID': orgID},
         rawQueryParams: {
           'rid': requestID,
           'spb': showPrivateBookings,
           'ro': readOnlyMode,
           'v': view,
         },
         initialChildren: children,
       );

  static const String name = 'ViewBookingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<ViewBookingsRouteArgs>(
        orElse: () => ViewBookingsRouteArgs(
          orgID: pathParams.getString('orgID'),
          requestID: queryParams.optString('rid'),
          showPrivateBookings: queryParams.getBool('spb', true),
          readOnlyMode: queryParams.getBool('ro', false),
          view: queryParams.optString('v'),
        ),
      );
      return ViewBookingsScreen(
        key: args.key,
        orgID: args.orgID,
        requestID: args.requestID,
        showPrivateBookings: args.showPrivateBookings,
        readOnlyMode: args.readOnlyMode,
        createRequest: args.createRequest,
        targetDate: args.targetDate,
        view: args.view,
      );
    },
  );
}

class ViewBookingsRouteArgs {
  const ViewBookingsRouteArgs({
    this.key,
    required this.orgID,
    this.requestID,
    this.showPrivateBookings = true,
    this.readOnlyMode = false,
    this.createRequest = false,
    this.targetDate,
    this.view,
  });

  final Key? key;

  final String orgID;

  final String? requestID;

  final bool showPrivateBookings;

  final bool readOnlyMode;

  final bool createRequest;

  final DateTime? targetDate;

  final String? view;

  @override
  String toString() {
    return 'ViewBookingsRouteArgs{key: $key, orgID: $orgID, requestID: $requestID, showPrivateBookings: $showPrivateBookings, readOnlyMode: $readOnlyMode, createRequest: $createRequest, targetDate: $targetDate, view: $view}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ViewBookingsRouteArgs) return false;
    return key == other.key &&
        orgID == other.orgID &&
        requestID == other.requestID &&
        showPrivateBookings == other.showPrivateBookings &&
        readOnlyMode == other.readOnlyMode &&
        createRequest == other.createRequest &&
        targetDate == other.targetDate &&
        view == other.view;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      orgID.hashCode ^
      requestID.hashCode ^
      showPrivateBookings.hashCode ^
      readOnlyMode.hashCode ^
      createRequest.hashCode ^
      targetDate.hashCode ^
      view.hashCode;
}
