import 'dart:ui';

import 'package:room_booker/data/services/logging_service.dart';

class FakeLoggingService implements LoggingService {
  @override
  void addListener(VoidCallback listener) {}

  @override
  void debug(String message) {}

  @override
  void dispose() {}

  @override
  void error(String message, [error, StackTrace? stackTrace]) {}

  @override
  void fatal(String message, [error, StackTrace? stackTrace]) {}

  @override
  void info(String message) {}

  @override
  void notifyListeners() {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  T trace<T>(String operation, T Function() action) {
    return action();
  }

  @override
  bool get hasListeners => false;

  @override
  void warning(String message) {}
}
