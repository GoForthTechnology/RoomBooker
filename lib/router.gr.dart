// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const HomeScreen();
    },
  );
}

/// generated route for
/// [NewBookingScreen]
class NewBookingRoute extends PageRouteInfo<NewBookingRouteArgs> {
  NewBookingRoute({
    Key? key,
    DateTime? startTime,
    List<PageRouteInfo>? children,
  }) : super(
          NewBookingRoute.name,
          args: NewBookingRouteArgs(
            key: key,
            startTime: startTime,
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
      );
    },
  );
}

class NewBookingRouteArgs {
  const NewBookingRouteArgs({
    this.key,
    this.startTime,
  });

  final Key? key;

  final DateTime? startTime;

  @override
  String toString() {
    return 'NewBookingRouteArgs{key: $key, startTime: $startTime}';
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
