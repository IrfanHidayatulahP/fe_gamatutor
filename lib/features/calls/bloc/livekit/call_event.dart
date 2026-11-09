import 'package:equatable/equatable.dart';

abstract class CallEvent extends Equatable {
  const CallEvent();

  @override
  List<Object?> get props => [];
}

/// Initiate a 1-on-1 audio call
class Initiate1on1CallEvent extends CallEvent {
  final String calleeId;

  const Initiate1on1CallEvent(this.calleeId);

  @override
  List<Object?> get props => [calleeId];
}

/// Incoming call received (from FCM push)
class IncomingCallReceivedEvent extends CallEvent {
  final String callId;
  final String callerName;
  final String? callerAvatar;
  final String token;
  final String roomName;
  final String livekitUrl;

  const IncomingCallReceivedEvent({
    required this.callId,
    required this.callerName,
    this.callerAvatar,
    required this.token,
    required this.roomName,
    required this.livekitUrl,
  });

  @override
  List<Object?> get props => [
        callId,
        callerName,
        callerAvatar,
        token,
        roomName,
        livekitUrl,
      ];
}

/// Accept an incoming call
class AcceptCallEvent extends CallEvent {
  final String callId;

  const AcceptCallEvent(this.callId);

  @override
  List<Object?> get props => [callId];
}

/// Reject an incoming call
class RejectCallEvent extends CallEvent {
  final String callId;

  const RejectCallEvent(this.callId);

  @override
  List<Object?> get props => [callId];
}

/// Join a group voice collaboration
class JoinGroupVoiceEvent extends CallEvent {
  final String taskId;

  const JoinGroupVoiceEvent(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

/// Leave current call (1-on-1 or group)
class LeaveCallEvent extends CallEvent {
  const LeaveCallEvent();
}

/// Toggle microphone on/off
class ToggleMicrophoneEvent extends CallEvent {
  final bool enabled;

  const ToggleMicrophoneEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Internal event: active speakers changed from LiveKit
class OnActiveSpeakersChangedEvent extends CallEvent {
  final List<String> activeSpeakerIds;

  const OnActiveSpeakersChangedEvent(this.activeSpeakerIds);

  @override
  List<Object?> get props => [activeSpeakerIds];
}

/// Internal event: participant connected
class OnParticipantConnectedEvent extends CallEvent {
  final String participantId;
  final String userName;
  final String? userAvatar;

  const OnParticipantConnectedEvent({
    required this.participantId,
    required this.userName,
    this.userAvatar,
  });

  @override
  List<Object?> get props => [participantId, userName, userAvatar];
}

/// Internal event: participant disconnected
class OnParticipantDisconnectedEvent extends CallEvent {
  final String participantId;

  const OnParticipantDisconnectedEvent(this.participantId);

  @override
  List<Object?> get props => [participantId];
}

/// Internal event: connection error
class OnConnectionErrorEvent extends CallEvent {
  final String error;

  const OnConnectionErrorEvent(this.error);

  @override
  List<Object?> get props => [error];
}

/// Internal event: connected to room
class OnConnectedEvent extends CallEvent {
  const OnConnectedEvent();
}

/// Internal event: disconnected from room
class OnDisconnectedEvent extends CallEvent {
  const OnDisconnectedEvent();
}

/// Callee accepted the call - caller should now connect to LiveKit
class CalleeAcceptedEvent extends CallEvent {
  final String callId;
  final String token;
  final String roomName;
  final String livekitUrl;

  const CalleeAcceptedEvent({
    required this.callId,
    required this.token,
    required this.roomName,
    required this.livekitUrl,
  });

  @override
  List<Object?> get props => [callId, token, roomName, livekitUrl];
}

/// End a group call (host only)
class EndGroupCallEvent extends CallEvent {
  final String groupCallId;

  const EndGroupCallEvent(this.groupCallId);

  @override
  List<Object?> get props => [groupCallId];
}