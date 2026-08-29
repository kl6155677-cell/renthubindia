# RentHubIndia — FCM Notification Improvement Prompt
> Give this entire file as a prompt to your AI coding agent.
> It covers every improvement needed to make FCM notifications work perfectly
> on both backend and Flutter, plus adding live notification badge via Socket.IO.

---

## PROMPT (Copy everything below this line)

---

You are a senior full-stack developer working on the RentHubIndia app.

RentHubIndia is a rental marketplace with:
- Backend: Node.js + Express + Prisma + PostgreSQL (Neon) +
  Redis (Upstash) + Socket.IO + Firebase Admin SDK (FCM only)
- Frontend: Flutter with flutter_bloc, go_router, dio,
  firebase_messaging, socket_io_client

I need you to fully improve the FCM push notification integration
on both the backend and Flutter. There are problems with the current
implementation that need to be fixed and new features to add.

Read this entire prompt before writing any code.
After reading, confirm your understanding then wait for me
to tell you which part to start with.

---

## CURRENT PROBLEMS TO FIX

### Backend Problems:
1. FCM is not triggered after all events that should send notifications
2. No Socket.IO event emitted for live in-app notification badge update
3. Notification records not always saved to PostgreSQL before FCM is sent
4. No error handling when FCM token is invalid or expired
5. FCM payload structure is inconsistent across different trigger points

### Flutter Problems:
1. FCM token not reliably registered after login
2. FCM token not refreshed when it changes
3. Foreground messages not showing in-app banner
4. Background notification tap not deep linking to correct screen
5. Terminated app notification tap not deep linking to correct screen
6. Notification bell badge count not updating live (only on screen open)
7. No handling when FCM token is null or unavailable

---

## PART 1 — BACKEND IMPROVEMENTS

---

### Step 1: Create a Central Notification Service

Create: `src/utils/notifications.js`

This is the single place where ALL notification logic lives.
Every module (bookings, chat, auth, reports) calls this service.
Never call FCM directly from a controller or socket handler.

```javascript
const admin = require('firebase-admin');
const { prisma } = require('../config/db');

/**
 * Send a notification to a user.
 * Always saves to PostgreSQL first, then sends FCM if token exists,
 * then emits Socket.IO event for live badge update.
 *
 * @param {object} io - Socket.IO server instance
 * @param {object} params
 * @param {string} params.userId - recipient user ID
 * @param {string} params.title - notification title
 * @param {string} params.body - notification body text
 * @param {string} params.type - type: booking_update | new_message | verification | system
 * @param {object} params.data - extra data for deep linking { chatId, listingId, bookingId }
 */
async function sendNotification(io, { userId, title, body, type, data = {} }) {
  try {
    // ── STEP 1: Save notification to PostgreSQL ──────────────
    // Always save first — even if FCM fails, user sees it in bell screen
    const notification = await prisma.notification.create({
      data: {
        userId,
        title,
        body,
        type,
        isRead: false,
        data: data,
      },
    });

    // ── STEP 2: Get unread count for badge ───────────────────
    const unreadCount = await prisma.notification.count({
      where: { userId, isRead: false },
    });

    // ── STEP 3: Emit Socket.IO event for live badge update ───
    // This updates the bell badge instantly if user is in the app
    if (io) {
      io.to(`user_${userId}`).emit('notification_received', {
        notification: {
          id: notification.id,
          title,
          body,
          type,
          data,
          isRead: false,
          createdAt: notification.createdAt,
        },
        unreadCount,
      });
    }

    // ── STEP 4: Send FCM push if user has a token ────────────
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: { fcmToken: true },
    });

    if (user?.fcmToken) {
      await sendFCM(user.fcmToken, { title, body, type, data, userId });
    }

    return notification;
  } catch (error) {
    console.error(`❌ Failed to send notification to user ${userId}:`, error);
    // Never throw — notification failure should never crash the main flow
  }
}

/**
 * Send raw FCM push notification to a device token.
 * Handles invalid token errors by clearing the token from DB.
 */
async function sendFCM(fcmToken, { title, body, type, data, userId }) {
  try {
    const message = {
      token: fcmToken,
      notification: {
        title,
        body,
      },
      data: {
        // All data values must be strings for FCM
        type: type || 'system',
        chatId: data.chatId || '',
        listingId: data.listingId || '',
        bookingId: data.bookingId || '',
        userId: userId || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'renthubindia_channel',
          priority: 'high',
          defaultSound: true,
          defaultVibrateTimings: true,
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            badge: 1,
            sound: 'default',
            contentAvailable: true,
          },
        },
        headers: {
          'apns-priority': '10',
        },
      },
    };

    await admin.messaging().send(message);
    console.log(`✅ FCM sent to user ${userId}`);
  } catch (error) {
    // Handle invalid/expired FCM token
    if (
      error.code === 'messaging/invalid-registration-token' ||
      error.code === 'messaging/registration-token-not-registered'
    ) {
      console.warn(`⚠️ Invalid FCM token for user ${userId} — clearing token`);
      // Clear the invalid token from the database
      if (userId) {
        await prisma.user.update({
          where: { id: userId },
          data: { fcmToken: null },
        });
      }
    } else {
      console.error('❌ FCM send error:', error);
    }
  }
}

/**
 * Send notification to multiple users at once.
 * Used for admin broadcasts (future feature).
 */
async function sendBulkNotification(io, userIds, { title, body, type, data }) {
  const promises = userIds.map((userId) =>
    sendNotification(io, { userId, title, body, type, data })
  );
  await Promise.allSettled(promises);
}

module.exports = { sendNotification, sendFCM, sendBulkNotification };
```

---

### Step 2: Update Socket.IO to Support User Rooms

In `src/config/socket.js`, update the connection handler so each
user joins a personal room named `user_{userId}`.
This is how the notification service targets a specific user
via Socket.IO without knowing their socket ID.

```javascript
// In the io.on('connection') handler, ADD this line:
socket.join(`user_${userId}`);
```

Full updated connection section:
```javascript
io.on('connection', (socket) => {
  const userId = socket.userId;

  // Track user as online
  onlineUsers.set(userId, socket.id);

  // Join personal room for targeted notifications
  socket.join(`user_${userId}`);   // ← ADD THIS LINE

  // ... rest of existing event handlers remain unchanged
});
```

---

### Step 3: Pass io Instance to All Modules

The `sendNotification` function needs the Socket.IO `io` instance.
Update `src/config/socket.js` to export `io` so other modules can use it:

```javascript
// At the top of socket.js, add:
let _io = null;

function getIO() {
  if (!_io) throw new Error('Socket.IO not initialized');
  return _io;
}

function initSocket(httpServer) {
  _io = new Server(httpServer, { ... });
  // ... rest of existing initSocket code
  return _io;
}

module.exports = { initSocket, getIO, onlineUsers };
```

Then in any module that needs to send notifications:
```javascript
const { getIO } = require('../config/socket');
const { sendNotification } = require('../../utils/notifications');

// Usage:
const io = getIO();
await sendNotification(io, { userId, title, body, type, data });
```

---

### Step 4: Add Notification Triggers to All Events

Update each module to call `sendNotification` at the right moment.
Below is every trigger point that must send a notification:

---

#### 4A — Bookings Module (`src/modules/bookings/bookings.service.js`)

**When a booking is CREATED (renter books an item):**
```javascript
// Notify the OWNER that someone wants to rent their item
await sendNotification(io, {
  userId: booking.ownerId,
  title: 'New Booking Request',
  body: `${renterName} wants to rent your "${listingTitle}"`,
  type: 'booking_update',
  data: { bookingId: booking.id, listingId: booking.listingId },
});
```

**When a booking is ACCEPTED (owner accepts):**
```javascript
// Notify the RENTER their booking was accepted
await sendNotification(io, {
  userId: booking.renterId,
  title: 'Booking Accepted! 🎉',
  body: `Your booking for "${listingTitle}" has been accepted`,
  type: 'booking_update',
  data: { bookingId: booking.id, listingId: booking.listingId },
});
```

**When a booking is CANCELLED:**
```javascript
// Notify the OTHER party (not whoever cancelled)
await sendNotification(io, {
  userId: cancelledByOwner ? booking.renterId : booking.ownerId,
  title: 'Booking Cancelled',
  body: `The booking for "${listingTitle}" has been cancelled`,
  type: 'booking_update',
  data: { bookingId: booking.id, listingId: booking.listingId },
});
```

**When a booking is COMPLETED:**
```javascript
// Notify the RENTER to leave a review
await sendNotification(io, {
  userId: booking.renterId,
  title: 'Rental Complete',
  body: `How was your rental of "${listingTitle}"? Leave a review!`,
  type: 'booking_update',
  data: { bookingId: booking.id, listingId: booking.listingId },
});
```

---

#### 4B — Chat Module (`src/modules/chat/chat.service.js` + `socket.js`)

**When a message is received and receiver is OFFLINE:**
```javascript
// Already in socket.js send_message handler
// Make sure it uses the central sendNotification function:
await sendNotification(io, {
  userId: receiver.id,
  title: senderName,
  body: text.length > 50 ? text.substring(0, 50) + '...' : text,
  type: 'new_message',
  data: { chatId: chat.id },
});
```

**When an IMAGE message is uploaded via REST:**
```javascript
// In chat.service.js uploadImage function, after saving message:
await sendNotification(io, {
  userId: receiver.id,
  title: senderName,
  body: '📷 Sent you a photo',
  type: 'new_message',
  data: { chatId },
});
```

---

#### 4C — Users Module (`src/modules/users/users.service.js`)

**When admin VERIFIES a user:**
```javascript
await sendNotification(io, {
  userId: user.id,
  title: 'Identity Verified ✓',
  body: 'Your account has been verified. You can now post high-value items!',
  type: 'verification',
  data: {},
});
```

---

#### 4D — Reports Module (`src/modules/admin/admin.service.js`)

**When admin takes action on a REPORT:**
```javascript
// Notify the reporter that their report was resolved
await sendNotification(io, {
  userId: report.reporterId,
  title: 'Report Update',
  body: 'Your report has been reviewed and action has been taken.',
  type: 'system',
  data: {},
});
```

---

#### 4E — Support Module (`src/modules/support/support.service.js`)

**When admin REPLIES to a support ticket:**
```javascript
await sendNotification(io, {
  userId: ticket.userId,
  title: 'Support Reply',
  body: `We replied to your ticket: "${ticket.subject}"`,
  type: 'system',
  data: {},
});
```

---

### Step 5: Update FCM Token Endpoint

In `src/modules/users/users.service.js`, update the FCM token
save logic to handle duplicates and validation:

```javascript
async function updateFcmToken(userId, fcmToken) {
  // Validate token is not empty
  if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim() === '') {
    throw new Error('Invalid FCM token');
  }

  // If another user has this same token, clear it from them first
  // (happens when same device logs into different accounts)
  await prisma.user.updateMany({
    where: {
      fcmToken: fcmToken,
      id: { not: userId },
    },
    data: { fcmToken: null },
  });

  // Save token to current user
  return prisma.user.update({
    where: { id: userId },
    data: { fcmToken: fcmToken.trim() },
  });
}
```

---

### Step 6: Update Notifications REST Endpoints

In `src/modules/notifications/notifications.service.js`:

**GET /api/notifications** — include unread count in response:
```javascript
async function getNotifications(userId) {
  const [notifications, unreadCount] = await Promise.all([
    prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50, // max 50 notifications
    }),
    prisma.notification.count({
      where: { userId, isRead: false },
    }),
  ]);

  return { notifications, unreadCount };
}
```

**PATCH /api/notifications/read-all** — return updated unread count:
```javascript
async function markAllRead(userId) {
  await prisma.notification.updateMany({
    where: { userId, isRead: false },
    data: { isRead: true },
  });

  return { unreadCount: 0 };
}
```

**PATCH /api/notifications/:id/read** — return updated unread count:
```javascript
async function markOneRead(userId, notificationId) {
  await prisma.notification.update({
    where: { id: notificationId, userId },
    data: { isRead: true },
  });

  const unreadCount = await prisma.notification.count({
    where: { userId, isRead: false },
  });

  return { unreadCount };
}
```

---

## PART 2 — FLUTTER IMPROVEMENTS

---

### Step 1: Update fcm_service.dart

Rewrite: `lib/data/services/fcm_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

// Top-level function required for background message handling
// Must be outside any class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by the system automatically
  // Only add custom logic here if absolutely needed
  print('📩 Background message received: ${message.messageId}');
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();

  // ─── INITIALIZE ─────────────────────────────────────────
  // Call once in main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    // Set background handler (must be top-level function)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize local notifications for foreground display
    await _initLocalNotifications();

    // Request permission
    await requestPermission();

    // Set foreground notification presentation options
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app was TERMINATED
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay to ensure app is fully initialized before navigating
      await Future.delayed(const Duration(seconds: 1));
      _handleNotificationTap(initialMessage);
    }
  }

  // ─── REQUEST PERMISSION ──────────────────────────────────
  Future<void> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ FCM permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ FCM provisional permission granted');
    } else {
      print('❌ FCM permission denied');
    }
  }

  // ─── GET & REGISTER TOKEN ───────────────────────────────
  // Call after login — registers token with backend
  Future<void> registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        print('⚠️ FCM token is null — skipping registration');
        return;
      }

      // Check if token has changed since last registration
      final savedToken = await _storage.read(key: 'fcm_token');
      if (savedToken == token) {
        print('ℹ️ FCM token unchanged — skipping registration');
        return;
      }

      // Register with backend
      final api = ApiService();
      await api.post('/api/users/fcm-token', {'fcmToken': token});

      // Save token locally so we can detect changes
      await _storage.write(key: 'fcm_token', value: token);
      print('✅ FCM token registered');
    } catch (e) {
      // Never throw — FCM registration failure should not break the app
      print('❌ FCM token registration failed: $e');
    }
  }

  // ─── LISTEN FOR TOKEN REFRESH ───────────────────────────
  // Call after login — re-registers if token changes
  void listenForTokenRefresh() {
    _messaging.onTokenRefresh.listen((newToken) async {
      print('🔄 FCM token refreshed');
      try {
        final api = ApiService();
        await api.post('/api/users/fcm-token', {'fcmToken': newToken});
        await _storage.write(key: 'fcm_token', value: newToken);
        print('✅ Refreshed FCM token registered');
      } catch (e) {
        print('❌ FCM token refresh registration failed: $e');
      }
    });
  }

  // ─── CLEAR TOKEN ON LOGOUT ──────────────────────────────
  Future<void> clearToken() async {
    await _storage.delete(key: 'fcm_token');
    // Note: We do NOT delete the token from the backend here
    // because the backend clears invalid tokens automatically
    // when FCM returns registration-token-not-registered error
  }

  // ─── HANDLE FOREGROUND MESSAGE ──────────────────────────
  void _handleForegroundMessage(RemoteMessage message) {
    print('📩 Foreground message: ${message.notification?.title}');

    // Show local notification so user sees it even in foreground
    _showLocalNotification(message);
  }

  // ─── HANDLE NOTIFICATION TAP ────────────────────────────
  // Works for both background and terminated app states
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.data}');
    _navigateFromNotification(message.data);
  }

  // ─── NAVIGATE BASED ON NOTIFICATION TYPE ────────────────
  void _navigateFromNotification(Map<String, dynamic> data) {
    final type = data['type'] ?? 'system';
    final chatId = data['chatId'];
    final bookingId = data['bookingId'];
    final listingId = data['listingId'];

    // Use your app's router to navigate
    // Replace with your actual go_router navigation
    final router = AppRouter.router; // adjust to your router instance

    switch (type) {
      case 'new_message':
        if (chatId != null && chatId.isNotEmpty) {
          router.push('/chat/$chatId');
        } else {
          router.push('/chat');
        }
        break;

      case 'booking_update':
        if (bookingId != null && bookingId.isNotEmpty) {
          router.push('/my-bookings');
        } else {
          router.push('/my-bookings');
        }
        break;

      case 'verification':
        router.push('/profile');
        break;

      case 'system':
      default:
        router.push('/notifications');
        break;
    }
  }

  // ─── LOCAL NOTIFICATIONS SETUP ──────────────────────────
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (details) {
        // Handle tap on local notification (foreground)
        if (details.payload != null) {
          final data = Uri.splitQueryString(details.payload!);
          _navigateFromNotification(data);
        }
      },
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'renthubindia_channel',
      'RentHubIndia Notifications',
      description: 'Notifications for bookings, messages, and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ─── SHOW LOCAL NOTIFICATION ────────────────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'renthubindia_channel',
      'RentHubIndia Notifications',
      channelDescription: 'Notifications for bookings, messages, and updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: Uri(queryParameters: message.data).query,
    );
  }
}
```

---

### Step 2: Add flutter_local_notifications Package

In `pubspec.yaml` add:
```yaml
flutter_local_notifications: ^17.0.0
```

Run: `flutter pub get`

This package is needed to show notifications when app is in foreground.
`firebase_messaging` alone does NOT show UI when app is open.

---

### Step 3: Update main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize FCM service (sets up background handler, local notifications)
  await FCMService().initialize();

  runApp(const RentHubIndiaApp());
}
```

---

### Step 4: Update AuthBloc to Register FCM Token

In `lib/blocs/auth/auth_bloc.dart`:

After emitting `AuthAuthenticated` state (both on login and on
app start token validation), call FCM token registration:

```dart
// After successful login or token validation:
emit(AuthAuthenticated(user));

// Register FCM token (non-blocking — never awaited)
FCMService().registerToken();
FCMService().listenForTokenRefresh();

// Connect WebSocket
chatBloc.add(ConnectSocket());

// Detect location
locationBloc.add(DetectLocation());
```

After logout:
```dart
// Clear FCM token from local storage
await FCMService().clearToken();

// Disconnect socket
chatBloc.add(DisconnectSocket());

// Clear token from secure storage
await SecureStorage.deleteToken();

emit(AuthUnauthenticated());
```

---

### Step 5: Update NotificationBloc

Rewrite: `lib/blocs/notification/notification_bloc.dart`

The bloc must now handle BOTH REST loading AND live Socket.IO updates:

```dart
// Events:
class LoadNotifications extends NotificationEvent {}
class MarkAllRead extends NotificationEvent {}
class MarkOneRead extends NotificationEvent {
  final String notificationId;
}
// New: triggered by Socket.IO 'notification_received' event
class LiveNotificationReceived extends NotificationEvent {
  final Map<String, dynamic> notification;
  final int unreadCount;
}

// States:
class NotificationInitial extends NotificationState {}
class NotificationLoading extends NotificationState {}
class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;  // ← used for bell badge
}
class NotificationError extends NotificationState {
  final String message;
}
```

In the bloc's constructor, listen to the WebSocket
`notification_received` event and dispatch `LiveNotificationReceived`:

```dart
NotificationBloc({
  required this.notificationRepository,
  required WebSocketChatService socketService,
}) : super(NotificationInitial()) {
  // Listen for live notifications from Socket.IO
  socketService.onNotificationReceived((data) {
    add(LiveNotificationReceived(
      notification: data['notification'],
      unreadCount: data['unreadCount'],
    ));
  });

  on<LoadNotifications>(_onLoadNotifications);
  on<MarkAllRead>(_onMarkAllRead);
  on<MarkOneRead>(_onMarkOneRead);
  on<LiveNotificationReceived>(_onLiveNotificationReceived);
}

Future<void> _onLiveNotificationReceived(
  LiveNotificationReceived event,
  Emitter<NotificationState> emit,
) async {
  // Add new notification to the top of the list
  // Update badge count immediately
  if (state is NotificationsLoaded) {
    final current = state as NotificationsLoaded;
    final newNotification = NotificationModel.fromJson(event.notification);
    emit(NotificationsLoaded(
      notifications: [newNotification, ...current.notifications],
      unreadCount: event.unreadCount,
    ));
  } else {
    // If list not loaded yet, just update badge
    emit(NotificationsLoaded(
      notifications: [],
      unreadCount: event.unreadCount,
    ));
  }
}
```

---

### Step 6: Add notification_received Listener to WebSocketChatService

In `lib/data/services/websocket_chat_service.dart`, add:

```dart
// Add this listener method to WebSocketChatService:
void onNotificationReceived(Function(Map<String, dynamic>) callback) {
  _socket?.on('notification_received', (data) => callback(data));
}
```

---

### Step 7: Update Bell Badge in Bottom Navigation

In `lib/features/shell/main_shell.dart`:

The Messages tab badge should show NOTIFICATION unread count,
not just message count. Update it to read from `NotificationBloc`:

```dart
BlocBuilder<NotificationBloc, NotificationState>(
  builder: (context, state) {
    final unreadCount = state is NotificationsLoaded
        ? state.unreadCount
        : 0;

    return Stack(
      children: [
        Icon(Icons.notifications_outlined),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  },
),
```

---

### Step 8: Update Notifications Screen

In `lib/features/notifications/notifications_screen.dart`:

Update to use new `NotificationsLoaded` state with `unreadCount`:

```dart
// On screen open — load notifications
context.read<NotificationBloc>().add(LoadNotifications());

// On mark all read
context.read<NotificationBloc>().add(MarkAllRead());

// On single tap — mark read then navigate
context.read<NotificationBloc>().add(MarkOneRead(notificationId: n.id));
_navigateFromNotification(n.type, n.data);

// Navigate based on notification type
void _navigateFromNotification(String type, Map<String, dynamic>? data) {
  switch (type) {
    case 'new_message':
      final chatId = data?['chatId'];
      if (chatId != null) context.push('/chat/$chatId');
      else context.push('/chat');
      break;
    case 'booking_update':
      context.push('/my-bookings');
      break;
    case 'verification':
      context.push('/profile');
      break;
    default:
      break; // stay on notifications screen
  }
}
```

---

### Step 9: Android Configuration

In `android/app/src/main/AndroidManifest.xml`, add inside `<application>`:

```xml
<!-- FCM default notification channel -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="renthubindia_channel" />

<!-- FCM default notification icon -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/ic_launcher" />

<!-- FCM default notification color -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

Create `android/app/src/main/res/values/colors.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="notification_color">#0D6E75</color>
</resources>
```

Also add this intent filter to the `<activity>` tag so tapping a
notification opens the correct screen even when app is terminated:
```xml
<intent-filter>
    <action android:name="FLUTTER_NOTIFICATION_CLICK" />
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
```

---

### Step 10: iOS Configuration

In `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    
    // Required for FCM on iOS
    UNUserNotificationCenter.current().delegate = self
    application.registerForRemoteNotifications()
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

In `ios/Runner/Info.plist`, add:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

---

## PART 3 — COMPLETE EVENT TRIGGER REFERENCE

Every event that must send a notification, where it is triggered,
and what the notification content must be:

| Event | Triggered in | Recipient | Title | Body | Type | Data |
|-------|-------------|-----------|-------|------|------|------|
| Booking created | bookings.service.js | Owner | "New Booking Request" | "{renter} wants to rent {listing}" | booking_update | { bookingId, listingId } |
| Booking accepted | bookings.service.js | Renter | "Booking Accepted! 🎉" | "Your booking for {listing} was accepted" | booking_update | { bookingId, listingId } |
| Booking cancelled | bookings.service.js | Other party | "Booking Cancelled" | "The booking for {listing} was cancelled" | booking_update | { bookingId, listingId } |
| Booking completed | bookings.service.js | Renter | "Rental Complete" | "Leave a review for {listing}!" | booking_update | { bookingId, listingId } |
| Text message (offline) | socket.js | Receiver | Sender name | Message text (truncated 50 chars) | new_message | { chatId } |
| Image message | chat.service.js | Receiver | Sender name | "📷 Sent you a photo" | new_message | { chatId } |
| User verified | users.service.js (admin) | User | "Identity Verified ✓" | "You can now post high-value items!" | verification | {} |
| Report resolved | admin.service.js | Reporter | "Report Update" | "Your report has been reviewed" | system | {} |
| Support replied | support.service.js | User | "Support Reply" | "We replied to your ticket" | system | {} |

---

## PART 4 — IMPORTANT RULES

1. The central `sendNotification` function in `src/utils/notifications.js`
   must ALWAYS be called in this exact order:
   a) Save to PostgreSQL first
   b) Emit Socket.IO event second
   c) Send FCM third
   Never skip step a — even if FCM fails, the notification must
   exist in the database for the bell screen.

2. FCM errors must NEVER crash or reject the main request.
   Always wrap FCM calls in try-catch. A failed notification
   must not fail a booking acceptance or message send.

3. Invalid FCM tokens (messaging/registration-token-not-registered)
   must be cleared from the database immediately to avoid wasting
   FCM quota on dead tokens.

4. The flutter_local_notifications package is REQUIRED to show
   notifications when the app is in the foreground.
   firebase_messaging alone does not show UI in foreground.

5. The background handler firebaseMessagingBackgroundHandler
   MUST be a top-level function (outside any class) and registered
   before runApp() is called.

6. FCM token registration must be idempotent — if the token has
   not changed since the last registration, do not call the backend
   again. Use SharedPreferences/SecureStorage to track the last
   registered token.

7. The Socket.IO user room must be named exactly `user_{userId}`
   (with underscore). The notification service targets this room.

8. All data values in FCM message.data must be strings.
   Never pass null, numbers, or objects in the data payload.
   Use empty string '' for missing values.

9. Show me every file you create or modify — complete code,
   no truncation.

10. Start with Part 1 (Backend) first. After I confirm the
    backend is working, proceed to Part 2 (Flutter).
    After Flutter is done, verify Part 3 trigger reference
    is fully implemented.
```
