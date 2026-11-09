
import 'package:equatable/equatable.dart';

import '../data/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int total;
  final bool hasMore;
  final int unreadCount;

  const NotificationsLoaded({
    required this.notifications,
    required this.total,
    required this.hasMore,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, total, hasMore, unreadCount];
}

class NotificationActionSuccess extends NotificationState {
  final String action;
  final NotificationModel? notification;
  final String message;

  const NotificationActionSuccess({
    required this.action,
    this.notification,
    required this.message,
  });

  @override
  List<Object?> get props => [action, notification, message];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}