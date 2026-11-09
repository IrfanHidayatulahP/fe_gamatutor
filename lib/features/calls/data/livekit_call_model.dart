class CallModel {
  final String callId;
  final String callerId;
  final String calleeId;
  final String callerName;
  final String? callerAvatar;
  final String type; // 'audio'
  final String status; // 'ringing', 'active', 'ended', 'missed', 'rejected'
  final String roomName;
  final String token;
  final String livekitUrl;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int? durationSeconds;

  CallModel({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.callerName,
    this.callerAvatar,
    required this.type,
    required this.status,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['callId'] ?? json['id'] ?? '',
      callerId: json['callerId'] ?? '',
      calleeId: json['calleeId'] ?? '',
      callerName: json['callerName'] ?? json['caller']?['name'] ?? '',
      callerAvatar: json['callerAvatar'] ?? json['caller']?['avatar'],
      type: json['type'] ?? 'audio',
      status: json['status'] ?? 'ringing',
      roomName: json['roomName'] ?? '',
      token: json['token'] ?? '',
      livekitUrl: json['livekitUrl'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      answeredAt: json['answeredAt'] != null
          ? DateTime.tryParse(json['answeredAt'])
          : null,
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'])
          : null,
      durationSeconds: json['durationSeconds'] ?? json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'callerName': callerName,
      'callerAvatar': callerAvatar,
      'type': type,
      'status': status,
      'roomName': roomName,
      'token': token,
      'livekitUrl': livekitUrl,
      'createdAt': createdAt.toIso8601String(),
      'answeredAt': answeredAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationSeconds': durationSeconds,
    };
  }

  CallModel copyWith({
    String? callId,
    String? callerId,
    String? calleeId,
    String? callerName,
    String? callerAvatar,
    String? type,
    String? status,
    String? roomName,
    String? token,
    String? livekitUrl,
    DateTime? createdAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) {
    return CallModel(
      callId: callId ?? this.callId,
      callerId: callerId ?? this.callerId,
      calleeId: calleeId ?? this.calleeId,
      callerName: callerName ?? this.callerName,
      callerAvatar: callerAvatar ?? this.callerAvatar,
      type: type ?? this.type,
      status: status ?? this.status,
      roomName: roomName ?? this.roomName,
      token: token ?? this.token,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}