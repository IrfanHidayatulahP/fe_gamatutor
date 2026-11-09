import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveKitAudioService {
  Room? _room;
  bool _isConnected = false;
  String? _currentRoomName;

  // Callbacks
  Function(List<Participant>)? onActiveSpeakersChanged;
  Function(Participant)? onParticipantConnected;
  Function(Participant)? onParticipantDisconnected;
  Function(String)? onConnectionError;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;
  String? get currentRoomName => _currentRoomName;

  Future<void> connect({
    required String token,
    required String roomName,
  }) async {
    try {
      // Request microphone permission before connecting
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        onConnectionError?.call('Microphone permission denied');
        throw Exception('Microphone permission denied');
      }

      _currentRoomName = roomName;

      _room = Room(
        roomOptions: RoomOptions(
          defaultAudioPublishOptions: AudioPublishOptions(
            dtx: true,
            red: true,
          ),
          defaultVideoPublishOptions: VideoPublishOptions(),
        ),
      );

      // Set up event listeners using stream-based events
      _room!.events.on<ActiveSpeakersChangedEvent>(_handleActiveSpeakersChanged);
      _room!.events.on<ParticipantConnectedEvent>(_handleParticipantConnected);
      _room!.events.on<ParticipantDisconnectedEvent>(_handleParticipantDisconnected);
      _room!.events.on<RoomDisconnectedEvent>(_handleDisconnected);
      _room!.events.on<RoomConnectedEvent>(_handleConnected);
      _room!.events.on<LocalTrackPublishedEvent>(_handleLocalTrackPublished);

      // Connect with audio-only options
      await _room!.connect(
        livekitUrl,
        token,
      );

      _isConnected = true;

      // Explicitly enable microphone after connect
      await setMicrophoneEnabled(true);
    } catch (e) {
      onConnectionError?.call(e.toString());
      rethrow;
    }
  }

  void _handleActiveSpeakersChanged(ActiveSpeakersChangedEvent event) {
    final speakers = event.speakers;
    onActiveSpeakersChanged?.call(speakers);
  }

  void _handleParticipantConnected(ParticipantConnectedEvent event) {
    onParticipantConnected?.call(event.participant);
  }

  void _handleParticipantDisconnected(ParticipantDisconnectedEvent event) {
    onParticipantDisconnected?.call(event.participant);
  }

  void _handleConnected(RoomConnectedEvent event) {
    onConnected?.call();
  }

  void _handleDisconnected(RoomDisconnectedEvent event) {
    _isConnected = false;
    onDisconnected?.call();
  }

  void _handleLocalTrackPublished(LocalTrackPublishedEvent event) {
    // Local track published
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (_room == null) return;

    try {
      final localParticipant = _room!.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setMicrophoneEnabled(enabled);
      }
    } catch (e) {
      onConnectionError?.call('Failed to toggle microphone: $e');
    }
  }

    Future<void> leaveRoom() async {
    if (_room == null) return;

    try {
      await setMicrophoneEnabled(false);
      await Future.delayed(const Duration(milliseconds: 100));
      await _room!.disconnect();
      _room = null;
      _isConnected = false;
      _currentRoomName = null;
    } catch (e) {
      debugPrint('Failed to leave room: $e');
    }
  }

  List<Participant> getRemoteParticipants() {
    if (_room == null) return [];
    return _room!.remoteParticipants.values.toList();
  }

  Participant? getLocalParticipant() {
    return _room?.localParticipant;
  }

  bool get isMicrophoneEnabled {
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return false;
    return localParticipant.isMicrophoneEnabled();
  }

  void dispose() {
    leaveRoom();
  }
}

// LiveKit Cloud URL - replace with your actual URL
const String livekitUrl = 'wss://gamatutor-rifo726f.livekit.cloud';