import 'package:equatable/equatable.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

class CallInitiated extends CallEvent {
  final String? callId;
  final String calleeId;

  const CallInitiated({
    this.callId,
    required this.calleeId,
  });

  @override
  List<Object?> get props => [callId, calleeId];
}

class CallAnswered extends CallEvent {
  final String callId;

  const CallAnswered({required this.callId});

  @override
  List<Object?> get props => [callId];
}

class CallRejected extends CallEvent {
  final String callId;

  const CallRejected({required this.callId});

  @override
  List<Object?> get props => [callId];
}

class CallEnded extends CallEvent {
  final String callId;

  const CallEnded({required this.callId});

  @override
  List<Object?> get props => [callId];
}

class CallSignalingReceived extends CallEvent {
  final String type; // offer, answer, ice-candidate
  final Map<String, dynamic> data;

  const CallSignalingReceived({
    required this.type,
    required this.data,
  });

  @override
  List<Object?> get props => [type, data];
}

class CallIncoming extends CallEvent {
  final String callId;
  final String callerId;
  final String callerName;
  // isVideo removed - voice-only app

  const CallIncoming({
    required this.callId,
    required this.callerId,
    required this.callerName,
  });

  @override
  List<Object?> get props => [callId, callerId, callerName];
}

class CallRinging extends CallEvent {
  final String callId;
  final String callerId;
  // isVideo removed - voice-only app

  const CallRinging({
    required this.callId,
    required this.callerId,
  });

  @override
  List<Object?> get props => [callId, callerId];
}

class CallToggledMute extends CallEvent {}

class CallErrorOccurred extends CallEvent {
  final String message;

  const CallErrorOccurred({required this.message});

  @override
  List<Object?> get props => [message];
}

class CallCleanup extends CallEvent {}

/// Callee accepted the call - caller should now complete WebRTC connection
class CalleeAcceptedEvent extends CallEvent {
  final String callId;
  final Map<String, dynamic> signalingData; // SDP answer from callee

  const CalleeAcceptedEvent({
    required this.callId,
    required this.signalingData,
  });

  @override
  List<Object?> get props => [callId, signalingData];
}