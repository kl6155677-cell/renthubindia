import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/logger.dart';

import '../../data/repositories/auth_repository.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── REGISTER TOKEN ───────────────────────────────────
  static Future<void> registerToken() async {
    try {
      final token = await _instance.getToken();
      if (token != null) {
        final authRepo = AuthRepository();
        await authRepo.updateFcmToken(token);
        AppLogger.success('📲 FCM Token registered');
      }
    } catch (e) {
      AppLogger.error('❌ FCM Registration failed', e);
    }
  }

  // ─── INITIALIZE ───────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Request Permissions (iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      AppLogger.success('✅ Notification permissions granted');
    }

    // 2. Initialize Local Notifications (For Foreground popups)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Standard launcher icon
    
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _handleDeepLink(Map<String, dynamic>.from(data));
        }
      },
    );

    // 3. Create Notification Channel for Android (High Importance)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'renthubindia_channel', // Match backend channelId
      'Muzaren Notifications',
      description: 'Main channel for RentHubIndia updates',
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen(_onMessageForeground);

    // 5. Handle Interaction (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleDeepLink(message.data));
    
    _checkInitialMessage();

    _initialized = true;
  }

  // ─── GET TOKEN ────────────────────────────────────────
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      AppLogger.error('❌ Failed to get FCM token', e);
      return null;
    }
  }

  // ─── FOREGROUND HANDLER ───────────────────────────────
  void _onMessageForeground(RemoteMessage message) {
    AppLogger.info('🔔 FCM Received in Foreground: ${message.notification?.title}');

    // 1. Recipient Filter (Security for shared devices)
    final String? recipientId = message.data['userId']?.toString();
    final context = AppRouter.rootNavigatorKey.currentContext;
    
    if (context != null) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        final String currentUserId = authState.user.id.toString();
        // Only ignore if we are SURE it's for someone else. 
        // If recipientId is missing, we assume it's for the current logged-in user.
        if (recipientId != null && recipientId.isNotEmpty && recipientId != currentUserId) {
          AppLogger.info('🔔 FCM: Ignoring message intended for $recipientId (Current: $currentUserId)');
          return;
        }
      }
      
      // 2. Refresh UI (Notification list + Badge)
      context.read<NotificationBloc>().add(LoadNotifications());
    }

    // 3. Show Heads-up Alert
    if (message.notification != null) {
      _localNotifications.show(
        message.hashCode,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'renthubindia_channel',
            'Muzaren Notifications',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  // ─── TERMINATED STATE HANDLER ────────────────────────
  Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleDeepLink(initialMessage.data);
    }
  }

  // ─── DEEP LINKING LOGIC ──────────────────────────────
  void _handleDeepLink(Map<String, dynamic> data) {
    final String? type = data['type'];
    AppLogger.info('🔗 Deep Linking to type: $type');

    if (type == 'new_message') {
      final chatId = data['chatId'];
      if (chatId != null) {
        AppRouter.router.push('/chat/$chatId');
      }
    } else if (type == 'booking_update') {
      // Navigate to My Bookings or the specific booking if ID exists
      AppRouter.router.go('/my-listings'); 
    } else if (type == 'verification') {
      AppRouter.router.go('/profile');
    } else {
      AppRouter.router.push('/notifications');
    }
  }
}
