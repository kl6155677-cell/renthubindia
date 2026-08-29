import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class MarkAllRead extends NotificationEvent {}

class MarkNotificationAsRead extends NotificationEvent {
  final String id;

  const MarkNotificationAsRead(this.id);

  @override
  List<Object?> get props => [id];
}
class NotificationReceived extends NotificationEvent {
  final NotificationModel notification;
  final int unreadCount;

  const NotificationReceived({
    required this.notification,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notification, unreadCount];
}
