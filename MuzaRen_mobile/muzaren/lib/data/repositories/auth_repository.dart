import 'dart:convert';
import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../models/user_model.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  final Dio _dio = ApiService.dio;

  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post(ApiConstants.login, data: {
      'email': email,
      'password': password,
    });
    
    final data = response.data['data'];
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final userJson = data['user'];
    
    await SecureStorage.saveAccessToken(accessToken);
    await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveUser(jsonEncode(userJson));
    
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> firebaseLogin(String idToken) async {
    final response = await _dio.post(ApiConstants.firebaseLogin, data: {
      'idToken': idToken,
    });
    
    final data = response.data['data'];
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final userJson = data['user'];
    
    await SecureStorage.saveAccessToken(accessToken);
    await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveUser(jsonEncode(userJson));
    
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> register(String name, String email, String password, {String? phone}) async {
    final response = await _dio.post(ApiConstants.register, data: {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    });
    
    final data = response.data['data'];
    final accessToken = data['accessToken'];
    final refreshToken = data['refreshToken'];
    final userJson = data['user'];
    
    await SecureStorage.saveAccessToken(accessToken);
    await SecureStorage.saveRefreshToken(refreshToken);
    await SecureStorage.saveUser(jsonEncode(userJson));
    
    return UserModel.fromJson(userJson);
  }

  /// Refreshes the access and refresh tokens using the provided refresh token
  Future<void> refreshTokens(String refreshToken) async {
    final response = await _dio.post(ApiConstants.refresh, data: {
      'refreshToken': refreshToken,
    });
    
    final data = response.data['data'];
    final newAccessToken = data['accessToken'];
    final newRefreshToken = data['refreshToken'];
    
    await SecureStorage.saveAccessToken(newAccessToken);
    await SecureStorage.saveRefreshToken(newRefreshToken);
  }

  Future<void> logout() async {
    try {
      final refreshToken = await SecureStorage.getRefreshToken();
      
      // Notify backend to invalidate tokens
      await _dio.post(ApiConstants.logout, data: {
        'refreshToken': refreshToken,
      });
    } catch (e) {
      // Proceed with local logout even if server request fails
    } finally {
      await SecureStorage.deleteAccessToken();
      await SecureStorage.deleteRefreshToken();
      await SecureStorage.deleteUser();
    }
  }

  Future<UserModel> getUserProfile() async {
    final response = await _dio.get(ApiConstants.userProfile);
    final data = response.data['data'];
    await SecureStorage.saveUser(jsonEncode(data));
    return UserModel.fromJson(data);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put(ApiConstants.userProfile, data: data);
    final userJson = response.data['data'];
    await SecureStorage.saveUser(jsonEncode(userJson));
    return UserModel.fromJson(userJson);
  }

  Future<UserModel> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });
    final response = await _dio.post(ApiConstants.userAvatar, data: formData);
    final userJson = response.data['data'];
    await SecureStorage.saveUser(jsonEncode(userJson));
    return UserModel.fromJson(userJson);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _dio.post('${ApiConstants.userProfile}/change-password', data: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> deleteAccount() async {
    await _dio.delete(ApiConstants.userProfile);
    await logout();
  }

  Future<UserModel> getPublicProfile(String userId) async {
    final response = await _dio.get(ApiConstants.userDetail(userId));
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> updateFcmToken(String token) async {
    await _dio.post(ApiConstants.updateFcmToken, data: {'fcmToken': token});
  }

  Future<UserModel?> getCachedUser() async {
    final userStr = await SecureStorage.getUser();
    if (userStr != null) {
      return UserModel.fromJson(jsonDecode(userStr));
    }
    return null;
  }
}
