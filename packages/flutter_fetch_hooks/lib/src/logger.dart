import 'dart:developer' as developer;
import 'package:logging/logging.dart';

const loggerName = 'flutter fetch';

void log(String message, {
  DateTime? time,
  level = Level.INFO,
}) {
  developer.log(
    '[${level.name}] ${DateTime.now()} $message',
    level: level.value,
    time: DateTime.now(),
    name: loggerName,
  );
}

void logError(String message, Exception exception, {
  DateTime? time,
  level = Level.SHOUT,
}) {
  developer.log(
    '[${level.name}] ${DateTime.now()} $message',
    level: level.value,
    time: DateTime.now(),
    name: loggerName,
    error: exception,
    stackTrace: StackTrace.current,
  );
}