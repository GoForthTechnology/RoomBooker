import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:room_booker/data/logging_service.dart';

class AppRouterObserver extends AutoRouterObserver {
  final LoggingService _loggingService;

  AppRouterObserver(this._loggingService);

  @override
  void didPush(Route route, Route? previousRoute) {
    _loggingService.debug('ROUTER route pushed: ${route.settings.name}');
  }

  // You can override other methods like didPop, didReplace, didRemove
  // to log other navigation events.
  @override
  void didPop(Route route, Route? previousRoute) {
    _loggingService.debug('ROUTER route popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _loggingService.debug(
      'ROUTER route replaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _loggingService.debug('ROUTER route removed: ${route.settings.name}');
  }
}
