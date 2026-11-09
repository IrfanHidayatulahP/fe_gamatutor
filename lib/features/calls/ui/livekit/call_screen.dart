import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../bloc/livekit/call_bloc.dart' as livekit_bloc;
import '../../bloc/livekit/call_event.dart';
import '../../bloc/livekit/call_state.dart' as livekit_bloc;
import '../../repository/livekit_audio_service.dart' as livekit;

class LiveKitCallScreen extends StatefulWidget {
  final String callId;
  final bool isInitiator;

  const LiveKitCallScreen({
    super.key,
    required this.callId,
    required this.isInitiator,
  });

  @override
  State<LiveKitCallScreen> createState() => _LiveKitCallScreenState();
}

class _LiveKitCallScreenState extends State<LiveKitCallScreen> {
  final livekit.LiveKitAudioService _liveKitService = livekit.LiveKitAudioService();
  int _duration = 0;
  bool _showControls = true;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _startDurationTimer();
    _setupCallbacks();
  }

  void _setupCallbacks() {
    _liveKitService.onConnected = () {
      if (mounted) setState(() {});
    };

    _liveKitService.onDisconnected = () {
      if (mounted) {
        context.read<livekit_bloc.CallBloc>().add(const LeaveCallEvent());
      }
    };

    _liveKitService.onConnectionError = (error) {
      if (mounted) {
        context.read<livekit_bloc.CallBloc>().add(OnConnectionErrorEvent(error));
      }
    };

    _liveKitService.onActiveSpeakersChanged = (speakers) {
      if (mounted) setState(() {});
    };

    _liveKitService.onParticipantConnected = (participant) {
      if (mounted) setState(() {});
    };

    _liveKitService.onParticipantDisconnected = (participant) {
      if (mounted) setState(() {});
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

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _toggleMute() async {
    await _liveKitService.setMicrophoneEnabled(!_isMuted);
    setState(() => _isMuted = !_isMuted);
  }

  Future<void> _endCall() async {
    await _liveKitService.leaveRoom();
    if (mounted) {
      context.read<livekit_bloc.CallBloc>().add(const LeaveCallEvent());
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _liveKitService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<livekit_bloc.CallBloc, livekit_bloc.CallState>(
      listener: (context, state) {
        if (state is livekit_bloc.CallEndedState) {
          Navigator.pop(context);
        } else if (state is livekit_bloc.CallErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        if (state is livekit_bloc.CallActiveState) {
          final localParticipant = state.participants.firstWhere(
            (p) => p.isLocal,
            orElse: () => state.participants.first,
          );
          _isMuted = localParticipant.isMuted;

          return _buildCallUI(state);
        }

        return _buildConnectingUI();
      },
    );
  }

  Widget _buildCallUI(livekit_bloc.CallActiveState state) {
    final remoteParticipants = state.participants.where((p) => !p.isLocal).toList();
    final activeSpeakerId = state.activeSpeakerId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content - show active speaker or grid of participants
          if (remoteParticipants.isNotEmpty) ...[
            if (activeSpeakerId != null)
              Positioned.fill(
                child: _buildActiveSpeakerView(activeSpeakerId, state.participants),
              )
            else
              Positioned.fill(
                child: _buildGridView(state.participants, state.activeSpeakerId),
              ),
          ] else ...[
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white38,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Waiting for participants...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],

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
                    _buildControlButton(
                      icon: Icons.volume_up,
                      label: 'Speaker',
                      color: Colors.white,
                      onPressed: () {}, // TODO: implement speaker toggle
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
  }

  Widget _buildActiveSpeakerView(String activeSpeakerId, List<livekit_bloc.CallParticipant> participants) {
    final activeParticipant = participants.firstWhere(
      (p) => p.participantId == activeSpeakerId,
      orElse: () => participants.firstWhere((p) => !p.isLocal),
    );

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 80,
            backgroundColor: Colors.blue[700],
            child: Text(
              activeParticipant.userName.isNotEmpty
                  ? activeParticipant.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 64,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            activeParticipant.userName,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (activeParticipant.isSpeaking) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.record_voice_over, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Speaking...',
                  style: TextStyle(color: Colors.green[300], fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridView(List<livekit_bloc.CallParticipant> participants, String? activeSpeakerId) {
    final remoteParticipants = participants.where((p) => !p.isLocal).toList();

    if (remoteParticipants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: Colors.white38),
            const SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: remoteParticipants.length,
      itemBuilder: (context, index) {
        final participant = remoteParticipants[index];
        final isActiveSpeaker = participant.participantId == activeSpeakerId;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isActiveSpeaker
                ? Border.all(color: Colors.blue, width: 3)
                : Border.all(color: Colors.grey[700]!, width: 1),
            color: isActiveSpeaker
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.grey[900],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue[700],
                child: Text(
                  participant.userName.isNotEmpty
                      ? participant.userName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                participant.userName,
                style: TextStyle(
                  color: isActiveSpeaker ? Colors.blue : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (participant.isMuted)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic_off, color: Colors.red[300], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Muted',
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectingUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Connecting...',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
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