import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:room_booker/data/logging_service.dart';

abstract class AnalyticsService extends ChangeNotifier {
  void logScreenView({
    required String screenName,
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
  void logEvent({required String name, Map<String, Object>? parameters}) {
    _loggingService.debug("ANALYTICS: Logging event: $name");
    _firebaseAnalytics.logEvent(name: name, parameters: parameters);
  }
}
