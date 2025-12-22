import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class LoggingService extends ChangeNotifier {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
  void fatal(String message, [dynamic error, StackTrace? stackTrace]);

  T trace<T>(String operation, T Function() action);
}

class DebugLoggingService extends ChangeNotifier implements LoggingService {
  final Logger _logger = Logger(printer: CustomLogPrinter());

  @override
  void debug(String message) {
    _logger.d(message);
  }

  @override
  void info(String message) {
    _logger.i(message);
  }

  @override
  void warning(String message) {
    _logger.w(message);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message);
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message);
  }

  @override
  T trace<T>(String operation, T Function() action) {
    return action();
  }
}

class CustomLogPrinter extends PrettyPrinter {
  CustomLogPrinter({
    int super.methodCount,
    int super.errorMethodCount,
    super.lineLength,
    super.colors,
    super.printEmojis,
    bool super.printTime = false,
  }) : super(
         stackTraceBeginIndex: 1, // This ignores the first frame
       );
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

  @override
  T trace<T>(String operation, T Function() action) {
    final span = Sentry.getSpan()?.startChild(operation);
    try {
      return action();
    } catch (e) {
      span?.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      span?.finish();
    }
  }
}
