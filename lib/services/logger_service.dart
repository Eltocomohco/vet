import 'package:flutter/foundation.dart';

/// Servicio de logging simple que acumula mensajes en memoria.
/// Útil para debuggear en web sin depender de F12.
class LoggerService {
  static final List<LogEntry> _logs = [];
  static const int _maxLogs = 200;

  static List<LogEntry> get logs => List.unmodifiable(_logs);

  static void info(String message, {String? tag}) {
    _add(LogLevel.info, message, tag: tag);
  }

  static void warn(String message, {String? tag}) {
    _add(LogLevel.warn, message, tag: tag);
  }

  static void error(String message, {String? tag, Object? exception, StackTrace? stackTrace}) {
    _add(LogLevel.error, message, tag: tag, exception: exception, stackTrace: stackTrace);
  }

  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _add(LogLevel.debug, message, tag: tag);
    }
  }

  static void _add(LogLevel level, String message, {String? tag, Object? exception, StackTrace? stackTrace}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag ?? 'APP',
      message: message,
      exception: exception?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    _logs.add(entry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // También imprimir a consola
    final emoji = _emoji(level);
    final prefix = '[$emoji ${entry.tag}] ${entry.timeFormatted}';
    debugPrint('$prefix $message');
    if (exception != null) debugPrint('  EXCEPTION: $exception');
    if (stackTrace != null) debugPrint('  STACK: $stackTrace');
  }

  static String _emoji(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🐛';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warn:
        return '⚠️';
      case LogLevel.error:
        return '🔴';
    }
  }

  static void clear() => _logs.clear();

  static int get errorCount => _logs.where((l) => l.level == LogLevel.error).length;
}

enum LogLevel { debug, info, warn, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? exception;
  final String? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.exception,
    this.stackTrace,
  });

  String get timeFormatted =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}';

  String get levelName {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warn:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }
}
