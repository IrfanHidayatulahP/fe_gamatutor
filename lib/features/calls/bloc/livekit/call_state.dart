import 'package:equatable/equatable.dart';

abstract class CallState extends Equatable {
  const CallState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no active call
class CallIdleState extends CallState {
  const CallIdleState();
}

/// Incoming call ringing (callee) or outgoing call waiting (caller)
class CallRingingState extends CallState {
  final String callId;
  final String callerName;
  final String? callerAvatar;
  final String token;
  final String roomName;
  final String livekitUrl;
  final bool isOutgoing;      // true = caller waiting for callee, false = callee incoming
  final String targetName;    // Name of the other party

  const CallRingingState({
    required this.callId,
    required this.callerName,
    this.callerAvatar,
    required this.token,
    required this.roomName,
    required this.livekitUrl,
    required this.isOutgoing,
    required this.targetName,
  });

  @override
  List<Object?> get props => [
        callId,
        callerName,
        callerAvatar,
        token,
        roomName,
        livekitUrl,
        isOutgoing,
        targetName,
      ];
}

/// Connecting to LiveKit room
class CallConnectingState extends CallState {
  final String callId;
  final String roomName;
  final String? token;
  final String? livekitUrl;

  const CallConnectingState({
    required this.callId,
    required this.roomName,
    this.token,
    this.livekitUrl,
  });

  @override
  List<Object?> get props => [callId, roomName, token, livekitUrl];
}

/// Active call - connected to room
class CallActiveState extends CallState {
  final String callId;
  final String roomName;
  final String? token;
  final String? livekitUrl;
  final String? activeSpeakerId;
  final bool isMuted;
  final List<CallParticipant> participants;
  final bool isGroupCall;
  final String? taskId; // For group calls
  final bool isHost; // For group calls - whether current user is host

  const CallActiveState({
    required this.callId,
    required this.roomName,
    this.token,
    this.livekitUrl,
    this.activeSpeakerId,
    required this.isMuted,
    required this.participants,
    this.isGroupCall = false,
    this.taskId,
    this.isHost = false,
  });

  @override
  List<Object?> get props => [
        callId,
        roomName,
        token,
        livekitUrl,
        activeSpeakerId,
        isMuted,
        participants,
        isGroupCall,
        taskId,
        isHost,
      ];

  CallActiveState copyWith({
    String? callId,
    String? roomName,
    String? token,
    String? livekitUrl,
    String? activeSpeakerId,
    bool? isMuted,
    List<CallParticipant>? participants,
    bool? isGroupCall,
    String? taskId,
    bool? isHost,
  }) {
    return CallActiveState(
      callId: callId ?? this.callId,
      roomName: roomName ?? this.roomName,
      token: token ?? this.token,
      livekitUrl: livekitUrl ?? this.livekitUrl,
      activeSpeakerId: activeSpeakerId ?? this.activeSpeakerId,
      isMuted: isMuted ?? this.isMuted,
      participants: participants ?? this.participants,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      taskId: taskId ?? this.taskId,
      isHost: isHost ?? this.isHost,
    );
  }
}

/// Call ended
class CallEndedState extends CallState {
  final String callId;
  final int? durationSeconds;

  const CallEndedState({
    required this.callId,
    this.durationSeconds,
  });

  @override
  List<Object?> get props => [callId, durationSeconds];
}

/// Error state
class CallErrorState extends CallState {
  final String message;

  const CallErrorState(this.message);

  @override
  List<Object?> get props => [message];
}

/// Participant model for call state
class CallParticipant extends Equatable {
  final String participantId;
  final String userName;
  final String? userAvatar;
  final bool isMuted;
  final bool isSpeaking;
  final bool isLocal;

  const CallParticipant({
    required this.participantId,
    required this.userName,
    this.userAvatar,
    required this.isMuted,
    required this.isSpeaking,
    required this.isLocal,
  });

  @override
  List<Object?> get props => [
        participantId,
        userName,
        userAvatar,
        isMuted,
        isSpeaking,
        isLocal,
      ];

  CallParticipant copyWith({
    String? participantId,
    String? userName,
    String? userAvatar,
    bool? isMuted,
    bool? isSpeaking,
    bool? isLocal,
  }) {
    return CallParticipant(
      participantId: participantId ?? this.participantId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isLocal: isLocal ?? this.isLocal,
    );
  }
}