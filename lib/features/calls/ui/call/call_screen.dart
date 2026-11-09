import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../bloc/call/call_bloc.dart';
import '../../bloc/call/call_event.dart';
import '../../bloc/call/call_state.dart';
import '../../data/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final bool isInitiator;

  const CallScreen({
    super.key,
    required this.callId,
    required this.isInitiator,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final WebRTCService _webRTCService = sl<WebRTCService>();

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  int _duration = 0;
  bool _showControls = true;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _webRTCService.onLocalStream = (stream) {
      if (mounted) setState(() {});
    };

    _webRTCService.onRemoteStream = (stream) {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    };

    _webRTCService.onCallEnded = (callId) {
      if (mounted) {
        context.read<CallBloc>().add(CallEnded(callId: callId));
      }
    };

    _webRTCService.onError = (message) {
      if (mounted) {
        context.read<CallBloc>().add(CallErrorOccurred(message: message));
      }
    };
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _duration++);
        _startDurationTimer();
      }
    });
  }

  @override
  void dispose() {
    _webRTCService.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    await _webRTCService.toggleMute();
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _toggleSpeaker() async {
    await _webRTCService.toggleSpeaker();
    setState(() => _isSpeakerOn = !_isSpeakerOn);
  }

  Future<void> _endCall() async {
    await _webRTCService.endCall();
    if (mounted) {
      context.read<CallBloc>().add(CallEnded(callId: widget.callId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallEndedState) {
          Navigator.pop(context);
        } else if (state is CallError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Main call area (audio-only)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: _isConnected ? Colors.green[700] : Colors.blue[700],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.isInitiator ? 'Calling...' : 'Incoming call',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isConnected ? _formatDuration(_duration) : 'Waiting for remote user...',
                        style: const TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      if (_isConnected) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isMuted ? Icons.mic_off : Icons.mic,
                              color: _isMuted ? Colors.red : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isMuted ? 'Muted' : 'Unmuted',
                              style: TextStyle(
                                color: _isMuted ? Colors.red : Colors.green,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Top bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                top: _showControls ? MediaQuery.of(context).padding.top : -100,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isInitiator ? 'Calling...' : 'Incoming call',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _toggleSpeaker,
                          icon: Icon(
                            _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom controls
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                bottom: _showControls ? MediaQuery.of(context).padding.bottom + 16 : -200,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: _isMuted ? Icons.mic_off : Icons.mic,
                          label: _isMuted ? 'Muted' : 'Mute',
                          color: _isMuted ? Colors.red : Colors.white,
                          onPressed: _toggleMute,
                        ),
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'End',
                          color: Colors.red,
                          onPressed: _endCall,
                          isEndCall: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Tap to toggle controls
              GestureDetector(
                onTap: () => setState(() => _showControls = !_showControls),
                child: Container(color: Theme.of(context).scaffoldBackgroundColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool isEndCall = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isEndCall ? 72 : 64,
          height: isEndCall ? 72 : 64,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isEndCall
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: isEndCall ? 32 : 28),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}