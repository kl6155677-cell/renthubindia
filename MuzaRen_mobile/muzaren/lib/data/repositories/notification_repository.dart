import '../services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import 'package:dio/dio.dart';

class NotificationResult {
  final List<NotificationModel> notifications;
  final int unreadCount;

  NotificationResult({required this.notifications, required this.unreadCount});
}

class NotificationRepository {
  final Dio _dio = ApiService.dio;

  Future<NotificationResult> getNotifications() async {
    final response = await _dio.get(ApiConstants.notifications);
    
    // Backend returns { success, data: { notifications, unreadCount } }
    final responseData = response.data['data'] ?? {};
    final List<dynamic> list = responseData['notifications'] ?? [];
    final int unreadCount = responseData['unreadCount'] ?? 0;
    
    final notifications = list.map((json) => NotificationModel.fromJson(json)).toList();
    
    return NotificationResult(
      notifications: notifications,
      unreadCount: unreadCount,
    );
  }

  Future<int> markAllRead() async {
    final response = await _dio.patch(ApiConstants.readAllNotifications);
    return response.data['data']?['unreadCount'] ?? 0;
  }

  Future<int> markOneRead(String id) async {
    final response = await _dio.patch(ApiConstants.readNotification(id));
    return response.data['data']?['unreadCount'] ?? 0;
  }
}
