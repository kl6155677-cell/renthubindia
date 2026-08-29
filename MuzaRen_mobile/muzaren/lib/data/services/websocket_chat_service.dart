import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class WebSocketChatService {
  static final WebSocketChatService _instance = WebSocketChatService._internal();
  factory WebSocketChatService() => _instance;
  WebSocketChatService._internal();

  IO.Socket? _socket;
  final _storage = const FlutterSecureStorage();

  // Stored callback for notification_received — survives connect/reconnect
  Function(Map<String, dynamic>)? _notificationCallback;

  // Dedicated Dio for token refresh (no interceptors to avoid recursion)
  static final Dio _refreshDio = Dio(
    BaseOptions(baseUrl: ApiConstants.baseUrl, connectTimeout: const Duration(seconds: 10)),
  );

  // WebSocket backend URL — must match the backend host exactly
  static const String _wsUrl = 'https://renthubindia-production-b4bd.up.railway.app';

  bool get isConnected => _socket?.connected ?? false;

  // ─── REFRESH TOKEN ─────────────────────────────────────
  /// Proactively refreshes the access token before socket connection.
  /// Returns the fresh access token, or null if refresh fails.
  Future<String?> _getValidToken() async {
    try {
      final refreshToken = await _storage.read(key: 'jwt_refresh_token');
      if (refreshToken == null) {
        print('⚠️ No refresh token found, cannot refresh');
        return await _storage.read(key: 'jwt_access_token');
      }

      // Call the refresh endpoint to get a brand-new access token
      final response = await _refreshDio.post(
        ApiConstants.refresh,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data['data'];
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String?;

      // Persist the fresh tokens
      await _storage.write(key: 'jwt_access_token', value: newAccessToken);
      if (newRefreshToken != null) {
        await _storage.write(key: 'jwt_refresh_token', value: newRefreshToken);
      }

      print('🔄 Socket: access token refreshed successfully');
      return newAccessToken;
    } catch (e) {
      print('⚠️ Token refresh failed, falling back to stored token: $e');
      // Fallback: use whatever is in storage — backend will reject if truly expired
      return await _storage.read(key: 'jwt_access_token');
    }
  }

  // ─── CONNECT ───────────────────────────────────────────
  Future<void> connect() async {
    // Already connected — no-op
    if (isConnected) return;

    // Always get a fresh token before connecting to avoid expired-token auth failures.
    // The access token expires in 15 min but the socket bypasses the Dio interceptor.
    final token = await _getValidToken();
    if (token == null) {
      print('⚠️ No JWT token available, skipping socket connect');
      return;
    }

    // Dispose any stale socket from a previous session
    _socket?.dispose();
    _socket = null;

    _buildAndConnectSocket(token);

    // Wait up to 10 seconds for connection, then proceed anyway
    await _connectionCompleter!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ WebSocket connect timed out after 10s, proceeding anyway');
      },
    );
  }

  Completer<void>? _connectionCompleter;

  /// Builds a Socket.IO instance with the given token and connects it.
  void _buildAndConnectSocket(String token) {
    _connectionCompleter = Completer<void>();

    _socket = IO.io(
      _wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionAttempts(3)
          .setAuth({'token': 'Bearer $token'})
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ WebSocket connected');
      if (_connectionCompleter?.isCompleted == false) {
        _connectionCompleter!.complete();
      }
      // Re-apply stored notification listener on every (re)connect
      if (_notificationCallback != null) {
        _socket?.on('notification_received', (data) =>
            _notificationCallback!(Map<String, dynamic>.from(data)));
      }
    });

    _socket!.onConnectError((err) async {
      print('❌ WebSocket connect error: $err');
      final errStr = err.toString();
      // If auth failed, try once more with a force-refreshed token
      if (errStr.contains('Authentication failed') || errStr.contains('No token') || errStr.contains('Token revoked')) {
        print('🔄 Auth error detected — attempting token refresh and reconnect...');
        _socket?.dispose();
        _socket = null;
        final freshToken = await _getValidToken();
        if (freshToken != null && (_connectionCompleter?.isCompleted == false)) {
          _buildAndConnectSocket(freshToken);
          _socket?.connect();
          return; // Don't complete the completer — let the new socket do it
        }
      }
      if (_connectionCompleter?.isCompleted == false) {
        _connectionCompleter!.complete(); // Unblock caller on non-auth errors
      }
    });

    _socket!.onDisconnect((_) {
      print('❌ WebSocket disconnected');
    });

    _socket!.on('error', (data) {
      print('! Socket error: $data');
    });

    _socket!.connect();
  }

  // ─── DISCONNECT ────────────────────────────────────────
  void disconnect() {
    _notificationCallback = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ─── JOIN CHAT ─────────────────────────────────────────
  void joinChat(String chatId) {
    _socket?.emit('join_chat', {'chatId': chatId});
  }

  // ─── LEAVE CHAT ────────────────────────────────────────
  void leaveChat(String chatId) {
    _socket?.emit('leave_chat', {'chatId': chatId});
  }

  // ─── SEND TEXT MESSAGE (Feature 3: added replyToId) ────
  void sendMessage(String chatId, String text, String tempId, {String? replyToId}) {
    print('📤 sendMessage called — socket connected: $isConnected, socket null: ${_socket == null}');
    if (_socket == null || !isConnected) {
      print('❌ Cannot send message: socket is ${_socket == null ? "null" : "disconnected"}');
      return;
    }
    _socket!.emit('send_message', {
      'chatId': chatId, 
      'text': text,
      'tempId': tempId,
      'replyToId': replyToId,
    });
    print('📤 send_message emitted for tempId=$tempId');
  }

  // ─── LOAD MORE MESSAGES (Feature: Pagination) ──────────
  void loadMoreMessages(String chatId, int skip) {
    _socket?.emit('load_more_messages', {
      'chatId': chatId,
      'skip': skip,
    });
  }

  // ─── MARK AS READ ──────────────────────────────────────
  void markRead(String chatId) {
    _socket?.emit('mark_read', {'chatId': chatId});
  }

  // ─── TYPING INDICATORS ─────────────────────────────────
  void sendTyping(String chatId) {
    _socket?.emit('typing', {'chatId': chatId});
  }

  void sendStopTyping(String chatId) {
    _socket?.emit('stop_typing', {'chatId': chatId});
  }

  // ─── ACTIONS (Features 1, 2, 4) ───────────────────────
  void deleteMessage(String messageId, String deleteType) {
    _socket?.emit('delete_message', {
      'messageId': messageId,
      'deleteType': deleteType,
    });
  }

  void editMessage(String messageId, String newText) {
    _socket?.emit('edit_message', {
      'messageId': messageId,
      'newText': newText,
    });
  }

  void reactToMessage(String messageId, String emoji) {
    _socket?.emit('react_message', {
      'messageId': messageId,
      'emoji': emoji,
    });
  }

  void deleteChat(String chatId) {
    _socket?.emit('delete_chat', {
      'chatId': chatId,
    });
  }

  // ─── LISTENERS ─────────────────────────────────────────
  void onChatHistory(Function(Map<String, dynamic>) callback) {
    _socket?.on('chat_history', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onNewMessage(Function(Map<String, dynamic>) callback) {
    _socket?.on('new_message', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onMessageSent(Function(Map<String, dynamic>) callback) {
    _socket?.on('message_sent', (data) {
      print('📩 message_sent received from server: ${data.runtimeType}');
      callback(Map<String, dynamic>.from(data));
    });
  }

  void onMessagesRead(Function(Map<String, dynamic>) callback) {
    _socket?.on('messages_read', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onUserTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('user_typing', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onStopTyping(Function(Map<String, dynamic>) callback) {
    _socket?.on('stop_typing', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    _socket?.on('message_deleted', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onNotificationReceived(Function(Map<String, dynamic>) callback) {
    // Store the callback so it can be re-applied on (re)connect
    _notificationCallback = callback;
    // Also register immediately if the socket is already connected
    _socket?.on('notification_received', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onMessageEdited(Function(Map<String, dynamic>) callback) {
    _socket?.on('message_edited', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onMessageReacted(Function(Map<String, dynamic>) callback) {
    _socket?.on('message_reacted', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onChatDeleted(Function(Map<String, dynamic>) callback) {
    _socket?.on('chat_deleted', (data) => callback(Map<String, dynamic>.from(data)));
  }

  void onMoreMessagesLoaded(Function(Map<String, dynamic>) callback) {
    _socket?.on('more_messages_loaded', (data) => callback(Map<String, dynamic>.from(data)));
  }

  // Remove all listeners
  void removeListeners() {
    _socket?.off('chat_history');
    _socket?.off('new_message');
    _socket?.off('message_sent');
    _socket?.off('messages_read');
    _socket?.off('user_typing');
    _socket?.off('stop_typing');
    _socket?.off('message_deleted');
    _socket?.off('message_edited');
    _socket?.off('message_reacted');
    _socket?.off('chat_deleted');
    _socket?.off('more_messages_loaded');
    _socket?.off('notification_received');
  }
}
