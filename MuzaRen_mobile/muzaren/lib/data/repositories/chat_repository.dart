import '../services/api_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class ChatRepository {
  // Create or get existing chat
  Future<Map<String, dynamic>> createOrGetChat(
      String listingId, String ownerId) async {
    final response = await ApiService.dio.post('/api/chat', data: {
      'listingId': listingId,
      'ownerId': ownerId,
    });
    return Map<String, dynamic>.from(response.data['chat'] as Map);
  }

  // Get all conversations for current user
  Future<List<ConversationModel>> getConversations() async {
    final response = await ApiService.dio.get('/api/chat/conversations');
    final List data = response.data['conversations'] as List;
    return data
        .map((c) => ConversationModel.fromJson(Map<String, dynamic>.from(c as Map)))
        .toList();
  }

  // Get paginated message history (REST fallback)
  Future<List<MessageModel>> getMessages(String chatId,
      {int page = 1, int limit = 50}) async {
    final response = await ApiService.dio
        .get('/api/chat/$chatId/messages', queryParameters: {'page': page, 'limit': limit});
    final List data = response.data['messages'] as List;
    return data
        .map((m) => MessageModel.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
  }

  // Upload image message via REST (not socket)
  Future<MessageModel> uploadImage(String chatId, File imageFile, {String? replyToId}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path),
      'replyToId': ?replyToId,
    });
    final response =
        await ApiService.dio.post('/api/chat/$chatId/upload', data: formData);
    return MessageModel.fromJson(
        Map<String, dynamic>.from(response.data['message'] as Map));
  }

  // Mark messages as read (REST backup)
  Future<void> markRead(String chatId) async {
    await ApiService.dio.patch('/api/chat/$chatId/read');
  }

  // Edit message
  Future<MessageModel> editMessage(String messageId, String text) async {
    final response = await ApiService.dio.patch('/api/chat/messages/$messageId', data: {
      'text': text,
    });
    return MessageModel.fromJson(
        Map<String, dynamic>.from(response.data['message'] as Map));
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    await ApiService.dio.delete('/api/chat/messages/$messageId');
  }

  // Delete entire conversation
  Future<void> deleteChat(String chatId) async {
    await ApiService.dio.delete('/api/chat/$chatId');
  }
}
