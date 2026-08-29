import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/layout/main_layout.dart';
import '../../presentation/auth/phone_auth_screen.dart';
import '../../presentation/auth/otp_verification_screen.dart';
import '../../presentation/location/not_serviceable_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/chat/chat_list_screen.dart';
import '../../presentation/chat/chat_thread_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/profile/public_profile_screen.dart';
import '../../presentation/profile/verification_screen.dart';
import '../../presentation/listing/listing_detail_screen.dart';
import '../../presentation/listing/post/post_listing_screen.dart';
import '../../presentation/booking/booking_screen.dart';
import '../../presentation/booking/my_bookings_screen.dart';
import '../../presentation/profile/my_listings_screen.dart';
import '../../presentation/notifications/notifications_screen.dart';
import '../../presentation/support/support_screen.dart';
import '../../presentation/categories/categories_screen.dart';
import '../../presentation/listing/edit/edit_listing_screen.dart';
import '../../presentation/profile/edit_profile_screen.dart';
import '../../presentation/profile/settings_screen.dart';
import '../../data/models/listing_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorHome = GlobalKey<NavigatorState>(debugLabel: 'shellHome');
  static final GlobalKey<NavigatorState> _shellNavigatorSearch = GlobalKey<NavigatorState>(debugLabel: 'shellSearch');
  static final GlobalKey<NavigatorState> _shellNavigatorChats = GlobalKey<NavigatorState>(debugLabel: 'shellChats');
  static final GlobalKey<NavigatorState> _shellNavigatorProfile = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      final isAuth = authState is AuthAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation == '/auth' || 
                          state.matchedLocation == '/otp-verification';

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (!isAuth && !isAuthRoute && !isSplash) {
        return '/auth';
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final verificationId = state.extra as String? ?? '';
          return OtpVerificationScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: '/not-serviceable',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final city = state.extra as String? ?? 'your city';
          return NotServiceableScreen(city: city);
        },
      ),
      // ── Listings ──
      GoRoute(
        path: '/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/listing/post',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PostListingScreen(),
      ),
      GoRoute(
        path: '/listing/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final listing = state.extra as ListingModel;
          return EditListingScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/listing/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ListingDetailScreen(
            listingId: id,
            heroSuffix: extra['heroSuffix'],
          );
        },
      ),
      // ── Booking ──
      GoRoute(
        path: '/booking',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final listing = state.extra as ListingModel;
          return BookingScreen(listing: listing);
        },
      ),
      GoRoute(
        path: '/my-bookings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/my-listings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MyListingsScreen(),
      ),
      // ── Chat ──
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ChatThreadScreen(
            chatId: id,
            recipientName: extra['recipientName'] ?? 'User',
            recipientAvatar: extra['recipientAvatar'],
            listingId: extra['listingId'],
            listingTitle: extra['listingTitle'],
            listingPrice: extra['listingPrice'],
            listingImageUrl: extra['listingImageUrl'],
          );
        },
      ),
      // ── Notifications ──
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // ── Verification ──
      GoRoute(
        path: '/verification',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VerificationScreen(),
      ),
      // ── Edit Profile ──
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EditProfileScreen(),
      ),
      // ── Public User Profile ──
      GoRoute(
        path: '/user/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicProfileScreen(userId: id);
        },
      ),
      // ── Support ──
      GoRoute(
        path: '/support',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      // ── Settings ──
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      // ── Bottom Nav Shell ──
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHome,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSearch,
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return SearchScreen(
                    initialCategoryId: extra['categoryId'],
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChats,
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
