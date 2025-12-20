import 'package:flutter/cupertino.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class LoggingService extends ChangeNotifier {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void fatal(String message, [dynamic error, StackTrace? stackTrace]);
}

class DebugLoggingService extends ChangeNotifier implements LoggingService {
  @override
  void debug(String message) {
    debugPrint("DEBUG: $message");
  }

  @override
  void info(String message) {
    debugPrint("INFO: $message");
  }

  @override
  void warning(String message) {
    debugPrint("WARNING: $message");
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint("ERROR: $message");
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    debugPrint("FATAL: $message");
  }
}

class SentryLoggingService extends ChangeNotifier implements LoggingService {
  @override
  void debug(String message) {
    Sentry.logger.info(message);
  }

  @override
  void info(String message) {
    Sentry.logger.info(message);
  }

  @override
  void warning(String message) {
    Sentry.logger.warn(message);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    Sentry.logger.error(message);
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    Sentry.logger.fatal(message);
  }
}
