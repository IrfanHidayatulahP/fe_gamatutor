import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../data/notification_model.dart';

class NotificationToast extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const NotificationToast({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 4),
  });

  @override
  State<NotificationToast> createState() => _NotificationToastState();

  // Public method to show notification from outside
  static void show(BuildContext context, NotificationModel notification) {
    final state = context.findAncestorStateOfType<_NotificationToastState>();
    state?._showNotification(notification);
  }
}

class _NotificationToastState extends State<NotificationToast> {
  final List<NotificationModel> _pendingNotifications = [];
  NotificationModel? _currentNotification;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
  }

  void _showNotification(NotificationModel notification) {
    if (_isShowing) {
      _pendingNotifications.add(notification);
    } else {
      _displayNotification(notification);
    }
  }

  void _displayNotification(NotificationModel notification) {
    setState(() {
      _currentNotification = notification;
      _isShowing = true;
    });

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted && _currentNotification?.notifId == notification.notifId) {
        _dismissCurrent();
      }
    });
  }

  void _dismissCurrent() {
    setState(() {
      _isShowing = false;
      _currentNotification = null;
    });

    // Show next pending notification
    if (_pendingNotifications.isNotEmpty) {
      final next = _pendingNotifications.removeAt(0);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _displayNotification(next);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isShowing && _currentNotification != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: _buildToast(_currentNotification!),
            ),
          ),
      ],
    );
  }

  Widget _buildToast(NotificationModel notification) {
    return AnimatedSlide(
      offset: _isShowing ? Offset.zero : const Offset(0, -1.5),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _isShowing ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: () {
            _handleToastTap(notification);
            _dismissCurrent();
          },
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 500) {
              _dismissCurrent();
            }
          },
          child: Card(
            elevation: 8,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getNotificationColor(notification.type).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.title ?? _getDefaultTitle(notification.type),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notification.triggerUser != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: notification.triggerUser!.avatarUrl != null
                                    ? NetworkImage(notification.triggerUser!.avatarUrl!)
                                    : null,
                                child: notification.triggerUser!.avatarUrl == null
                                    ? Text(
                                        notification.triggerUser!.initials,
                                        style: const TextStyle(fontSize: 8),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                notification.triggerUser!.fullName,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Dismiss button
                  IconButton(
                    onPressed: _dismissCurrent,
                    icon: Icon(Icons.close, size: 20, color: Colors.grey[500]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'friend_request_received':
      case 'friend_request_accepted':
      case 'friend_request_rejected':
        return Icons.person_add;
      case 'call_incoming':
      case 'call_missed':
        return Icons.call;
      case 'group_call_invite':
      case 'group_call_starting':
        return Icons.call;
      case 'collaboration_invite':
      case 'collab_new_message':
      case 'mention_in_collab':
      case 'card_updated_by_collaborator':
        return Icons.folder_shared;
      case 'smart_reminder':
      case 'encouragement':
        return Icons.lightbulb;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'friend_request_received':
      case 'friend_request_accepted':
      case 'friend_request_rejected':
        return Colors.blue;
      case 'call_incoming':
      case 'call_missed':
        return Colors.green;
      case 'group_call_invite':
      case 'group_call_starting':
        return Colors.purple;
      case 'collaboration_invite':
      case 'collab_new_message':
      case 'mention_in_collab':
      case 'card_updated_by_collaborator':
        return Colors.orange;
      case 'smart_reminder':
      case 'encouragement':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getDefaultTitle(String type) {
    switch (type) {
      case 'friend_request_received':
        return 'New Friend Request';
      case 'friend_request_accepted':
        return 'Friend Request Accepted';
      case 'friend_request_rejected':
        return 'Friend Request Declined';
      case 'call_incoming':
        return 'Incoming Call';
      case 'call_missed':
        return 'Missed Call';
      case 'group_call_invite':
        return 'Group Call Invitation';
      case 'group_call_starting':
        return 'Group Call Starting';
      case 'collaboration_invite':
        return 'Collaboration Invite';
      case 'collab_new_message':
        return 'New Message in Collaboration';
      case 'mention_in_collab':
        return 'You were mentioned';
      case 'card_updated_by_collaborator':
        return 'Card Updated';
      case 'smart_reminder':
        return 'Smart Reminder';
      case 'encouragement':
        return 'Encouragement';
      default:
        return 'Notification';
    }
  }

  void _handleToastTap(NotificationModel notification) {
    // Mark as clicked
    context.read<NotificationBloc>().add(MarkAsClicked(notifId: notification.notifId));
  }
}

// Wrapper widget to use in MaterialApp
class NotificationToastWrapper extends StatelessWidget {
  final Widget child;
  final Duration toastDuration;

  const NotificationToastWrapper({
    super.key,
    required this.child,
    this.toastDuration = const Duration(seconds: 4),
  });

  @override
  Widget build(BuildContext context) {
    return NotificationToast(
      duration: toastDuration,
      child: child,
    );
  }
}