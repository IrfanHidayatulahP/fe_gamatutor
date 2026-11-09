import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../data/group_call_model.dart';

abstract class GroupCallEvent extends Equatable {
  const GroupCallEvent();

  @override
  List<Object?> get props => [];
}

class CreateGroupCall extends GroupCallEvent {
  final String title;
  // type removed - voice-only app, always 'audio'
  final DateTime? scheduledAt;
  final int maxParticipants;
  final bool isRecording;
  final Map<String, dynamic>? settings;

  const CreateGroupCall({
    required this.title,
    this.scheduledAt,
    this.maxParticipants = 10,
    this.isRecording = false,
    this.settings,
  });

  @override
  List<Object?> get props => [title, scheduledAt, maxParticipants, isRecording, settings];
}

class JoinGroupCall extends GroupCallEvent {
  final String groupCallId;
  // isVideo removed - voice-only app

  const JoinGroupCall({required this.groupCallId});

  @override
  List<Object?> get props => [groupCallId];
}

class LeaveGroupCall extends GroupCallEvent {
  final String groupCallId;

  const LeaveGroupCall({required this.groupCallId});

  @override
  List<Object?> get props => [groupCallId];
}

class EndGroupCall extends GroupCallEvent {
  final String groupCallId;

  const EndGroupCall({required this.groupCallId});

  @override
  List<Object?> get props => [groupCallId];
}

class UpdateGroupCallSettings extends GroupCallEvent {
  final String groupCallId;
  final String? title;
  final bool? isRecording;
  final Map<String, dynamic>? settings;

  const UpdateGroupCallSettings({
    required this.groupCallId,
    this.title,
    this.isRecording,
    this.settings,
  });

  @override
  List<Object?> get props => [groupCallId, title, isRecording, settings];
}

class UpdateParticipant extends GroupCallEvent {
  final String groupCallId;
  final String participantId;
  final String? role;
  final bool? isMuted;
  // isVideoEnabled removed - voice-only app
  final bool? isScreenSharing;

  const UpdateParticipant({
    required this.groupCallId,
    required this.participantId,
    this.role,
    this.isMuted,
    this.isScreenSharing,
  });

  @override
  List<Object?> get props => [groupCallId, participantId, role, isMuted, isScreenSharing];
}

class LoadGroupCallHistory extends GroupCallEvent {
  final String? status;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int limit;
  final int offset;

  const LoadGroupCallHistory({
    this.status,
    this.fromDate,
    this.toDate,
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [status, fromDate, toDate, limit, offset];
}

class LoadParticipants extends GroupCallEvent {
  final String groupCallId;

  const LoadParticipants({required this.groupCallId});

  @override
  List<Object?> get props => [groupCallId];
}

class HandleGroupCallInvite extends GroupCallEvent {
  final GroupCallModel groupCall;

  const HandleGroupCallInvite({required this.groupCall});

  @override
  List<Object?> get props => [groupCall];
}

class GroupCallRealtimeEvent extends GroupCallEvent {
  final Map<String, dynamic> data;

  const GroupCallRealtimeEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

class ToggleMuteGroupCall extends GroupCallEvent {
  const ToggleMuteGroupCall();

  @override
  List<Object?> get props => [];
}

// ToggleVideoGroupCall removed - voice-only app
// SwitchCameraGroupCall removed - voice-only app

class GroupCallErrorOccurred extends GroupCallEvent {
  final String message;

  const GroupCallErrorOccurred({required this.message});

  @override
  List<Object?> get props => [message];
}

class GroupCallCleanup extends GroupCallEvent {}