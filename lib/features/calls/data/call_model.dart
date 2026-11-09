import 'package:equatable/equatable.dart';

import '../../../../core/models/user_model.dart';

class CallModel extends Equatable {
  final String callId;
  final String callerId;
  final String calleeId;
  final String type;
  final String status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int duration;
  final Map<String, dynamic> signalingData;
  final DateTime createdAt;
  final UserModel? caller;
  final UserModel? callee;

  const CallModel({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.type,
    required this.status,
    this.startedAt,
    this.endedAt,
    required this.duration,
    required this.signalingData,
    required this.createdAt,
    this.caller,
    this.callee,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      callId: json['callId'] ?? json['id'] ?? '',
      callerId: json['callerId'] ?? '',
      calleeId: json['calleeId'] ?? '',
      type: json['type'] ?? 'audio',
      status: json['status'] ?? 'pending',
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      endedAt: json['endedAt'] != null ? DateTime.parse(json['endedAt']) : null,
      duration: json['duration'] ?? 0,
      signalingData: json['signalingData'] ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      caller: json['caller'] != null ? UserModel.fromJson(json['caller']) : null,
      callee: json['callee'] != null ? UserModel.fromJson(json['callee']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'callId': callId,
      'callerId': callerId,
      'calleeId': calleeId,
      'type': type,
      'status': status,
      'startedAt': startedAt?.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'duration': duration,
      'signalingData': signalingData,
      'createdAt': createdAt.toIso8601String(),
      'caller': caller?.toJson(),
      'callee': callee?.toJson(),
    };
  }

  bool get isIncoming => false; // Set by BLOC based on current user
  bool get isOutgoing => false; // Set by BLOC based on current user
  bool get isActive => status == 'answered' || status == 'ringing' || status == 'connecting';
  bool get isEnded => status == 'ended' || status == 'rejected' || status == 'cancelled' || status == 'missed';

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [callId, callerId, calleeId, type, status, startedAt, endedAt, duration, signalingData, createdAt, caller, callee];
}

class CallHistoryResponse extends Equatable {
  final List<CallModel> calls;
  final int total;

  const CallHistoryResponse({required this.calls, required this.total});

  factory CallHistoryResponse.fromJson(Map<String, dynamic> json) {
    final list = json['calls'] ?? json['data'] ?? [];
    return CallHistoryResponse(
      calls: (list as List).map((e) => CallModel.fromJson(e)).toList(),
      total: json['total'] ?? list.length,
    );
  }

  @override
  List<Object?> get props => [calls, total];
}