class GroupCallParticipant {
  final String participantId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String connectionStatus; // 'connected', 'disconnected', 'connecting'
  final DateTime joinedAt;
  final DateTime? leftAt;
  final bool isMuted;
  final bool isSpeaking;

  GroupCallParticipant({
    required this.participantId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.connectionStatus,
    required this.joinedAt,
    this.leftAt,
    required this.isMuted,
    required this.isSpeaking,
  });

  factory GroupCallParticipant.fromJson(Map<String, dynamic> json) {
    return GroupCallParticipant(
      participantId: json['participantId'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? json['user']?['name'] ?? '',
      userAvatar: json['userAvatar'] ?? json['user']?['avatar'],
      connectionStatus: json['connectionStatus'] ?? 'connected',
      joinedAt: DateTime.tryParse(json['joinedAt'] ?? '') ?? DateTime.now(),
      leftAt: json['leftAt'] != null
          ? DateTime.tryParse(json['leftAt'])
          : null,
      isMuted: json['isMuted'] ?? false,
      isSpeaking: json['isSpeaking'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participantId': participantId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'connectionStatus': connectionStatus,
      'joinedAt': joinedAt.toIso8601String(),
      'leftAt': leftAt?.toIso8601String(),
      'isMuted': isMuted,
      'isSpeaking': isSpeaking,
    };
  }

  GroupCallParticipant copyWith({
    String? participantId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? connectionStatus,
    DateTime? joinedAt,
    DateTime? leftAt,
    bool? isMuted,
    bool? isSpeaking,
  }) {
    return GroupCallParticipant(
      participantId: participantId ?? this.participantId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

class GroupCallModel {
  final String groupCallId;
  final String taskId;
  final String roomName;
  final String token;
  final String livekitUrl;
  final String status; // 'active', 'ended'
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final List<GroupCallParticipant> participants;
  final int maxParticipants;
  final String? hostId;

  GroupCallModel({
    required this.groupCallId,
    required this.taskId,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.participants,
    this.maxParticipants = 50,
    this.hostId,
  });

  factory GroupCallModel.fromJson(Map<String, dynamic> json) {
    final participantsJson = json['participants'] as List<dynamic>? ?? [];
    // Backend returns nested groupCall object with hostId
    final groupCallJson = json['groupCall'] as Map<String, dynamic>?;
    return GroupCallModel(
      groupCallId: json['groupCallId'] ?? json['id'] ?? groupCallJson?['groupCallId'] ?? '',
      taskId: json['taskId'] ?? groupCallJson?['taskId'] ?? '',
      roomName: json['roomName'] ?? '',
      token: json['token'] ?? '',
      livekitUrl: json['livekitUrl'] ?? '',
      status: json['status'] ?? groupCallJson?['status'] ?? 'active',
      startedAt: DateTime.tryParse(json['startedAt'] ?? groupCallJson?['startedAt'] ?? '') ?? DateTime.now(),
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'])
          : (groupCallJson?['endedAt'] != null ? DateTime.tryParse(groupCallJson!['endedAt']) : null),
      durationSeconds: json['durationSeconds'] ?? json['duration'],
      participants: participantsJson
          .map((p) => GroupCallParticipant.fromJson(p))
          .toList(),
      maxParticipants: json['maxParticipants'] ?? groupCallJson?['maxParticipants'] ?? 50,
      hostId: groupCallJson?['hostId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupCallId': groupCallId,
      'taskId': taskId,
      'roomName': roomName,
      'token': token,
      'livekitUrl': livekitUrl,
      'status': status,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
      'participants': participants.map((p) => p.toJson()).toList(),
      'maxParticipants': maxParticipants,
    };
  }

  GroupCallModel copyWith({
    String? groupCallId,
    String? taskId,
    String? roomName,
    String? token,
    String? livekitUrl,
    String? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    List<GroupCallParticipant>? participants,
    int? maxParticipants,
    String? hostId,
  }) {
    return GroupCallModel(
      groupCallId: groupCallId ?? this.groupCallId,
      taskId: taskId ?? this.taskId,
      roomName: roomName ?? this.roomName,
      token: token ?? this.token,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      hostId: hostId ?? this.hostId,
    );
  }
}