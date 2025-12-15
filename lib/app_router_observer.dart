import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class AppRouterObserver extends AutoRouterObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    debugPrint('ROUTER route pushed: ${route.settings.name}');
  }

  // You can override other methods like didPop, didReplace, didRemove
  // to log other navigation events.
  @override
  void didPop(Route route, Route? previousRoute) {
    debugPrint('ROUTER route popped: ${route.settings.name}');
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    debugPrint(
      'ROUTER route replaced: ${oldRoute?.settings.name} with ${newRoute?.settings.name}',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    debugPrint('ROUTER route removed: ${route.settings.name}');
  }
}
