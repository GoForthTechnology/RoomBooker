import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

abstract class AnalyticsService {
  void logScreenView(
      {required String screenName, Map<String, Object>? parameters});
  void logEvent({required String name, Map<String, Object>? parameters});
}

class FirebaseAnalyticsService extends ChangeNotifier
    implements AnalyticsService {
  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;

  @override
  void logScreenView(
      {required String screenName, Map<String, Object>? parameters}) {
    _firebaseAnalytics.logScreenView(
        screenName: screenName, parameters: parameters);
  }

  @override
  void logEvent({required String name, Map<String, Object>? parameters}) {
    _firebaseAnalytics.logEvent(name: name, parameters: parameters);
  }
}
