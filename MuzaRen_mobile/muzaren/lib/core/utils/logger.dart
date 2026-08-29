import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = 'RentHubIndia';

  static void info(String message) {
    _log('💡 INFO', message, '\x1B[34m');
  }

  static void success(String message) {
    _log('✅ SUCCESS', message, '\x1B[32m');
  }

  static void warning(String message) {
    _log('⚠️ WARNING', message, '\x1B[33m');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('❌ ERROR', '$message ${error ?? ''}', '\x1B[31m');
    if (stackTrace != null) {
      dev.log(stackTrace.toString(), name: _tag);
    }
  }

  static void request(String method, String url, {dynamic data, Map<String, dynamic>? query}) {
    final log = '🚀 REQUEST [$method] $url\n'
                '   Data: $data\n'
                '   Query: $query';
    _log('🌐 API', log, '\x1B[36m');
  }

  static void response(String method, String url, int? status, {dynamic data}) {
    final log = '🔙 RESPONSE [$method] ($status) $url\n'
                '   Body: $data';
    _log('🌐 API', log, '\x1B[35m');
  }

  static void bloc(String bloc, String transition) {
    _log('🧩 BLOC', '[$bloc] $transition', '\x1B[37m');
  }

  static void _log(String type, String message, String color) {
    if (kDebugMode) {
      final now = DateTime.now().toIso8601String().split('T').last.substring(0, 8);
      // Colored output for VS Code / Terminal
      print('$color[$now] $type: $message\x1B[0m');
    }
  }
}
