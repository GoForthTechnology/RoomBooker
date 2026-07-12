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

  void startColdStartTrace(DateTime startTime);
  void stopColdStartTrace();
}

class DebugLoggingService extends ChangeNotifier implements LoggingService {
  final Logger _logger = Logger(printer: CustomLogPrinter());
  bool _coldStartTraceStopped = false;

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
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  @override
  T trace<T>(String operation, T Function() action) {
    return action();
  }

  @override
  void startColdStartTrace(DateTime startTime) {
    _logger.i("Starting cold start trace at $startTime");
    _coldStartTraceStopped = false;
  }

  @override
  void stopColdStartTrace() {
    if (!_coldStartTraceStopped) {
      _logger.i("Stopping cold start trace");
      _coldStartTraceStopped = true;
    }
  }
}

class CustomLogPrinter extends LogPrinter {
  static const _levelLabels = {
    Level.trace: 'T',
    Level.debug: 'D',
    Level.info: 'I',
    Level.warning: 'W',
    Level.error: 'E',
    Level.fatal: 'F',
  };

  @override
  List<String> log(LogEvent event) {
    final now = event.time;
    final ts =
        '[${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}]';
    final label = '[${_levelLabels[event.level]}]';
    final msg = event.message?.toString() ?? '';
    final err = event.error != null ? ' — ${event.error}' : '';
    return ['$ts$label $msg$err'];
  }
}

class SentryLoggingService extends ChangeNotifier implements LoggingService {
  ISentrySpan? _coldStartTrace;

  @override
  void debug(String message) {
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: SentryLevel.debug),
    );
  }

  @override
  void info(String message) {
    Sentry.addBreadcrumb(Breadcrumb(message: message, level: SentryLevel.info));
  }

  @override
  void warning(String message) {
    Sentry.addBreadcrumb(
      Breadcrumb(message: message, level: SentryLevel.warning),
    );
    Sentry.captureMessage(message, level: SentryLevel.warning);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    Sentry.captureException(
      error ?? message,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('log_message', message);
        scope.level = SentryLevel.error;
      },
    );
  }

  @override
  void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    Sentry.captureException(
      error ?? message,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('log_message', message);
        scope.level = SentryLevel.fatal;
      },
    );
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

  @override
  void startColdStartTrace(DateTime startTime) {
    _coldStartTrace = Sentry.startTransaction(
      'cold_start_to_calendar',
      'ui.load',
      startTimestamp: startTime,
      bindToScope: true,
    );
  }

  @override
  void stopColdStartTrace() {
    if (_coldStartTrace != null) {
      _coldStartTrace?.status = const SpanStatus.ok();
      _coldStartTrace?.finish();
      _coldStartTrace = null;
    }
  }
}
