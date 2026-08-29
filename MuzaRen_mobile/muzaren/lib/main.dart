import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/bloc_observer.dart';
import 'core/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/listing_repository.dart';
import 'data/repositories/booking_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/review_repository.dart';
import 'data/models/notification_model.dart';

// Services
import 'data/services/api_service.dart';
import 'data/services/local_cache_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/websocket_chat_service.dart';

// BLoCs
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/listing/listing_bloc.dart';
import 'blocs/booking/booking_bloc.dart';
import 'blocs/chat/chat_bloc.dart';
import 'blocs/chat/chat_event.dart';
import 'blocs/notification/notification_bloc.dart';
import 'blocs/notification/notification_event.dart';
import 'blocs/location/location_bloc.dart';
import 'blocs/location/location_event.dart';
import 'blocs/category/category_bloc.dart';
import 'blocs/category/category_event.dart';
import 'blocs/review/review_bloc.dart';
import 'blocs/auth/auth_state.dart';

// Router & Theme
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Background messages are automatically handled as system tray notifications
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  await FCMService().initialize();
  ApiService.init();
  await LocalCacheService.init(); // Open Hive boxes before any BLoC runs
  
  Bloc.observer = AppBlocObserver();
  AppLogger.success('🚀 App Started');

  // Global Crash & Error Handler
  FlutterError.onError = (details) {
    AppLogger.error('🛠️ FLUTTER ERROR', details.exception, details.stack);
  };

  // Custom Error Widget (Replaces Red Screen of Death)
  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_very_dissatisfied, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontFamily: 'Sora', fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'We encountered a small technical glitch. Our team has been notified.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'PlusJakartaSans', color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => AppRouter.router.go('/home'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Return Home'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const RentHubIndiaApp());
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class RentHubIndiaApp extends StatefulWidget {
  const RentHubIndiaApp({super.key});

  @override
  State<RentHubIndiaApp> createState() => _RentHubIndiaAppState();
}

class _RentHubIndiaAppState extends State<RentHubIndiaApp> {
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => ListingRepository()),
        RepositoryProvider(create: (_) => BookingRepository()),
        RepositoryProvider(create: (_) => ChatRepository()),
        RepositoryProvider(create: (_) => NotificationRepository()),
        RepositoryProvider(create: (_) => CategoryRepository()),
        RepositoryProvider(create: (_) => ReviewRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ChatBloc(
              chatRepository: context.read<ChatRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => LocationBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
              locationBloc: context.read<LocationBloc>(),
              chatBloc: context.read<ChatBloc>(),
            )..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => ListingBloc(
              listingRepository: context.read<ListingRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => BookingBloc(
              bookingRepository: context.read<BookingRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => NotificationBloc(
              notificationRepository: context.read<NotificationRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CategoryBloc(
              categoryRepository: context.read<CategoryRepository>(),
            )..add(LoadCategories()),
          ),
          BlocProvider(
            create: (context) => ReviewBloc(
              reviewRepository: context.read<ReviewRepository>(),
            ),
          ),
        ],
        child: _AuthDependentInit(
          child: MaterialApp.router(
            title: 'RentHubIndia',
            theme: AppTheme.lightTheme,
            scaffoldMessengerKey: rootScaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}

/// Handles socket + notification init that depends on auth state.
/// Uses both a BlocListener (for future changes) and initState (for
/// the case where AuthAuthenticated was already emitted before mount).
class _AuthDependentInit extends StatefulWidget {
  final Widget child;
  const _AuthDependentInit({required this.child});

  @override
  State<_AuthDependentInit> createState() => _AuthDependentInitState();
}

class _AuthDependentInitState extends State<_AuthDependentInit> {
  bool _socketInitialized = false;

  @override
  void initState() {
    super.initState();
    // Check if auth state is already authenticated (was emitted before this widget mounted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && !_socketInitialized) {
        _initForAuth(context);
      }
    });
  }

  void _initForAuth(BuildContext context) {
    if (_socketInitialized) return;
    _socketInitialized = true;
    print('🔌 Initializing socket connection (auth detected)');
    context.read<ChatBloc>().add(ConnectSocket());
    context.read<LocationBloc>().add(const DetectLocation());
    context.read<NotificationBloc>().add(LoadNotifications());

    // ─── LIVE NOTIFICATION SYNC ───
    WebSocketChatService().onNotificationReceived((data) {
      final notification = NotificationModel.fromJson(
          Map<String, dynamic>.from(data['notification'] as Map));
      final unreadCount = data['unreadCount'] as int;

      context.read<NotificationBloc>().add(NotificationReceived(
            notification: notification,
            unreadCount: unreadCount,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _initForAuth(context);
        } else if (state is AuthUnauthenticated) {
          _socketInitialized = false;
          context.read<ChatBloc>().add(DisconnectSocket());
        }
      },
      child: widget.child,
    );
  }
}
