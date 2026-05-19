import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();

  static void info(String message) {
    if (kDebugMode) {
      print('🏔️ [INFO] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  static void warn(String message) {
    if (kDebugMode) {
      print('⚠️ [WARNING] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('🚨 [ERROR] ${DateTime.now().toIso8601String()}: $message');
      if (error != null) print('Detail: $error');
      if (stackTrace != null) print(stackTrace);
    }
  }

  static void success(String message) {
    if (kDebugMode) {
      print('✅ [SUCCESS] ${DateTime.now().toIso8601String()}: $message');
    }
  }
}
