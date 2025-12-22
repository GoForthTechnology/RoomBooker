import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:room_booker/data/services/logging_service.dart';

abstract class AnalyticsService extends ChangeNotifier {
  void logScreenView({
    required String screenName,
    Map<String, Object>? parameters,
  });

  Widget logView({
    required String viewName,
    required Widget Function() builder,
    Map<String, Object>? parameters,
  });
  void logEvent({required String name, Map<String, Object>? parameters});
}

class FirebaseAnalyticsService extends ChangeNotifier
    implements AnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  final LoggingService _loggingService;

  FirebaseAnalyticsService(this._loggingService);

  @override
  void logScreenView({
    required String screenName,
    Map<String, Object>? parameters,
  }) {
    _loggingService.debug(
      "ANALYTICS: Logging screen view: $screenName, parameters: $parameters",
    );
    _firebaseAnalytics.logScreenView(
      screenName: screenName,
      parameters: parameters,
    );
  }

  @override
  Widget logView({
    required String viewName,
    required Widget Function() builder,
    Map<String, Object>? parameters,
  }) {
    String debugStr = "ANALYTICS: Logging view: $viewName";
    if (parameters != null) {
      debugStr += ", parameters: $parameters";
    }
    _loggingService.debug(debugStr);
    return _loggingService.trace("Create View: $viewName", () => builder());
  }

  @override
  void logEvent({required String name, Map<String, Object>? parameters}) {
    _loggingService.debug("ANALYTICS: Logging event: $name");
    _firebaseAnalytics.logEvent(name: name, parameters: parameters);
  }
}
