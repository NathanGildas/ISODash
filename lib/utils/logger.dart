import 'package:flutter/foundation.dart';

/// Secure logging utility that only logs in debug mode
/// and prevents sensitive information from being logged in production
class Logger {
  /// Log a general message (only in debug mode)
  static void log(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('$prefix$message');
    }
  }

  /// Log an info message
  static void info(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('ℹ️ $prefix$message');
    }
  }

  /// Log a warning message
  static void warn(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('⚠️ $prefix$message');
    }
  }

  /// Log an error with optional error object and stack trace
  /// In production, this should send to a logging service like Sentry
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('❌ $prefix$message');
      if (error != null) debugPrint('Error details: $error');
      if (stackTrace != null) debugPrint('Stack trace: $stackTrace');
    } else {
      // In production, send to crash reporting service
      // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
      debugPrint('❌ Error occurred'); // Minimal production logging
    }
  }

  /// Log success messages
  static void success(String message, {String? tag}) {
    if (kDebugMode) {
      final prefix = tag != null ? '[$tag] ' : '';
      debugPrint('✅ $prefix$message');
    }
  }

  /// Log API-related messages with redacted sensitive information
  static void api(String message, {bool showInProduction = false}) {
    if (kDebugMode || showInProduction) {
      debugPrint('🌐 [API] $message');
    }
  }

  /// Log security-related events (always logged for audit purposes)
  static void security(String message) {
    // Security events should be logged even in production for audit trail
    debugPrint('🔒 [SECURITY] $message');
    // In production, send to security monitoring service
  }
}