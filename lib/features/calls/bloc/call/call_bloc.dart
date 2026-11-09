import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../../repository/call_repository.dart';
import '../../data/webrtc_service.dart';
import '../../../../core/network/websocket_manager.dart';
import 'call_event.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRepository _repository;
  final WebRTCService _webRTCService;
  final WebSocketManager _wsManager;

  String? _currentUserId;
  Timer? _durationTimer;
  int _duration = 0;

  // Pending connection info for caller waiting for callee to accept (voice-only app)
  String? _pendingCallId;
  String? _pendingCalleeId;

  CallBloc({
    required CallRepository repository,
    required WebRTCService webRTCService,
    required WebSocketManager wsManager,
  })  : _repository = repository,
        _webRTCService = webRTCService,
        _wsManager = wsManager,
        super(const CallIdle()) {
    on<CallInitiated>(_onCallInitiated);
    on<CallAnswered>(_onCallAnswered);
    on<CallRejected>(_onCallRejected);
    on<CallEnded>(_onCallEnded);
    on<CallSignalingReceived>(_onSignalingReceived);
    on<CallIncoming>(_onIncomingCall);
    on<CallRinging>(_onRinging);
    on<CallToggledMute>(_onToggleMute);
    on<CallErrorOccurred>(_onErrorOccurred);
    on<CallCleanup>(_onCleanup);
    on<CalleeAcceptedEvent>(_onCalleeAccepted);

    _setupWebRTCCallbacks();
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    // Listen for incoming call notifications (real-time when app is foreground)
    _wsManager.on('call:incoming', (data) {
      add(CallIncoming(
        callId: data['callId'],
        callerId: data['callerId'],
        callerName: data['callerName'],
      ));
    });

    // Listen for callee acceptance via WebSocket
    _wsManager.on('call:accepted', (data) {
      add(CalleeAcceptedEvent(
        callId: data['callId'],
        signalingData: data['signalingData'] ?? {},
      ));
    });
  }

  void _setupWebRTCCallbacks() {
    _webRTCService.onLocalStream = (stream) {
      if (state is CallConnecting || state is CallConnected) {
        _emitConnectedState(stream: stream);
      }
    };

    _webRTCService.onRemoteStream = (stream) {
      if (state is CallConnecting || state is CallConnected) {
        _emitConnectedState(remoteStream: stream);
      }
    };

    _webRTCService.onCallEnded = (callId) {
      add(CallEnded(callId: callId));
    };

    _webRTCService.onError = (message) {
      add(CallErrorOccurred(message: message));
    };

    _webRTCService.onSignalingData = (data) {
      // Handle signaling data if needed
    };
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  Future<void> _onCallInitiated(
    CallInitiated event,
    Emitter<CallState> emit,
  ) async {
    // Guard clause: prevent double initiation
    if (state is CallOutgoing || state is CallConnecting || state is CallRingingState) return;

    try {
      // Create call via API (voice-only app, always audio)
      final response = await _repository.initiateCall(
        calleeId: event.calleeId,
      );

      if (response != null) {
        // Store pending connection info for when callee accepts
        _pendingCallId = response.callId;
        _pendingCalleeId = event.calleeId;

        // Emit ringing state for caller - wait for callee to accept
        emit(CallRingingState(
          callId: response.callId,
          calleeId: event.calleeId,
          targetName: event.calleeId, // TODO: Get actual callee name
          isOutgoing: true,
        ));

        // Do NOT start WebRTC connection yet - wait for CalleeAcceptedEvent
      } else {
        emit(const CallError(message: 'Failed to initiate call'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        emit(const CallError(message: 'User sedang dalam panggilan lain'));
        emit(const CallIdle());
      } else {
        emit(CallError(message: e.toString()));
      }
    } catch (e) {
      emit(CallError(message: e.toString()));
    }
  }

  Future<void> _onCallAnswered(
    CallAnswered event,
    Emitter<CallState> emit,
  ) async {
    try {
      // Get call details
      final call = await _repository.getCallById(event.callId);
      if (call == null) {
        emit(const CallError(message: 'Call not found'));
        return;
      }

      // Answer via API
      await _repository.answerCall(
        callId: event.callId,
        signalingData: {},
      );

      // Start WebRTC connection (voice-only app)
      await _webRTCService.answerCall(
        callId: event.callId,
        userId: _currentUserId!,
        callerId: call.callerId,
      );

      emit(CallConnecting(
        callId: event.callId,
        isInitiator: false,
      ));
    } catch (e) {
      emit(CallError(message: e.toString()));
    }
  }

  Future<void> _onCallRejected(
    CallRejected event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _repository.rejectCall(event.callId);
      _webRTCService.dispose();
      _stopDurationTimer();
      emit(CallEndedState(callId: event.callId, reason: 'rejected'));
    } catch (e) {
      emit(CallError(message: e.toString()));
    }
  }

  Future<void> _onCallEnded(
    CallEnded event,
    Emitter<CallState> emit,
  ) async {
    try {
      await _repository.endCall(event.callId);
      _webRTCService.dispose();
      _stopDurationTimer();
      emit(CallEndedState(callId: event.callId, reason: 'ended'));
    } catch (e) {
      emit(CallError(message: e.toString()));
    }
  }

  Future<void> _onSignalingReceived(
    CallSignalingReceived event,
    Emitter<CallState> emit,
  ) async {
    // Handle incoming signaling data via WebSocket
    // The WebRTCService handles this via socket listeners
    // This is for manual handling if needed
  }

  Future<void> _onIncomingCall(
    CallIncoming event,
    Emitter<CallState> emit,
  ) async {
    emit(CallRingingState(
      callId: event.callId,
      callerId: event.callerId,
      targetName: event.callerName,
      isOutgoing: false,
    ));
  }

  Future<void> _onCalleeAccepted(
    CalleeAcceptedEvent event,
    Emitter<CallState> emit,
  ) async {
    // Caller receives this when callee accepts - now complete WebRTC connection
    if (state is CallRingingState && (state as CallRingingState).isOutgoing) {
      if (_pendingCallId != null) {
        emit(CallConnecting(
          callId: _pendingCallId!,
          isInitiator: true,
        ));

        try {
          // Complete the WebRTC connection with the callee's SDP answer
          await _webRTCService.handleCalleeAnswer(
            callId: _pendingCallId!,
            answer: event.signalingData,
          );
        } catch (e) {
          emit(CallError(message: 'Failed to complete connection: $e'));
        }
      }
    }
  }

  Future<void> _onRinging(
    CallRinging event,
    Emitter<CallState> emit,
  ) async {
    // Guard clause: prevent double initiation
    if (state is CallConnecting) return;

    // Emit outgoing state for the caller
    emit(CallOutgoing(
      callId: event.callId,
      calleeId: event.callerId,
    ));

    // Start WebRTC connection
    await _webRTCService.makeCall(
      callId: event.callId,
      callerId: _currentUserId!,
      calleeId: event.callerId,
    );

    emit(CallConnecting(
      callId: event.callId,
      isInitiator: true,
    ));
  }

  Future<void> _onToggleMute(
    CallToggledMute event,
    Emitter<CallState> emit,
  ) async {
    await _webRTCService.toggleMute();
    if (state is CallConnected) {
      final currentState = state as CallConnected;
      emit(CallConnected(
        callId: currentState.callId,
        localStream: currentState.localStream,
        remoteStream: currentState.remoteStream,
        isMuted: !currentState.isMuted,
        duration: currentState.duration,
        isInitiator: currentState.isInitiator,
      ));
    }
  }

  Future<void> _onErrorOccurred(
    CallErrorOccurred event,
    Emitter<CallState> emit,
  ) async {
    _webRTCService.dispose();
    _stopDurationTimer();
    emit(CallError(message: event.message));
  }

  Future<void> _onCleanup(
    CallCleanup event,
    Emitter<CallState> emit,
  ) async {
    _webRTCService.dispose();
    _stopDurationTimer();
    emit(const CallIdle());
  }

  void _emitConnectedState({
    MediaStream? stream,
    MediaStream? remoteStream,
  }) {
    if (state is CallConnecting) {
      final currentState = state as CallConnecting;
      final localStream = _webRTCService.localStream;
      final remoteStream = _webRTCService.remoteStream;

      if (localStream != null && remoteStream != null) {
        _startDurationTimer();
        emit(CallConnected(
          callId: currentState.callId,
          localStream: localStream,
          remoteStream: remoteStream,
          isMuted: false,
          duration: 0,
          isInitiator: currentState.isInitiator,
        ));
      }
    } else if (state is CallConnected) {
      final currentState = state as CallConnected;
      emit(CallConnected(
        callId: currentState.callId,
        localStream: stream ?? currentState.localStream,
        remoteStream: remoteStream ?? currentState.remoteStream,
        isMuted: currentState.isMuted,
        duration: currentState.duration,
        isInitiator: currentState.isInitiator,
      ));
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _duration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _duration++;
      if (state is CallConnected) {
        final currentState = state as CallConnected;
        emit(CallConnected(
          callId: currentState.callId,
          localStream: currentState.localStream,
          remoteStream: currentState.remoteStream,
          isMuted: currentState.isMuted,
          duration: _duration,
          isInitiator: currentState.isInitiator,
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