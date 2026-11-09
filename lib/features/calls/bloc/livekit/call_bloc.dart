import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/livekit_audio_service.dart';
import '../../repository/call_livekit_repository.dart';
import '../../repository/group_call_livekit_repository.dart';
import '../../../../core/network/websocket_manager.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final LiveKitAudioService _liveKitService;
  final CallLiveKitRepository _callRepository;
  final GroupCallLiveKitRepository _groupCallRepository;
  final WebSocketManager _wsManager;

  String? _currentCallId;
  String? _currentRoomName;
  bool _isGroupCall = false;
  String? _currentTaskId;
  String? _currentUserId;
  bool _isHost = false;

  // Pending connection info for caller waiting for callee to accept
  String? _pendingToken;
  String? _pendingRoomName;
  String? _pendingLivekitUrl;
  String? _pendingCalleeName;

  CallBloc({
    required this._liveKitService,
    required this._callRepository,
    required this._groupCallRepository,
    required this._wsManager,
  }) : super(const CallIdleState()) {
    _setupLiveKitListeners();
    _setupWebSocketListeners();
    on<Initiate1on1CallEvent>(_onInitiate1on1Call);
    on<IncomingCallReceivedEvent>(_onIncomingCallReceived);
    on<AcceptCallEvent>(_onAcceptCall);
    on<RejectCallEvent>(_onRejectCall);
    on<JoinGroupVoiceEvent>(_onJoinGroupVoice);
    on<LeaveCallEvent>(_onLeaveCall);
    on<EndGroupCallEvent>(_onEndGroupCall);
    on<ToggleMicrophoneEvent>(_onToggleMicrophone);
    on<OnActiveSpeakersChangedEvent>(_onActiveSpeakersChanged);
    on<OnParticipantConnectedEvent>(_onParticipantConnected);
    on<OnParticipantDisconnectedEvent>(_onParticipantDisconnected);
    on<OnConnectionErrorEvent>(_onConnectionError);
    on<OnConnectedEvent>(_onConnected);
    on<OnDisconnectedEvent>(_onDisconnected);
    on<CalleeAcceptedEvent>(_onCalleeAccepted);
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  String? get currentCallId => _currentCallId;

  void _setupWebSocketListeners() {
    // Listen for incoming call notifications (real-time when app is foreground)
    _wsManager.on('call:incoming', (data) {
      add(
        IncomingCallReceivedEvent(
          callId: data['callId']?.toString() ?? '',
          callerName: data['callerName']?.toString() ?? '',
          callerAvatar: null, // Will be fetched from user profile if needed
          token: data['token']?.toString() ?? '',
          roomName: data['roomName']?.toString() ?? '',
          livekitUrl: data['livekitUrl']?.toString() ?? '',
        ),
      );
    });

    // Listen for callee acceptance via WebSocket (LiveKit audio calls)
    _wsManager.on('call:answered', (data) {
      final token = data['token'];
      final tokenStr = token is String ? token : (token?.toString() ?? '');

      add(
        CalleeAcceptedEvent(
          callId: data['callId']?.toString() ?? '',
          token: tokenStr,
          roomName: data['roomName']?.toString() ?? '',
          livekitUrl: data['livekitUrl']?.toString() ?? '',
        ),
      );
    });

    // Listen for callee acceptance via WebSocket (WebRTC video calls - legacy)
    _wsManager.on('call:accepted', (data) {
      final token = data['token'];
      final tokenStr = token is String ? token : (token?.toString() ?? '');

      add(
        CalleeAcceptedEvent(
          callId: data['callId']?.toString() ?? '',
          token: tokenStr,
          roomName: data['roomName']?.toString() ?? '',
          livekitUrl: data['livekitUrl']?.toString() ?? '',
        ),
      );
    });

    // Group call WebSocket events
    _wsManager.on('group-call:user-joined', (data) {
      add(
        OnParticipantConnectedEvent(
          participantId: data['participantId']?.toString() ?? '',
          userName: data['userName']?.toString() ?? '',
          userAvatar: data['userAvatar']?.toString(),
        ),
      );
    });

    _wsManager.on('group-call:user-left', (data) {
      add(
        OnParticipantDisconnectedEvent(data['participantId']?.toString() ?? ''),
      );
    });

    _wsManager.on('group-call:ended', (data) {
      add(const OnDisconnectedEvent());
    });
  }

  void _setupLiveKitListeners() {
    _liveKitService.onActiveSpeakersChanged = (speakers) {
      final speakerIds = speakers.map((p) => p.sid).toList();
      add(OnActiveSpeakersChangedEvent(speakerIds));
    };

    _liveKitService.onParticipantConnected = (participant) {
      add(
        OnParticipantConnectedEvent(
          participantId: participant.sid,
          userName: participant.name,
          userAvatar: participant.metadata,
        ),
      );
    };

    _liveKitService.onParticipantDisconnected = (participant) {
      add(OnParticipantDisconnectedEvent(participant.sid));
    };

    _liveKitService.onConnectionError = (error) {
      add(OnConnectionErrorEvent(error));
    };

    _liveKitService.onConnected = () {
      add(const OnConnectedEvent());
    };

    _liveKitService.onDisconnected = () {
      add(const OnDisconnectedEvent());
    };
  }

  Future<void> _onInitiate1on1Call(
    Initiate1on1CallEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      final call = await _callRepository.initiateCall(event.calleeId);
      _currentCallId = call.callId;
      _currentRoomName = call.roomName;
      _isGroupCall = false;

      // Store connection info for later when callee accepts
      _pendingToken = call.token;
      _pendingRoomName = call.roomName;
      _pendingLivekitUrl = call.livekitUrl;
      _pendingCalleeName =
          event.calleeId; // TODO: Get actual callee name from user profile

      // Emit ringing state for caller - wait for callee to accept
      emit(
        CallRingingState(
          callId: call.callId,
          callerName: 'You', // Caller sees their own name
          token: call.token,
          roomName: call.roomName,
          livekitUrl: call.livekitUrl,
          isOutgoing: true,
          targetName: _pendingCalleeName ?? 'Unknown',
        ),
      );

      // Do NOT connect to LiveKit yet - wait for CalleeAcceptedEvent
    } catch (e) {
      emit(CallErrorState('Failed to initiate call: $e'));
    }
  }

  Future<void> _onIncomingCallReceived(
    IncomingCallReceivedEvent event,
    Emitter<CallState> emit,
  ) async {
    _currentCallId = event.callId;
    _currentRoomName = event.roomName;
    _isGroupCall = false;

    // Store connection info for when user accepts
    _pendingToken = event.token;
    _pendingRoomName = event.roomName;
    _pendingLivekitUrl = event.livekitUrl;
    _pendingCalleeName = event.callerName;

    emit(
      CallRingingState(
        callId: event.callId,
        callerName: event.callerName,
        callerAvatar: event.callerAvatar,
        token: event.token,
        roomName: event.roomName,
        livekitUrl: event.livekitUrl,
        isOutgoing: false, // Callee receiving incoming call
        targetName: event.callerName,
      ),
    );
  }

  Future<void> _onAcceptCall(
    AcceptCallEvent event,
    Emitter<CallState> emit,
  ) async {
    if (state is CallRingingState) {
      final ringingState = state as CallRingingState;

      emit(
        CallConnectingState(
          callId: event.callId,
          roomName: ringingState.roomName,
          token: ringingState.token,
          livekitUrl: ringingState.livekitUrl,
        ),
      );

      try {
        // Call API to accept call and get LiveKit token for callee
        final call = await _callRepository.acceptCall(event.callId);

        await _liveKitService.connect(
          token: call.token,
          roomName: call.roomName,
        );
      } catch (e) {
        emit(CallErrorState('Failed to accept call: $e'));
      }
    }
  }

  Future<void> _onCalleeAccepted(
    CalleeAcceptedEvent event,
    Emitter<CallState> emit,
  ) async {
    // Caller receives this when callee accepts - now connect to LiveKit
    if (state is CallRingingState && (state as CallRingingState).isOutgoing) {
      // Store connection info for navigation
      _pendingToken = event.token;
      _pendingRoomName = event.roomName;
      _pendingLivekitUrl = event.livekitUrl;

      emit(
        CallConnectingState(
          callId: event.callId,
          roomName: event.roomName,
          token: event.token,
          livekitUrl: event.livekitUrl,
        ),
      );

      try {
        await _liveKitService.connect(
          token: event.token,
          roomName: event.roomName,
        );
      } catch (e) {
        emit(CallErrorState('Failed to connect to call: $e'));
      }
    }
  }

  Future<void> _onRejectCall(
    RejectCallEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      if (_currentCallId != null) {
        await _callRepository.rejectCall(_currentCallId!);
      }
    } catch (e) {
      // Ignore error when rejecting
    }

    _resetCallState();
    emit(const CallIdleState());
  }

  Future<void> _onJoinGroupVoice(
    JoinGroupVoiceEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      final groupCall = await _groupCallRepository.joinGroupCall(event.taskId);
      _currentCallId = groupCall.groupCallId;
      _currentRoomName = groupCall.roomName;
      _currentTaskId = event.taskId;
      _isGroupCall = true;
      // Determine if current user is the host
      _isHost = groupCall.hostId == _currentUserId;

      _wsManager.emit('group-call:join', {
        'groupCallId': groupCall.groupCallId,
      });

      emit(
        CallConnectingState(
          callId: groupCall.groupCallId,
          roomName: groupCall.roomName,
        ),
      );

      await _liveKitService.connect(
        token: groupCall.token,
        roomName: groupCall.roomName,
      );
    } catch (e) {
      emit(CallErrorState('Failed to join group voice: $e'));
    }
  }

  Future<void> _onLeaveCall(
    LeaveCallEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      if (_currentCallId != null) {
        if (_isGroupCall) {
          await _groupCallRepository.leaveGroupCall(_currentCallId!);
        } else {
          await _callRepository.endCall(_currentCallId!);
        }
      }
    } catch (e) {
      // Ignore error when leaving
    }

    await _liveKitService.leaveRoom();
    _resetCallState();
    emit(const CallIdleState());
  }

  Future<void> _onToggleMicrophone(
    ToggleMicrophoneEvent event,
    Emitter<CallState> emit,
  ) async {
    await _liveKitService.setMicrophoneEnabled(event.enabled);

    if (state is CallActiveState) {
      final activeState = state as CallActiveState;
      final updatedParticipants = activeState.participants.map((p) {
        if (p.isLocal) {
          return p.copyWith(isMuted: !event.enabled);
        }
        return p;
      }).toList();

      emit(
        activeState.copyWith(
          isMuted: !event.enabled,
          participants: updatedParticipants,
        ),
      );
    }
  }

  void _onActiveSpeakersChanged(
    OnActiveSpeakersChangedEvent event,
    Emitter<CallState> emit,
  ) {
    if (state is CallActiveState) {
      final activeState = state as CallActiveState;
      String? activeSpeakerId;
      if (event.activeSpeakerIds.isNotEmpty) {
        activeSpeakerId = event.activeSpeakerIds.first;
      }

      final updatedParticipants = activeState.participants.map((p) {
        final isSpeaking = event.activeSpeakerIds.contains(p.participantId);
        return p.copyWith(isSpeaking: isSpeaking);
      }).toList();

      emit(
        activeState.copyWith(
          activeSpeakerId: activeSpeakerId,
          participants: updatedParticipants,
        ),
      );
    }
  }

  void _onParticipantConnected(
    OnParticipantConnectedEvent event,
    Emitter<CallState> emit,
  ) {
    if (state is CallActiveState) {
      final activeState = state as CallActiveState;
      final newParticipant = CallParticipant(
        participantId: event.participantId,
        userName: event.userName,
        userAvatar: event.userAvatar,
        isMuted: false,
        isSpeaking: false,
        isLocal: false,
      );

      final updatedParticipants = [...activeState.participants, newParticipant];
      emit(activeState.copyWith(participants: updatedParticipants));
    }
  }

  void _onParticipantDisconnected(
    OnParticipantDisconnectedEvent event,
    Emitter<CallState> emit,
  ) {
    if (state is CallActiveState) {
      final activeState = state as CallActiveState;
      final updatedParticipants = activeState.participants
          .where((p) => p.participantId != event.participantId)
          .toList();

      emit(activeState.copyWith(participants: updatedParticipants));
    }
  }

  void _onConnectionError(
    OnConnectionErrorEvent event,
    Emitter<CallState> emit,
  ) {
    emit(CallErrorState(event.error));
  }

  void _onConnected(OnConnectedEvent event, Emitter<CallState> emit) {
    final localParticipant = _liveKitService.getLocalParticipant();
    final remoteParticipants = _liveKitService.getRemoteParticipants();

    final participants = <CallParticipant>[];

    // Add local participant
    if (localParticipant != null) {
      participants.add(
        CallParticipant(
          participantId: localParticipant.sid,
          userName: 'You',
          userAvatar: null,
          isMuted: !localParticipant.isMicrophoneEnabled(),
          isSpeaking: false,
          isLocal: true,
        ),
      );
    }

    // Add remote participants
    for (final p in remoteParticipants) {
      participants.add(
        CallParticipant(
          participantId: p.sid,
          userName: p.name,
          userAvatar: p.metadata,
          isMuted: !p.isMicrophoneEnabled(),
          isSpeaking: false,
          isLocal: false,
        ),
      );
    }

    emit(
      CallActiveState(
        callId: _currentCallId!,
        roomName: _currentRoomName!,
        token: _pendingToken,
        livekitUrl: _pendingLivekitUrl,
        isMuted: localParticipant != null
            ? !localParticipant.isMicrophoneEnabled()
            : false,
        participants: participants,
        isGroupCall: _isGroupCall,
        taskId: _currentTaskId,
        isHost: _isHost,
      ),
    );
  }

  Future<void> _onDisconnected(
    OnDisconnectedEvent event,
    Emitter<CallState> emit,
  ) async {
    // <--- Tambahkan async
    final callId = _currentCallId ?? '';

    emit(CallEndedState(callId: callId, durationSeconds: null));

    // Tunggu 2 detik menggunakan await agar emit tetap valid
    await Future.delayed(const Duration(seconds: 2));

    _resetCallState();
    if (!isClosed) {
      emit(const CallIdleState());
    }
  }

  Future<void> _onEndGroupCall(
    EndGroupCallEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      if (_currentCallId != null && _isGroupCall) {
        await _groupCallRepository.endGroupCall(_currentCallId!);
      }
    } catch (e) {
      // Ignore error when ending
    }

    await _liveKitService.leaveRoom();
    _resetCallState();
    emit(const CallIdleState());
  }

  void _resetCallState() {
    _currentCallId = null;
    _currentRoomName = null;
    _currentTaskId = null;
    _isGroupCall = false;
    _isHost = false;
  }

  @override
  Future<void> close() {
    _liveKitService.dispose();
    return super.close();
  }
}

// Extension to add copyWith to CallActiveState
extension CallActiveStateCopyWith on CallActiveState {
  CallActiveState copyWith({
    String? callId,
    String? roomName,
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
      activeSpeakerId: activeSpeakerId ?? this.activeSpeakerId,
      isMuted: isMuted ?? this.isMuted,
      participants: participants ?? this.participants,
      isGroupCall: isGroupCall ?? this.isGroupCall,
      taskId: taskId ?? this.taskId,
      isHost: isHost ?? this.isHost,
    );
  }
}
