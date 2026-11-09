import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../bloc/livekit/call_bloc.dart' as livekit_bloc;
import '../../bloc/livekit/call_event.dart';
import '../../bloc/livekit/call_state.dart' as livekit_bloc;
import '../../repository/call_livekit_repository.dart';
import '../../../../../core/di/injection_container.dart';

class LiveKitActiveCallScreen extends StatefulWidget {
  final String callId;
  final String roomName;
  final String token;
  final String livekitUrl;
  final String otherParticipantName;
  final bool isInitiator;

  const LiveKitActiveCallScreen({
    super.key,
    required this.callId,
    required this.roomName,
    required this.token,
    required this.livekitUrl,
    required this.otherParticipantName,
    required this.isInitiator,
  });

  @override
  State<LiveKitActiveCallScreen> createState() => _LiveKitActiveCallScreenState();
}

class _LiveKitActiveCallScreenState extends State<LiveKitActiveCallScreen> {
  Room? _room;
  bool _isMuted = false;
  bool _isConnected = false;
  int _callDuration = 0;
  Timer? _durationTimer;
  String? _errorMessage;
  bool _isEnded = false; 

  final CallLiveKitRepository _callRepository = sl<CallLiveKitRepository>();

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        setState(() {
          _errorMessage = 'Microphone permission denied';
        });
        return;
      }

      // Create LiveKit room
      _room = Room(
        roomOptions: RoomOptions(
          defaultAudioPublishOptions: AudioPublishOptions(
            dtx: true,
            red: true,
          ),
          defaultVideoPublishOptions: VideoPublishOptions(),
        ),
      );

      // Set up event listeners
      _setupRoomListeners();

      // Connect to room
      await _room!.connect(
        widget.livekitUrl,
        widget.token,
      );

      // Enable microphone
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      setState(() {
        _isConnected = true;
      });

      _startDurationTimer();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect: $e';
      });
    }
  }

  void _setupRoomListeners() {
    _room!.events.on<RoomConnectedEvent>((event) {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    });

    _room!.events.on<RoomDisconnectedEvent>((event) {
      if (mounted) {
        setState(() {
          _isConnected = false;
        });
        _stopDurationTimer();
        _navigateToEnded();
      }
    });

    _room!.events.on<ParticipantConnectedEvent>((event) {
      // Remote participant joined
    });

    _room!.events.on<ParticipantDisconnectedEvent>((event) {
      // Remote participant left - end call
      if (mounted && _isConnected) {
        _endCall();
      }
    });

    _room!.events.on<TrackSubscribedEvent>((event) {
      // Remote audio track subscribed - audio will play automatically
    });

    _room!.events.on<OnConnectionErrorEvent>((event) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: ${event.error}';
        });
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _callDuration = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callDuration++;
        });
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    if (_room == null) return;

    try {
      final newMuted = !_isMuted;
      await _room!.localParticipant?.setMicrophoneEnabled(!newMuted);
      setState(() {
        _isMuted = newMuted;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle mute: $e')),
        );
      }
    }
  }

    Future<void> _endCall() async {
    try {
      await _callRepository.endCall(widget.callId);
    } catch (e) {
      // Ignore backend error, still disconnect locally
    }

    if (_room != null) {
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(false);
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 100));
      try {
        await _room!.disconnect();
      } catch (_) {}
      _room = null;
    }

    _stopDurationTimer();

    _navigateToEnded();
  }

    void _navigateToEnded() {
    if (_isEnded) return;
    _isEnded = true;

    _stopDurationTimer();
    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      debugPrint('📞 _navigateToEnded: no page to pop — going to /board');
      try {
        GoRouter.of(context).go('/board');
      } catch (_) {
        navigator.maybePop();
      }
    }
  }

  @override
  void dispose() {
    _stopDurationTimer();
    if (_room != null) {
      _room!.localParticipant?.setMicrophoneEnabled(false);
      _room!.disconnect();
      _room = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _endCall();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _errorMessage != null
            ? _buildErrorView()
            : _buildCallView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCallView() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with call info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button (disabled during active call)
                IconButton(
                  onPressed: null,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                // Call info
                Column(
                  children: [
                    Text(
                      widget.otherParticipantName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _isConnected ? _formatDuration(_callDuration) : 'Connecting...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                // Placeholder for balance
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Connection status indicator
          if (!_isConnected)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Connecting...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Main call area
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 80,
                    backgroundColor: _isConnected ? Colors.green[700] : Colors.blue[700],
                    child: Text(
                      widget.otherParticipantName.isNotEmpty
                          ? widget.otherParticipantName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 56,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isConnected ? 'Connected' : 'Connecting...',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  if (_isConnected && _room != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _isMuted ? Colors.red : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isMuted ? 'Muted' : 'Unmuted',
                          style: TextStyle(
                            color: _isMuted ? Colors.red : Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom controls
          if (_isConnected)
            Padding(
              padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute/Unmute button
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    color: _isMuted ? Colors.orange : Colors.blue,
                    onPressed: _toggleMute,
                  ),
                  // End call button
                  _buildControlButton(
                    icon: Icons.call_end,
                    label: 'End Call',
                    color: Colors.red,
                    onPressed: _endCall,
                    size: 72,
                  ),
                ],
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    double size = 64,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}