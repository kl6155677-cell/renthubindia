import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/logger.dart';
import '../../main.dart'; 
import '../../presentation/widgets/muza_snackbar.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static DateTime? _lastErrorTime;
  static String? _lastErrorMessage;
  
  // Lock mechanism for token refresh
  static bool _isRefreshing = false;
  static final List<Map<String, dynamic>> _failedRequestsQueue = [];

  // Dedicated Dio for token refresh to avoid interceptor recursion
  static final Dio _refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  static void init() {
    // baseUrl is already set in constructor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        AppLogger.request(options.method, options.uri.toString(), data: options.data, query: options.queryParameters);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.response(response.requestOptions.method, response.requestOptions.uri.toString(), response.statusCode, data: response.data);
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        // Log error but don't show it yet if it's a 401 we might handle
        AppLogger.error('🌐 API ${error.requestOptions.method} ${error.requestOptions.uri}', error.response?.data ?? error.message);
        
        String errorMessage = "Something went wrong. Please try again later.";
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        
        if (statusCode == 401) {
          final code = (responseData is Map) ? responseData['code'] : null;
          
          if (code == 'TOKEN_EXPIRED') {
            if (_isRefreshing) {
              _failedRequestsQueue.add({'options': error.requestOptions, 'handler': handler});
              return;
            }
            
            _isRefreshing = true;
            try {
              final refreshToken = await SecureStorage.getRefreshToken();
              if (refreshToken == null) throw Exception("No refresh token");
              
              // Use dedicated refreshDio to avoid interceptors
              final response = await _refreshDio.post(ApiConstants.refresh, data: {'refreshToken': refreshToken});
              final data = response.data['data'];
              
              final newAccessToken = data['accessToken'];
              final newRefreshToken = data['refreshToken'];
              final userJson = data['user'];
              
              await SecureStorage.saveAccessToken(newAccessToken);
              await SecureStorage.saveRefreshToken(newRefreshToken);
              if (userJson != null) await SecureStorage.saveUser(jsonEncode(userJson));

              // Retry current request
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResponse = await _dio.fetch(error.requestOptions);
              handler.resolve(retryResponse);
              
              // Retry queued requests
              for (var req in _failedRequestsQueue) {
                final options = req['options'] as RequestOptions;
                final queuedHandler = req['handler'] as ErrorInterceptorHandler;
                options.headers['Authorization'] = 'Bearer $newAccessToken';
                try {
                  final res = await _dio.fetch(options);
                  queuedHandler.resolve(res);
                } catch (e) {
                  queuedHandler.reject(e is DioException ? e : DioException(requestOptions: options, error: e));
                }
              }
              _failedRequestsQueue.clear();
              _isRefreshing = false;
              return; 
            } catch (e) {
              _failedRequestsQueue.clear();
              _isRefreshing = false;
              
              await SecureStorage.clearAll();
              AppRouter.router.go('/auth');
              return handler.reject(DioException(requestOptions: error.requestOptions, error: "Session expired"));
            }
          } else {
            // Standard 401
            errorMessage = (responseData is Map && responseData['message'] != null) 
                ? responseData['message'] 
                : "Unauthorized access.";
            
            if (errorMessage.contains("Session expired") || errorMessage.contains("revoked")) {
              await SecureStorage.clearAll();
              AppRouter.router.go('/auth');
              return handler.reject(error);
            }
          }
        } else if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
          errorMessage = "No internet connection. Please check your network.";
        } else if (statusCode == 429) {
          errorMessage = "Please verify your account to unlock higher usage limits.";
          final context = AppRouter.rootNavigatorKey.currentContext;
          if (context != null) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text("Rate Limit Exceeded", style: TextStyle(fontFamily: 'Sora', fontWeight: FontWeight.bold)),
                content: const Text(
                  "You have reached your request limit. Verify your identity now to lift these restrictions.",
                  style: TextStyle(fontFamily: 'PlusJakartaSans'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Later", style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E), // AppColors.primary
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AppRouter.router.push('/verification');
                    },
                    child: const Text("Verify Now", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
        } else if (statusCode == 500) {
          errorMessage = "Server error. We are looking into it.";
        } else if (responseData != null && responseData is Map) {
          final dynamic dataMessage = responseData['message'];
          final dynamic dataErrors = responseData['errors'];
          if (dataErrors != null && dataErrors is List && dataErrors.isNotEmpty) {
            final firstError = dataErrors[0];
            if (firstError is Map && firstError['message'] != null) {
              errorMessage = "Check input: ${firstError['message']}";
            }
          } else if (dataMessage is String && dataMessage.isNotEmpty) {
            errorMessage = dataMessage.contains('Error') || dataMessage.contains('Exception') 
              ? "Something went wrong. Please try again." 
              : dataMessage;
          }
        }

        // Show friendly error snackbar
        if (!_isRefreshing) {
          final now = DateTime.now();
          final isDuplicate = _lastErrorMessage == errorMessage && 
                             _lastErrorTime != null && 
                             now.difference(_lastErrorTime!).inMilliseconds < 1500;

          if (!isDuplicate) {
            _lastErrorMessage = errorMessage;
            _lastErrorTime = now;
            MuzaSnackbar.showGlobal(
              messengerKey: rootScaffoldMessengerKey,
              message: errorMessage,
              type: MuzaSnackbarType.error,
            );
          }
        }

        return handler.next(error);
      },
    ));
  }

  static Dio get dio => _dio;
}
