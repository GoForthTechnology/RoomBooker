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
class NewBookingRoute extends PageRouteInfo<void> {
  const NewBookingRoute({List<PageRouteInfo>? children})
      : super(
          NewBookingRoute.name,
          initialChildren: children,
        );

  static const String name = 'NewBookingRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NewBookingScreen();
    },
  );
}
