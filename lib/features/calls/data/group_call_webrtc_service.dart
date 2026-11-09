import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/network/websocket_manager.dart';

class GroupCallWebRTCService {
  final WebSocketManager _wsManager;

  // Map of peer connections: remoteUserId -> RTCPeerConnection
  final Map<String, RTCPeerConnection> _peerConnections = {};

  // Map of remote streams: remoteUserId -> MediaStream
  final Map<String, MediaStream> _remoteStreams = {};

  MediaStream? _localStream;
  String? _currentGroupCallId;
  String? _currentUserId;
  List<String> _participantIds = [];
  bool _isHost = false;

  // Callbacks
  Function(MediaStream)? onLocalStream;
  Function(String, MediaStream)? onRemoteStreamAdded;
  Function(String)? onRemoteStreamRemoved;
  Function(String)? onParticipantJoined;
  Function(String)? onParticipantLeft;
  Function(String)? onCallEnded;
  Function(String)? onError;

  GroupCallWebRTCService(this._wsManager) {
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    _wsManager.on('group_call:offer', _handleOffer);
    _wsManager.on('group_call:answer', _handleAnswer);
    _wsManager.on('group_call:ice-candidate', _handleIceCandidate);
    _wsManager.on('group_call:participant_joined', _handleParticipantJoined);
    _wsManager.on('group_call:participant_left', _handleParticipantLeft);
    _wsManager.on('group_call:end', _handleCallEnd);
    _wsManager.on('group_call:reject', _handleCallReject);
  }

  Future<void> initialize() async {
    await _getUserMedia();
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      onLocalStream?.call(_localStream!);
    } catch (e) {
      onError?.call('Failed to get user media: $e');
    }
  }

  Future<void> joinGroupCall({
    required String groupCallId,
    required String userId,
    required List<String> participantIds,
    required bool isHost,
  }) async {
    _currentGroupCallId = groupCallId;
    _currentUserId = userId;
    _participantIds = participantIds.where((id) => id != userId).toList();
    _isHost = isHost;

    await initialize();

    // Create peer connections for existing participants
    for (final participantId in _participantIds) {
      await _createPeerConnection(participantId, isInitiator: _isHost);
    }

    // If host, create offers for all participants
    if (_isHost) {
      for (final participantId in _participantIds) {
        await _createOffer(participantId);
      }
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String remoteUserId, {required bool isInitiator}) async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };

    final pc = await createPeerConnection(configuration);
    _peerConnections[remoteUserId] = pc;

    pc.onIceCandidate = (candidate) {
      if (candidate != null && _currentGroupCallId != null) {
        _wsManager.emit('group_call:ice-candidate', {
          'groupCallId': _currentGroupCallId,
          'targetUserId': remoteUserId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    pc.onIceConnectionState = (state) {
      print('ICE Connection State with $remoteUserId: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _handlePeerConnectionFailure(remoteUserId);
      }
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStreams[remoteUserId] = event.streams.first;
        onRemoteStreamAdded?.call(remoteUserId, _remoteStreams[remoteUserId]!);
      }
    };

    // Add local stream tracks to peer connection
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        pc.addTrack(track, _localStream!);
      });
    }

    return pc;
  }

  Future<void> _createOffer(String remoteUserId) async {
    final pc = _peerConnections[remoteUserId];
    if (pc == null) return;

    try {
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      if (_currentGroupCallId != null) {
        _wsManager.emit('group_call:offer', {
          'groupCallId': _currentGroupCallId,
          'targetUserId': remoteUserId,
          'offer': offer.toMap(),
        });
      }
    } catch (e) {
      onError?.call('Failed to create offer for $remoteUserId: $e');
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> data) async {
    final remoteUserId = data['fromUserId'];
    if (_currentGroupCallId != data['groupCallId']) return;

    var pc = _peerConnections[remoteUserId];
    if (pc == null) {
      pc = await _createPeerConnection(remoteUserId, isInitiator: false);
    }

    try {
      final offer = RTCSessionDescription(data['offer']['sdp'], data['offer']['type']);
      await pc.setRemoteDescription(offer);

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      _wsManager.emit('group_call:answer', {
        'groupCallId': _currentGroupCallId,
        'targetUserId': remoteUserId,
        'answer': answer.toMap(),
      });
    } catch (e) {
      onError?.call('Failed to handle offer from $remoteUserId: $e');
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    final remoteUserId = data['fromUserId'];
    if (_currentGroupCallId != data['groupCallId']) return;

    final pc = _peerConnections[remoteUserId];
    if (pc == null) return;

    try {
      final answer = RTCSessionDescription(data['answer']['sdp'], data['answer']['type']);
      await pc.setRemoteDescription(answer);
    } catch (e) {
      onError?.call('Failed to handle answer from $remoteUserId: $e');
    }
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    final remoteUserId = data['fromUserId'];
    if (_currentGroupCallId != data['groupCallId']) return;

    final pc = _peerConnections[remoteUserId];
    if (pc == null) return;

    try {
      final candidate = data['candidate'];
      final iceCandidate = RTCIceCandidate(
        candidate['candidate'],
        candidate['sdpMid'],
        candidate['sdpMLineIndex'],
      );
      await pc.addCandidate(iceCandidate);
    } catch (e) {
      onError?.call('Failed to add ICE candidate from $remoteUserId: $e');
    }
  }

  void _handleParticipantJoined(Map<String, dynamic> data) {
    if (_currentGroupCallId != data['groupCallId']) return;

    final newParticipantId = data['userId'];
    if (newParticipantId == _currentUserId) return;
    if (_participantIds.contains(newParticipantId)) return;

    _participantIds.add(newParticipantId);

    _createPeerConnection(newParticipantId, isInitiator: _isHost).then((_) {
      if (_isHost) {
        _createOffer(newParticipantId);
      }
      onParticipantJoined?.call(newParticipantId);
    });
  }

  void _handleParticipantLeft(Map<String, dynamic> data) {
    if (_currentGroupCallId != data['groupCallId']) return;

    final leftParticipantId = data['userId'];
    _participantIds.remove(leftParticipantId);
    _cleanupPeerConnection(leftParticipantId);
    onParticipantLeft?.call(leftParticipantId);
  }

  void _handleCallEnd(Map<String, dynamic> data) {
    if (_currentGroupCallId == data['groupCallId']) {
      _cleanup();
      onCallEnded?.call(data['groupCallId']);
    }
  }

  void _handleCallReject(Map<String, dynamic> data) {
    if (_currentGroupCallId == data['groupCallId']) {
      _cleanup();
      onCallEnded?.call(data['groupCallId']);
    }
  }

  void _handlePeerConnectionFailure(String remoteUserId) {
    _cleanupPeerConnection(remoteUserId);
    _participantIds.remove(remoteUserId);
    onParticipantLeft?.call(remoteUserId);
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

  Future<void> leaveGroupCall() async {
    if (_currentGroupCallId != null) {
      _wsManager.emit('group_call:end', {'groupCallId': _currentGroupCallId});
    }
    _cleanup();
  }

  void _cleanupPeerConnection(String remoteUserId) {
    final pc = _peerConnections[remoteUserId];
    pc?.close();
    _peerConnections.remove(remoteUserId);
    _remoteStreams.remove(remoteUserId);
    onRemoteStreamRemoved?.call(remoteUserId);
  }

  void _cleanup() {
    for (final pc in _peerConnections.values) {
      pc.close();
    }
    _peerConnections.clear();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream = null;
    _remoteStreams.clear();
    _currentGroupCallId = null;
    _participantIds.clear();
    _isHost = false;
  }

  void dispose() {
    _cleanup();
    _wsManager.off('group_call:offer', _handleOffer);
    _wsManager.off('group_call:answer', _handleAnswer);
    _wsManager.off('group_call:ice-candidate', _handleIceCandidate);
    _wsManager.off('group_call:participant_joined', _handleParticipantJoined);
    _wsManager.off('group_call:participant_left', _handleParticipantLeft);
    _wsManager.off('group_call:end', _handleCallEnd);
    _wsManager.off('group_call:reject', _handleCallReject);
  }

  MediaStream? get localStream => _localStream;
  Map<String, MediaStream> get remoteStreams => Map.unmodifiable(_remoteStreams);
  List<String> get participantIds => List.unmodifiable(_participantIds);
  bool get isHost => _isHost;
  String? get currentGroupCallId => _currentGroupCallId;
}