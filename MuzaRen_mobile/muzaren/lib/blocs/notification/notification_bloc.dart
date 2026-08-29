import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/models/notification_model.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationBloc({required this.notificationRepository}) : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllRead>(_onMarkAllRead);
    on<NotificationReceived>(_onNotificationReceived);
  }

  Future<void> _onLoadNotifications(LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final result = await notificationRepository.getNotifications();
      emit(NotificationsLoaded(
        notifications: result.notifications,
        unreadCount: result.unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(e.toString()));
    }
  }

  void _onNotificationReceived(NotificationReceived event, Emitter<NotificationState> emit) {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      
      // Prevent duplicates
      final exists = currentState.notifications.any((n) => n.id == event.notification.id);
      if (exists) return;

      final updatedNotifications = [event.notification, ...currentState.notifications];
      emit(NotificationsLoaded(
        notifications: updatedNotifications,
        unreadCount: event.unreadCount,
      ));
    } else {
      // If notifications weren't loaded yet, just state they are now
      emit(NotificationsLoaded(
        notifications: [event.notification],
        unreadCount: event.unreadCount,
      ));
    }
  }

  Future<void> _onMarkNotificationAsRead(MarkNotificationAsRead event, Emitter<NotificationState> emit) async {
    try {
      final newUnreadCount = await notificationRepository.markOneRead(event.id);
      
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationModel(
              id: n.id,
              userId: n.userId,
              title: n.title,
              body: n.body,
              type: n.type,
              isRead: true,
              data: n.data,
              createdAt: n.createdAt,
            );
          }
          return n;
        }).toList();
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ));
      }
    } catch (e) {
      // Fail silently for background marking
    }
  }

  Future<void> _onMarkAllRead(MarkAllRead event, Emitter<NotificationState> emit) async {
    try {
      final newUnreadCount = await notificationRepository.markAllRead();
      
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        final updatedNotifications = currentState.notifications.map((n) {
          return NotificationModel(
            id: n.id,
            userId: n.userId,
            title: n.title,
            body: n.body,
            type: n.type,
            isRead: true,
            data: n.data,
            createdAt: n.createdAt,
          );
        }).toList();
        
        emit(NotificationsLoaded(
          notifications: updatedNotifications,
          unreadCount: newUnreadCount,
        ));
      }
    } catch (e) {
      // Fail silently
    }
  }
}
