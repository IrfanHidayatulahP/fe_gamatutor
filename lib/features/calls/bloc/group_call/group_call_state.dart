import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../data/group_call_model.dart';

abstract class GroupCallState extends Equatable {
  const GroupCallState();

  @override
  List<Object?> get props => [];
}

class GroupCallInitial extends GroupCallState {}

class GroupCallLoading extends GroupCallState {}

class GroupCallCreating extends GroupCallState {}

class GroupCallScheduled extends GroupCallState {
  final GroupCallModel groupCall;

  const GroupCallScheduled({required this.groupCall});

  @override
  List<Object?> get props => [groupCall];
}

class GroupCallJoining extends GroupCallState {
  final String groupCallId;

  const GroupCallJoining({required this.groupCallId});

  @override
  List<Object?> get props => [groupCallId];
}

class GroupCallActive extends GroupCallState {
  final GroupCallModel groupCall;
  final MediaStream localStream;
  final Map<String, MediaStream> remoteStreams;
  final bool isMuted;
  // isVideoEnabled removed - voice-only app
  final int duration;
  final bool isHost;

  const GroupCallActive({
    required this.groupCall,
    required this.localStream,
    required this.remoteStreams,
    required this.isMuted,
    required this.duration,
    required this.isHost,
  });

  @override
  List<Object?> get props => [groupCall, localStream, remoteStreams, isMuted, duration, isHost];
}

class GroupCallEnded extends GroupCallState {
  final GroupCallModel groupCall;
  final String reason;

  const GroupCallEnded({required this.groupCall, required this.reason});

  @override
  List<Object?> get props => [groupCall, reason];
}

class ParticipantsLoaded extends GroupCallState {
  final List<GroupCallParticipantModel> participants;
  final int total;

  const ParticipantsLoaded({required this.participants, required this.total});

  @override
  List<Object?> get props => [participants, total];
}

class GroupCallHistoryLoaded extends GroupCallState {
  final List<GroupCallModel> groupCalls;
  final int total;
  final bool hasMore;

  const GroupCallHistoryLoaded({
    required this.groupCalls,
    required this.total,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [groupCalls, total, hasMore];
}

class GroupCallError extends GroupCallState {
  final String message;

  const GroupCallError({required this.message});

  @override
  List<Object?> get props => [message];
}