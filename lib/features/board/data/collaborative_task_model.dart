import 'package:equatable/equatable.dart';

class CollaborativeTaskModel extends Equatable {
  final String cardId;
  final String title;
  final String? courseName;
  final String difficulty;
  final String priority;
  final String? deadline;
  final bool isOwner;
  final String role; // 'owner', 'editor', 'viewer'
  final CollaborativeGroupCallModel? activeGroupCall;

  const CollaborativeTaskModel({
    required this.cardId,
    required this.title,
    this.courseName,
    required this.difficulty,
    required this.priority,
    this.deadline,
    required this.isOwner,
    required this.role,
    this.activeGroupCall,
  });

  factory CollaborativeTaskModel.fromJson(Map<String, dynamic> json) {
    return CollaborativeTaskModel(
      cardId: json['cardId'] ?? '',
      title: json['title'] ?? '',
      courseName: json['courseName'],
      difficulty: json['difficulty'] ?? 'medium',
      priority: json['priority'] ?? 'medium',
      deadline: json['deadline'],
      isOwner: json['isOwner'] ?? false,
      role: json['role'] ?? 'viewer',
      activeGroupCall: json['activeGroupCall'] != null
          ? CollaborativeGroupCallModel.fromJson(json['activeGroupCall'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'title': title,
      'courseName': courseName,
      'difficulty': difficulty,
      'priority': priority,
      'deadline': deadline,
      'isOwner': isOwner,
      'role': role,
      'activeGroupCall': activeGroupCall?.toJson(),
    };
  }

  String get difficultyLabel {
    switch (difficulty) {
      case 'easy':
        return 'Mudah';
      case 'medium':
        return 'Sedang';
      case 'hard':
        return 'Sulit';
      case 'expert':
        return 'Ahli';
      default:
        return difficulty;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      case 'critical':
        return 'Kritis';
      default:
        return priority;
    }
  }

  @override
  List<Object?> get props => [
        cardId,
        title,
        courseName,
        difficulty,
        priority,
        deadline,
        isOwner,
        role,
        activeGroupCall,
      ];
}

class CollaborativeGroupCallModel extends Equatable {
  final String groupCallId;
  final String status; // 'waiting', 'active', 'ended'
  final String hostId;
  final int participantCount;

  const CollaborativeGroupCallModel({
    required this.groupCallId,
    required this.status,
    required this.hostId,
    required this.participantCount,
  });

  factory CollaborativeGroupCallModel.fromJson(Map<String, dynamic> json) {
    return CollaborativeGroupCallModel(
      groupCallId: json['groupCallId'] ?? '',
      status: json['status'] ?? 'waiting',
      hostId: json['hostId'] ?? '',
      participantCount: json['participantCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupCallId': groupCallId,
      'status': status,
      'hostId': hostId,
      'participantCount': participantCount,
    };
  }

  @override
  List<Object?> get props => [
        groupCallId,
        status,
        hostId,
        participantCount,
      ];

  bool get isActive => status == 'active';
  bool get isWaiting => status == 'waiting';
  String get statusLabel {
    switch (status) {
      case 'waiting':
        return 'Waiting';
      case 'active':
        return 'Active';
      case 'ended':
        return 'Ended';
      default:
        return status;
    }
  }
}