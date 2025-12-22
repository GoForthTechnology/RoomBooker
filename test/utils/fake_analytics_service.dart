import 'package:flutter/material.dart';
import 'package:room_booker/data/analytics_service.dart';

class FakeAnalyticsService implements AnalyticsService {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void dispose() {}

  @override
  bool get hasListeners => false;

  @override
  void logEvent({required String name, Map<String, Object>? parameters}) {}

  @override
  Widget logView({
    required String viewName,
    required Widget Function() builder,
    Map<String, Object>? parameters,
  }) {
    return builder();
  }

  @override
  void notifyListeners() {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void logScreenView({
    required String screenName,
    Map<String, Object>? parameters,
  }) {}
}
