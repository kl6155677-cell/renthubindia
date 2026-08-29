import 'package:dio/dio.dart';

class ErrorUtils {
  static String formatError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response?.data as Map;
        // Check for 'message' field in the standard RentHubIndia error response
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        // Check for 'error' field (fallback)
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Please check your internet.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to the server.';
        case DioExceptionType.badResponse:
          return 'Something went wrong on the server. (${error.response?.statusCode})';
        default:
          return 'An unexpected error occurred.';
      }
    }
    return error.toString();
  }
}
