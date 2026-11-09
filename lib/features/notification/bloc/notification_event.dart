
import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotifications extends NotificationEvent {
  final String? type;
  final bool? read;
  final bool? delivered;
  final int limit;
  final int offset;

  const LoadNotifications({
    this.type,
    this.read,
    this.delivered,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [type, read, delivered, limit, offset];
}

class MarkAsRead extends NotificationEvent {
  final String notifId;

  const MarkAsRead({required this.notifId});

  @override
  List<Object?> get props => [notifId];
}

class MarkAsClicked extends NotificationEvent {
  final String notifId;

  const MarkAsClicked({required this.notifId});

  @override
  List<Object?> get props => [notifId];
}

class MarkAllAsRead extends NotificationEvent {
  const MarkAllAsRead();
}

class DeleteNotification extends NotificationEvent {
  final String notifId;

  const DeleteNotification({required this.notifId});

  @override
  List<Object?> get props => [notifId];
}

class NotificationRealtimeEvent extends NotificationEvent {
  final Map<String, dynamic> data;

  const NotificationRealtimeEvent({required this.data});

  @override
  List<Object?> get props => [data];
}