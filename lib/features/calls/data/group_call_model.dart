import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

class GroupCallModel extends Equatable {
  final String groupCallId;
  final String hostId;
  final String title;
  final String type;
  final String status;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int maxParticipants;
  final bool isRecording;
  final Map<String, dynamic> settings;
  final DateTime createdAt;
  final UserModel? host;
  final List<GroupCallParticipantModel> participants;

  const GroupCallModel({
    required this.groupCallId,
    required this.hostId,
    required this.title,
    required this.type,
    required this.status,
    this.scheduledAt,
    this.startedAt,
    this.endedAt,
    required this.maxParticipants,
    required this.isRecording,
    required this.settings,
    required this.createdAt,
    this.host,
    this.participants = const [],
  });

  factory GroupCallModel.fromJson(Map<String, dynamic> json) {
    return GroupCallModel(
      groupCallId: json['groupCallId'] ?? json['id'] ?? '',
      hostId: json['hostId'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'audio', // Voice-only app
      status: json['status'] ?? 'scheduled',
      scheduledAt: json['scheduledAt'] != null ? DateTime.parse(json['scheduledAt']) : null,
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      maxParticipants: json['maxParticipants'] ?? 10,
      isRecording: json['isRecording'] ?? false,
      settings: json['settings'] ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      host: json['host'] != null ? UserModel.fromJson(json['host']) : null,
      participants: (json['participants'] as List? ?? [])
          .map((e) => GroupCallParticipantModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupCallId': groupCallId,
      'hostId': hostId,
      'title': title,
      'type': type,
      'status': status,
      'scheduledAt': scheduledAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'maxParticipants': maxParticipants,
      'isRecording': isRecording,
      'settings': settings,
      'createdAt': createdAt.toIso8601String(),
      'host': host?.toJson(),
      'participants': participants.map((e) => e.toJson()).toList(),
    };
  }

  bool get isHost => false; // Set by BLOC
  bool get isActive => status == 'active' || status == 'live';
  bool get isScheduled => status == 'scheduled';
  bool get isEnded => status == 'ended';
  // isVideo removed - voice-only app

  GroupCallParticipantModel? getCurrentUserParticipant(String userId) {
    try {
      return participants.firstWhere((p) => p.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    groupCallId,
    hostId,
    title,
    type,
    status,
    scheduledAt,
    startedAt,
    endedAt,
    maxParticipants,
    isRecording,
    settings,
    createdAt,
    host,
    participants,
  ];
}

class GroupCallParticipantModel extends Equatable {
  final String participantId;
  final String groupCallId;
  final String userId;
  final String role;
  final bool isMuted;
  final bool isScreenSharing;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final UserModel? user;

  const GroupCallParticipantModel({
    required this.participantId,
    required this.groupCallId,
    required this.userId,
    required this.role,
    required this.isMuted,
    required this.isScreenSharing,
    required this.joinedAt,
    this.leftAt,
    this.user,
  });

  factory GroupCallParticipantModel.fromJson(Map<String, dynamic> json) {
    return GroupCallParticipantModel(
      participantId: json['participantId'] ?? json['id'] ?? '',
      groupCallId: json['groupCallId'] ?? '',
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'participant',
      isMuted: json['isMuted'] ?? false,
      isScreenSharing: json['isScreenSharing'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'groupCallId': groupCallId,
      'userId': userId,
      'role': role,
      'isMuted': isMuted,
      'isScreenSharing': isScreenSharing,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }

  bool get isHost => role == 'host';
  bool get isModerator => role == 'moderator';
  bool get isActive => leftAt == null;

  @override
  List<Object?> get props => [
    participantId,
    groupCallId,
    userId,
    role,
    isMuted,
    isScreenSharing,
    joinedAt,
    leftAt,
    user,
  ];
}

class GroupCallHistoryResponse extends Equatable {
  final List<GroupCallModel> groupCalls;
  final int total;

  const GroupCallHistoryResponse({required this.groupCalls, required this.total});

  factory GroupCallHistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['groupCalls'] ?? json['group_calls'] ?? json['data'] ?? [];
    return GroupCallHistoryResponse(
      groupCalls: (list as List).map((e) => GroupCallModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [groupCalls, total];
}

class GroupCallParticipantsResponse extends Equatable {
  final List<GroupCallParticipantModel> participants;
  final int total;

  const GroupCallParticipantsResponse({required this.participants, required this.total});

  factory GroupCallParticipantsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['participants'] ?? json['data'] ?? [];
    return GroupCallParticipantsResponse(
      participants: (list as List).map((e) => GroupCallParticipantModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [participants, total];
}