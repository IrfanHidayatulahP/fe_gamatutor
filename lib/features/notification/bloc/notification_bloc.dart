import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../../core/network/websocket_manager.dart';
import '../../../../../core/utils/constants.dart';
import '../repository/notification_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _repository;
  final WebSocketManager _wsManager;
  StreamSubscription? _wsSubscription;
  String? _currentUserId;

  NotificationBloc({
    NotificationRepository? repository,
    WebSocketManager? wsManager,
  })  : _repository = repository ?? sl<NotificationRepository>(),
        _wsManager = wsManager ?? sl<WebSocketManager>(),
        super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkAsRead>(_onMarkAsRead);
    on<MarkAsClicked>(_onMarkAsClicked);
    on<MarkAllAsRead>(_onMarkAllAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<NotificationRealtimeEvent>(_onRealtimeEvent);

    _setupWebSocketListeners();
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  void _setupWebSocketListeners() {
    _wsManager.on(WebSocketEvents.notificationReceived, _handleNotificationReceived);
    _wsManager.on(WebSocketEvents.notificationRead, _handleNotificationRead);
  }

  void _handleNotificationReceived(Map<String, dynamic> data) {
    add(NotificationRealtimeEvent(data: data));
  }

  void _handleNotificationRead(Map<String, dynamic> data) {
    add(NotificationRealtimeEvent(data: data));
  }

  Future<void> _onLoadNotifications(
    LoadNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationLoading());
    try {
      final response = await _repository.getNotifications(
        type: event.type,
        read: event.read,
        delivered: event.delivered,
        limit: event.limit,
        offset: event.offset,
      );

      final unreadCount = response.notifications.where((n) => !n.read).length;

      emit(NotificationsLoaded(
        notifications: response.notifications,
        total: response.total,
        hasMore: response.notifications.length < response.total,
        unreadCount: unreadCount,
      ));
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notification = await _repository.markAsRead(event.notifId);
      if (notification != null) {
        emit(NotificationActionSuccess(
          action: 'read',
          notification: notification,
          message: 'Marked as read',
        ));
        add(LoadNotifications());
      }
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkAsClicked(
    MarkAsClicked event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final notification = await _repository.markAsClicked(event.notifId);
      if (notification != null) {
        emit(NotificationActionSuccess(
          action: 'click',
          notification: notification,
          message: 'Marked as clicked',
        ));
      }
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await _repository.markAllAsRead();
      if (success) {
        emit(const NotificationActionSuccess(
          action: 'read_all',
          notification: null,
          message: 'All marked as read',
        ));
        add(LoadNotifications());
      }
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final success = await _repository.deleteNotification(event.notifId);
      if (success) {
        emit(const NotificationActionSuccess(
          action: 'delete',
          notification: null,
          message: 'Notification deleted',
        ));
        add(LoadNotifications());
      }
    } catch (e) {
      emit(NotificationError(message: e.toString()));
    }
  }

  Future<void> _onRealtimeEvent(
    NotificationRealtimeEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final eventType = event.data['event'] ?? event.data['type'];
    final data = event.data['data'] ?? event.data;

    switch (eventType) {
      case WebSocketEvents.notificationReceived:
        if (data['userId'] == _currentUserId) {
          add(LoadNotifications());
        }
        break;
      case WebSocketEvents.notificationRead:
        add(LoadNotifications());
        break;
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}