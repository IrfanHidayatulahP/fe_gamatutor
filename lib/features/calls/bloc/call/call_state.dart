import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

class CallIdle extends CallState {
  const CallIdle();
}

class CallIncomingState extends CallState {
  final String callId;
  final String callerId;
  final String callerName;
  // isVideo removed - voice-only app

  const CallIncomingState({
    required this.callId,
    required this.callerId,
    required this.callerName,
  });

  @override
  List<Object?> get props => [callId, callerId, callerName];
}

class CallOutgoing extends CallState {
  final String callId;
  final String calleeId;
  // isVideo removed - voice-only app

  const CallOutgoing({
    required this.callId,
    required this.calleeId,
  });

  @override
  List<Object?> get props => [callId, calleeId];
}

/// Ringing state for both caller (waiting) and callee (incoming)
class CallRingingState extends CallState {
  final String callId;
  final String calleeId;      // For caller (outgoing)
  final String callerId;      // For callee (incoming)
  final String targetName;    // Name of the other party
  // isVideo removed - voice-only app
  final bool isOutgoing;      // true = caller waiting, false = callee incoming

  const CallRingingState({
    required this.callId,
    this.calleeId = '',
    this.callerId = '',
    required this.targetName,
    required this.isOutgoing,
  });

  @override
  List<Object?> get props => [callId, calleeId, callerId, targetName, isOutgoing];
}

class CallConnecting extends CallState {
  final String callId;
  final bool isInitiator;

  const CallConnecting({
    required this.callId,
    required this.isInitiator,
  });

  @override
  List<Object?> get props => [callId, isInitiator];
}

class CallConnected extends CallState {
  final String callId;
  final MediaStream localStream;
  final MediaStream remoteStream;
  final bool isMuted;
  // isVideoEnabled removed - voice-only app
  final int duration;
  final bool isInitiator;

  const CallConnected({
    required this.callId,
    required this.localStream,
    required this.remoteStream,
    required this.isMuted,
    required this.duration,
    required this.isInitiator,
  });

  @override
  List<Object?> get props => [callId, localStream, remoteStream, isMuted, duration, isInitiator];
}

class CallEndedState extends CallState {
  final String callId;
  final String reason; // ended, rejected, failed, timeout

  const CallEndedState({
    required this.callId,
    required this.reason,
  });

  @override
  List<Object?> get props => [callId, reason];
}

class CallError extends CallState {
  final String message;

  const CallError({required this.message});

  @override
  List<Object?> get props => [message];
}