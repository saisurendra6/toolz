import 'dart:developer';

import 'package:flutter/foundation.dart';

class AppLogger {
  static bool _isInitialized = false;
  static bool _isDebug = kDebugMode;

  /// Initialize the logger
  static void initialize({bool isDebug = kDebugMode}) {
    _isDebug = isDebug;
    _isInitialized = true;

    if (_isDebug) {
      log('🔧 AppLogger initialized (Debug mode: $_isDebug)');
    }
  }

  /// Log info message
  static void info(String message) {
    if (_isDebug) {
      log('ℹ️ [INFO] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  /// Log warning message
  static void warning(String message) {
    if (_isDebug) {
      log('⚠️ [WARNING] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  /// Log error message
  static void error(String message) {
    if (_isDebug) {
      log('❌ [ERROR] ${DateTime.now().toIso8601String()}: $message');
    }
  }

  /// Log debug message
  static void debug(String message) {
    if (_isDebug) {
      log('🐛 [DEBUG] ${DateTime.now().toIso8601String()}: $message');
    }
  }
}
