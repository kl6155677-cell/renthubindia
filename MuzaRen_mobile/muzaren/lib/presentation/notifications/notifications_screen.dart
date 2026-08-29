import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/notification/notification_event.dart';
import '../../blocs/notification/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  Future<void> _loadNotifications() async {
    context.read<NotificationBloc>().add(LoadNotifications());
  }

  void _markAllRead() {
    context.read<NotificationBloc>().add(MarkAllRead());
  }

  void _markOneRead(String id) {
    context.read<NotificationBloc>().add(MarkNotificationAsRead(id));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) {
        final notifications = state is NotificationsLoaded ? state.notifications : <NotificationModel>[];
        final unreadCount = state is NotificationsLoaded ? state.unreadCount : 0;
        final isLoading = state is NotificationLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0.5,
            title: const Text('Notifications', 
                style: TextStyle(fontFamily: 'Sora', fontSize: 18, fontWeight: FontWeight.w700)),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: _markAllRead,
                  child: const Text('Mark all read', 
                      style: TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
            ],
          ),
          body: isLoading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: _loadNotifications,
                      child: _buildNotificationList(notifications),
                    ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text('No notifications', 
              style: TextStyle(fontFamily: 'Sora', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 6),
          const Text('You\'re all caught up!', 
              style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 13, color: Color(0xFFD1D5DB))),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    // Group notifications: Today / Yesterday / Earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayList = notifications.where((n) => n.createdAt.isAfter(today)).toList();
    final yesterdayList = notifications.where((n) => n.createdAt.isAfter(yesterday) && n.createdAt.isBefore(today)).toList();
    final earlierList = notifications.where((n) => n.createdAt.isBefore(yesterday)).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (todayList.isNotEmpty) ...[
          _buildSectionHeader('Today'),
          ...todayList.map(_buildNotificationTile),
        ],
        if (yesterdayList.isNotEmpty) ...[
          _buildSectionHeader('Yesterday'),
          ...yesterdayList.map(_buildNotificationTile),
        ],
        if (earlierList.isNotEmpty) ...[
          _buildSectionHeader('Earlier'),
          ...earlierList.map(_buildNotificationTile),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(title, style: const TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF))),
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final isRead = notification.isRead;
    final timeAgo = DateFormat.jm().format(notification.createdAt);

    IconData icon;
    Color iconColor;
    switch (notification.type) {
      case 'booking_update':
        icon = Icons.calendar_today_outlined;
        iconColor = AppColors.primary;
        break;
      case 'new_message':
        icon = Icons.chat_bubble_outline;
        iconColor = AppColors.accent;
        break;
      case 'verification':
        icon = Icons.verified_outlined;
        iconColor = AppColors.success;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = const Color(0xFF6B7280);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) _markOneRead(notification.id);
        // Navigate based on type
        final data = notification.data;
        if (notification.type == 'new_message' && data != null && data['chatId'] != null) {
          context.push('/chat/${data['chatId']}');
        } else if (notification.type == 'booking_update') {
          context.push('/my-bookings');
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: isRead ? null : Border(left: BorderSide(color: AppColors.primary, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: TextStyle(fontFamily: 'Sora', fontSize: 13, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(timeAgo, style: const TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 11, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}
