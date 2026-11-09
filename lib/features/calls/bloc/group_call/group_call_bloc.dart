import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:equatable/equatable.dart';

import '../../repository/group_call_repository.dart';
import '../../data/group_call_webrtc_service.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../data/group_call_model.dart';
import 'group_call_event.dart';
import 'group_call_state.dart';

class GroupCallBloc extends Bloc<GroupCallEvent, GroupCallState> {
  final GroupCallRepository _repository;
  final GroupCallWebRTCService _webRTCService;
  final WebSocketManager _wsManager;

  String? _currentUserId;
  Timer? _durationTimer;
  int _duration = 0;

  GroupCallBloc({
    required GroupCallRepository repository,
    required GroupCallWebRTCService webRTCService,
    required WebSocketManager wsManager,
  })  : _repository = repository,
        _webRTCService = webRTCService,
        _wsManager = wsManager,
        super(GroupCallInitial()) {
    on<CreateGroupCall>(_onCreateGroupCall);
    on<JoinGroupCall>(_onJoinGroupCall);
    on<LeaveGroupCall>(_onLeaveGroupCall);
    on<EndGroupCall>(_onEndGroupCall);
    on<UpdateGroupCallSettings>(_onUpdateSettings);
    on<UpdateParticipant>(_onUpdateParticipant);
    on<LoadGroupCallHistory>(_onLoadHistory);
    on<LoadParticipants>(_onLoadParticipants);
    on<HandleGroupCallInvite>(_onHandleInvite);
    on<GroupCallRealtimeEvent>(_onRealtimeEvent);
    on<ToggleMuteGroupCall>(_onToggleMute);
    on<GroupCallErrorOccurred>(_onErrorOccurred);
    on<GroupCallCleanup>(_onCleanup);

    _setupWebRTCCallbacks();
  }

  void _setupWebRTCCallbacks() {
    _webRTCService.onLocalStream = (stream) {
      if (state is GroupCallJoining || state is GroupCallActive) {
        _emitActiveState(stream: stream);
      }
    };

    _webRTCService.onRemoteStreamAdded = (userId, stream) {
      if (state is GroupCallActive) {
        _emitActiveState();
      }
    };

    _webRTCService.onRemoteStreamRemoved = (userId) {
      if (state is GroupCallActive) {
        _emitActiveState();
      }
    };

    _webRTCService.onParticipantJoined = (userId) {
      if (state is GroupCallActive) {
        _emitActiveState();
      }
    };

    _webRTCService.onParticipantLeft = (userId) {
      if (state is GroupCallActive) {
        _emitActiveState();
      }
    };

    _webRTCService.onCallEnded = (groupCallId) {
      add(EndGroupCall(groupCallId: groupCallId));
    };

    _webRTCService.onError = (message) {
      add(GroupCallErrorOccurred(message: message));
    };
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  Future<void> _onCreateGroupCall(
    CreateGroupCall event,
    Emitter<GroupCallState> emit,
  ) async {
    emit( GroupCallCreating());
    try {
      final groupCall = await _repository.createGroupCall(
        title: event.title,
        type: 'audio', // Voice-only app
        scheduledAt: event.scheduledAt,
        maxParticipants: event.maxParticipants,
        isRecording: event.isRecording,
        settings: event.settings,
      );

      if (groupCall != null) {
        if (event.scheduledAt != null && event.scheduledAt!.isAfter(DateTime.now())) {
          emit(GroupCallScheduled(groupCall: groupCall));
        } else {
          emit(GroupCallLoading());
        }
      } else {
        emit(GroupCallError(message: 'Failed to create group call'));
      }
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onJoinGroupCall(
    JoinGroupCall event,
    Emitter<GroupCallState> emit,
  ) async {
    emit(GroupCallJoining(groupCallId: event.groupCallId));
    try {
      final groupCall = await _repository.joinGroupCall(event.groupCallId);
      if (groupCall == null) {
        emit(const GroupCallError(message: 'Group call not found'));
        return;
      }

      final isHost = groupCall.hostId == _currentUserId;
      final participantIds = groupCall.participants.map((p) => p.userId).toList();

      await _webRTCService.joinGroupCall(
        groupCallId: event.groupCallId,
        userId: _currentUserId!,
        participantIds: participantIds,
        isHost: isHost,
      );

      emit(GroupCallJoining(groupCallId: event.groupCallId));
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onLeaveGroupCall(
    LeaveGroupCall event,
    Emitter<GroupCallState> emit,
  ) async {
    try {
      await _repository.leaveGroupCall(event.groupCallId);
      _webRTCService.dispose();
      _stopDurationTimer();
      emit(GroupCallEnded(groupCall: GroupCallModel(
        groupCallId: event.groupCallId,
        hostId: '',
        title: '',
        type: '',
        status: 'ended',
        maxParticipants: 0,
        isRecording: false,
        settings: {},
        createdAt: DateTime.now(),
      ), reason: 'left'));
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onEndGroupCall(
    EndGroupCall event,
    Emitter<GroupCallState> emit,
  ) async {
    try {
      await _repository.endGroupCall(event.groupCallId);
      _webRTCService.dispose();
      _stopDurationTimer();
      emit(GroupCallEnded(
        groupCall: GroupCallModel(
          groupCallId: event.groupCallId,
          hostId: '',
          title: '',
          type: '',
          status: 'ended',
          maxParticipants: 0,
          isRecording: false,
          settings: {},
          createdAt: DateTime.now(),
        ),
        reason: 'ended',
      ));
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onUpdateSettings(
    UpdateGroupCallSettings event,
    Emitter<GroupCallState> emit,
  ) async {
    try {
      await _repository.updateGroupCallSettings(
        groupCallId: event.groupCallId,
        title: event.title,
        isRecording: event.isRecording,
        settings: event.settings,
      );
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onUpdateParticipant(
    UpdateParticipant event,
    Emitter<GroupCallState> emit,
  ) async {
    try {
      await _repository.updateParticipant(
        groupCallId: event.groupCallId,
        participantId: event.participantId,
        role: event.role,
        isMuted: event.isMuted,
        isScreenSharing: event.isScreenSharing,
      );
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onLoadHistory(
    LoadGroupCallHistory event,
    Emitter<GroupCallState> emit,
  ) async {
    emit(GroupCallLoading());
    try {
      final response = await _repository.getGroupCallHistory(
        status: event.status,
        fromDate: event.fromDate,
        toDate: event.toDate,
        limit: event.limit,
        offset: event.offset,
      );
      emit(GroupCallHistoryLoaded(
        groupCalls: response.groupCalls,
        total: response.total,
        hasMore: response.groupCalls.length >= event.limit,
      ));
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onLoadParticipants(
    LoadParticipants event,
    Emitter<GroupCallState> emit,
  ) async {
    try {
      final response = await _repository.getParticipants(event.groupCallId);
      emit(ParticipantsLoaded(participants: response.participants, total: response.total));
    } catch (e) {
      emit(GroupCallError(message: e.toString()));
    }
  }

  Future<void> _onHandleInvite(
    HandleGroupCallInvite event,
    Emitter<GroupCallState> emit,
  ) async {
    // Navigate to group call screen - emit joining state, the WebRTC callbacks will handle active state
    emit(GroupCallJoining(groupCallId: event.groupCall.groupCallId));
  }

  Future<void> _onRealtimeEvent(
    GroupCallRealtimeEvent event,
    Emitter<GroupCallState> emit,
  ) async {
    // Handle real-time events from WebSocket
    final data = event.data;
    final type = data['type'] as String?;

    switch (type) {
      case 'participant_joined':
        // Handled by WebRTCService callbacks
        break;
      case 'participant_left':
        // Handled by WebRTCService callbacks
        break;
      case 'call_end':
        add(GroupCallErrorOccurred(message: 'Call ended by host'));
        break;
    }
  }

  Future<void> _onToggleMute(
    ToggleMuteGroupCall event,
    Emitter<GroupCallState> emit,
  ) async {
    await _webRTCService.toggleMute();
    if (state is GroupCallActive) {
      _emitActiveState();
    }
  }

  Future<void> _onErrorOccurred(
    GroupCallErrorOccurred event,
    Emitter<GroupCallState> emit,
  ) async {
    _webRTCService.dispose();
    _stopDurationTimer();
    emit(GroupCallError(message: event.message));
  }

  Future<void> _onCleanup(
    GroupCallCleanup event,
    Emitter<GroupCallState> emit,
  ) async {
    _webRTCService.dispose();
    _stopDurationTimer();
    emit(GroupCallInitial());
  }

  void _emitActiveState({
    MediaStream? stream,
  }) {
    if (state is GroupCallActive) {
      final currentState = state as GroupCallActive;
      emit(GroupCallActive(
        groupCall: currentState.groupCall,
        localStream: stream ?? currentState.localStream,
        remoteStreams: Map.from(_webRTCService.remoteStreams),
        isMuted: currentState.isMuted,
        duration: currentState.duration,
        isHost: currentState.isHost,
      ));
    } else if (state is GroupCallJoining) {
      final localStream = _webRTCService.localStream;
      if (localStream != null) {
        _startDurationTimer();
        // Get group call info to create GroupCallModel
        final groupCallId = _webRTCService.currentGroupCallId;
        if (groupCallId != null) {
          _repository.getGroupCallById(groupCallId).then((groupCall) {
            if (groupCall != null) {
              emit(GroupCallActive(
                groupCall: groupCall,
                localStream: localStream,
                remoteStreams: Map.from(_webRTCService.remoteStreams),
                isMuted: false,
                duration: 0,
                isHost: _webRTCService.isHost,
              ));
            }
          });
        }
      }
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _duration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration++;
      if (state is GroupCallActive) {
        final currentState = state as GroupCallActive;
        emit(GroupCallActive(
          groupCall: currentState.groupCall,
          localStream: currentState.localStream,
          remoteStreams: currentState.remoteStreams,
          isMuted: currentState.isMuted,
          duration: _duration,
          isHost: currentState.isHost,
        ));
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _duration = 0;
  }

  @override
  Future<void> close() {
    _webRTCService.dispose();
    _stopDurationTimer();
    return super.close();
  }
}