import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

class NotificationModel extends Equatable {
  final String notifId;
  final String userId;
  final String type;
  final String? title;
  final String message;
  final bool read;
  final bool delivered;
  final DateTime? scheduledFor;
  final String? reminderReason;
  final String? triggerAction;
  final String? triggerUserId;
  final String? referenceId;
  final DateTime createdAt;
  final UserModel? triggerUser;

  const NotificationModel({
    required this.notifId,
    required this.userId,
    required this.type,
    this.title,
    required this.message,
    required this.read,
    required this.delivered,
    this.scheduledFor,
    this.reminderReason,
    this.triggerAction,
    this.triggerUserId,
    this.referenceId,
    required this.createdAt,
    this.triggerUser,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notifId: json['notifId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'],
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      delivered: json['delivered'] ?? false,
      scheduledFor: json['scheduledFor'] != null ? DateTime.parse(json['scheduledFor']) : null,
      reminderReason: json['reminderReason'],
      triggerAction: json['triggerAction'],
      triggerUserId: json['triggerUserId'],
      referenceId: json['referenceId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      triggerUser: json['triggerUser'] != null ? UserModel.fromJson(json['triggerUser']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notifId': notifId,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'read': read,
      'delivered': delivered,
      'scheduledFor': scheduledFor?.toIso8601String(),
      'reminderReason': reminderReason,
      'triggerAction': triggerAction,
      'triggerUserId': triggerUserId,
      'createdAt': createdAt.toIso8601String(),
      'triggerUser': triggerUser?.toJson(),
    };
  }

  NotificationModel copyWith({
    String? notifId,
    String? userId,
    String? type,
    String? title,
    String? message,
    bool? read,
    bool? delivered,
    DateTime? scheduledFor,
    String? reminderReason,
    String? triggerAction,
    String? triggerUserId,
    DateTime? createdAt,
    UserModel? triggerUser,
  }) {
    return NotificationModel(
      notifId: notifId ?? this.notifId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      read: read ?? this.read,
      delivered: delivered ?? this.delivered,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      reminderReason: reminderReason ?? this.reminderReason,
      triggerAction: triggerAction ?? this.triggerAction,
      triggerUserId: triggerUserId ?? this.triggerUserId,
      createdAt: createdAt ?? this.createdAt,
      triggerUser: triggerUser ?? this.triggerUser,
    );
  }

  @override
  List<Object?> get props => [
    notifId,
    userId,
    type,
    title,
    message,
    read,
    delivered,
    scheduledFor,
    reminderReason,
    triggerAction,
    triggerUserId,
    createdAt,
    triggerUser,
  ];
}

class NotificationListResponse extends Equatable {
  final List<NotificationModel> notifications;
  final int total;

  const NotificationListResponse({required this.notifications, required this.total});

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['notifications'] ?? json['data'] ?? [];
    return NotificationListResponse(
      notifications: (list as List).map((e) => NotificationModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [notifications, total];
}