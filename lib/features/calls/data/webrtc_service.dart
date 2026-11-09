import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/network/websocket_manager.dart';

class WebRTCService {
  final WebSocketManager _wsManager;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  String? _currentCallId;
  String? _currentUserId;
  String? _remoteUserId;
  bool _isInitiator = false;

  // Callbacks
  Function(MediaStream)? onLocalStream;
  Function(MediaStream)? onRemoteStream;
  Function(String)? onCallEnded;
  Function(String)? onError;
  Function(Map<String, dynamic>)? onSignalingData;

  WebRTCService(this._wsManager) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _wsManager.on('call:offer', _handleOffer);
    _wsManager.on('call:answer', _handleAnswer);
    _wsManager.on('call:ice-candidate', _handleIceCandidate);
    _wsManager.on('call:end', _handleCallEnd);
    _wsManager.on('call:reject', _handleCallReject);
  }

  Future<void> initialize() async {
    await _createPeerConnection();
    await _getUserMedia();
  }

  Future<void> _createPeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null && _currentCallId != null && _remoteUserId != null) {
        _wsManager.emit('call:ice-candidate', {
          'callId': _currentCallId,
          'targetUserId': _remoteUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    _peerConnection!.onIceConnectionState = (state) {
      print('ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _handleConnectionFailure();
      }
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        onRemoteStream?.call(_remoteStream!);
      }
    };

    // Add local stream tracks to peer connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    }
  }

  Future<void> _getUserMedia() async {
    // Request microphone permission before accessing media devices
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      onError?.call('Microphone permission denied');
      return;
    }

    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      onLocalStream?.call(_localStream!);

      // Add tracks to peer connection if already created
      if (_peerConnection != null) {
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
        });
      }
    } catch (e) {
      onError?.call('Failed to get user media: $e');
    }
  }

  Future<void> makeCall({
    required String callId,
    required String callerId,
    required String calleeId,
  }) async {
    _currentCallId = callId;
    _currentUserId = callerId;
    _remoteUserId = calleeId;
    _isInitiator = true;

    await initialize();
    await _createOffer();
  }

  Future<void> answerCall({
    required String callId,
    required String userId,
    required String callerId,
  }) async {
    _currentCallId = callId;
    _currentUserId = userId;
    _remoteUserId = callerId;
    _isInitiator = false;

    await initialize();
  }

  Future<void> _createOffer() async {
    if (_peerConnection == null) return;

    try {
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);

      if (_currentCallId != null && _remoteUserId != null) {
        _wsManager.emit('call:offer', {
          'callId': _currentCallId,
          'targetUserId': _remoteUserId,
          'offer': offer.toMap(),
        });
      }
    } catch (e) {
      onError?.call('Failed to create offer: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_peerConnection == null || _currentCallId != data['callId']) return;

    try {
      final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
      await _peerConnection!.setRemoteDescription(offer);

      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      _wsManager.emit('call:answer', {
        'callId': _currentCallId,
        'targetUserId': _remoteUserId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      onError?.call('Failed to handle offer: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null || _currentCallId != data['callId']) return;

    try {
      final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await _peerConnection!.setRemoteDescription(answer);
    } catch (e) {
      onError?.call('Failed to handle answer: $e');
    }
  }

  /// Handle callee's answer from signaling (for caller waiting for acceptance)
  Future<void> handleCalleeAnswer({
    required String callId,
    required Map<String, dynamic> answer,
  }) async {
    if (_peerConnection == null || _currentCallId != callId) return;

    try {
      final sdpAnswer = RTCSessionDescription(answer['sdp'], answer['type']);
      await _peerConnection!.setRemoteDescription(sdpAnswer);
    } catch (e) {
      onError?.call('Failed to handle callee answer: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null || _currentCallId != data['callId']) return;

    try {
      final candidate = data['candidate'];
      final iceCandidate = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(iceCandidate);
    } catch (e) {
      onError?.call('Failed to add ICE candidate: $e');
    }
  }

  void _handleCallEnd(Map<String, dynamic> data) {
    if (_currentCallId == data['callId']) {
      _cleanup();
      onCallEnded?.call(data['callId']);
    }
  }

  void _handleCallReject(Map<String, dynamic> data) {
    if (_currentCallId == data['callId']) {
      _cleanup();
      onCallEnded?.call(data['callId']);
    }
  }

  void _handleConnectionFailure() {
    if (_currentCallId != null) {
      _wsManager.emit('call:end', {'callId': _currentCallId});
      _cleanup();
      onCallEnded?.call(_currentCallId!);
    }
  }

  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      for (final track in audioTracks) {
        track.enabled = !track.enabled;
      }
    }
  }

  Future<void> toggleSpeaker() async {
    // Speaker handling is platform-specific
    // On mobile, this would use the audio session APIs
    // On web, the browser handles audio output device selection
    try {
      // For now, this is a no-op - the actual speaker toggle
      // would be implemented using platform channels or
      // the WebRTC audio output device APIs
    } catch (e) {
      onError?.call('Failed to toggle speaker: $e');
    }
  }

  Future<void> endCall() async {
    if (_currentCallId != null) {
      _wsManager.emit('call:end', {'callId': _currentCallId});
    }
    _cleanup();
  }

  void _cleanup() {
    _peerConnection?.close();
    _peerConnection = null;
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _remoteStream = null;
    _currentCallId = null;
    _remoteUserId = null;
    _isInitiator = false;
  }

  void dispose() {
    _cleanup();
    _wsManager.off('call:offer', _handleOffer);
    _wsManager.off('call:answer', _handleAnswer);
    _wsManager.off('call:ice-candidate', _handleIceCandidate);
    _wsManager.off('call:end', _handleCallEnd);
    _wsManager.off('call:reject', _handleCallReject);
  }

  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  bool get isConnected => _peerConnection?.connectionState == RTCPeerConnectionState.RTCPeerConnectionStateConnected;
}