import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../bloc/group_call/group_call_bloc.dart';
import '../../bloc/group_call/group_call_event.dart';
import '../../bloc/group_call/group_call_state.dart';
import '../../repository/group_call_repository.dart';
import '../../data/group_call_webrtc_service.dart';

class GroupCallScreen extends StatefulWidget {
  final String groupCallId;

  const GroupCallScreen({
    super.key,
    required this.groupCallId,
  });

  @override
  State<GroupCallScreen> createState() => _GroupCallScreenState();
}

class _GroupCallScreenState extends State<GroupCallScreen>
    with TickerProviderStateMixin {
  final GroupCallWebRTCService _webRTCService = sl<GroupCallWebRTCService>();
  final GroupCallRepository _repository = sl<GroupCallRepository>();

  // Audio-only: track participants as a list of user IDs
  final Set<String> _remoteParticipants = {};

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
    context.read<GroupCallBloc>().add(JoinGroupCall(
      groupCallId: widget.groupCallId,
    ));
  }

  void _setupCallbacks() {
    _webRTCService.onLocalStream = (stream) {
      if (mounted) setState(() {});
    };

    _webRTCService.onRemoteStreamAdded = (userId, stream) {
      if (mounted) {
        setState(() {
          _remoteParticipants.add(userId);
          _isConnected = true;
        });
      }
    };

    _webRTCService.onRemoteStreamRemoved = (userId) {
      if (mounted) {
        setState(() {
          _remoteParticipants.remove(userId);
        });
      }
    };

    _webRTCService.onParticipantJoined = (userId) {
      if (mounted) setState(() {});
    };

    _webRTCService.onParticipantLeft = (userId) {
      if (mounted) setState(() {});
    };

    _webRTCService.onCallEnded = (groupCallId) {
      if (mounted) {
        context.read<GroupCallBloc>().add(GroupCallErrorOccurred(message: 'Call ended'));
      }
    };

    _webRTCService.onError = (message) {
      if (mounted) {
        context.read<GroupCallBloc>().add(GroupCallErrorOccurred(message: message));
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

  Future<void> _leaveCall() async {
    await _webRTCService.leaveGroupCall();
    await _repository.leaveGroupCall(widget.groupCallId);
    if (mounted) {
      context.read<GroupCallBloc>().add(LeaveGroupCall(groupCallId: widget.groupCallId));
      Navigator.pop(context);
    }
  }

  Future<void> _endCall() async {
    await _webRTCService.leaveGroupCall();
    await _repository.endGroupCall(widget.groupCallId);
    if (mounted) {
      context.read<GroupCallBloc>().add(EndGroupCall(groupCallId: widget.groupCallId));
      Navigator.pop(context);
    }
  }

  List<String> _getParticipantIds() {
    final ids = <String>[];
    ids.add('local');
    ids.addAll(_remoteParticipants);
    return ids;
  }

  Widget _buildAudioTile({
    required String userId,
    required String label,
    required bool isLocal,
    bool isMuted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
        color: isLocal ? Colors.blue[900] : Colors.grey[900],
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isLocal ? Colors.blue[700] : Colors.green[700],
              child: Text(
                label.isNotEmpty ? label[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMuted) ...[
                  const Icon(Icons.mic_off, color: Colors.red, size: 18),
                  const SizedBox(width: 4),
                  const Text('Muted', style: TextStyle(color: Colors.red, fontSize: 12)),
                ] else ...[
                  const Icon(Icons.mic, color: Colors.green, size: 18),
                  const SizedBox(width: 4),
                  const Text('Unmuted', style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupCallBloc, GroupCallState>(
      listener: (context, state) {
        if (state is GroupCallEnded) {
          Navigator.pop(context);
        } else if (state is GroupCallError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final participantIds = _getParticipantIds();
        final participantCount = participantIds.length;

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Participant grid (audio-only)
              if (participantCount > 0)
                LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount;
                    if (participantCount == 1) crossAxisCount = 1;
                    else if (participantCount == 2) crossAxisCount = 2;
                    else if (participantCount <= 4) crossAxisCount = 2;
                    else if (participantCount <= 6) crossAxisCount = 3;
                    else crossAxisCount = 4;

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: participantCount,
                      itemBuilder: (context, index) {
                        final userId = participantIds[index];
                        if (userId == 'local') {
                          return _buildAudioTile(
                            userId: userId,
                            label: 'You',
                            isLocal: true,
                            isMuted: _isMuted,
                          );
                        } else {
                          return _buildAudioTile(
                            userId: userId,
                            label: 'User ${userId.substring(0, userId.length > 4 ? 4 : userId.length)}',
                            isLocal: false,
                          );
                        }
                      },
                    );
                  },
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.blue),
                      const SizedBox(height: 16),
                      const Text(
                        'Joining group call...',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ],
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
                              'Group Voice Call',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$participantCount participants  •  ${_formatDuration(_duration)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _toggleSpeaker,
                              icon: Icon(
                                _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                // Show participants list
                              },
                              icon: const Icon(Icons.people, color: Colors.white, size: 28),
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
                          label: 'Leave',
                          color: Colors.red,
                          onPressed: _leaveCall,
                          isEndCall: true,
                        ),
                        _buildControlButton(
                          icon: Icons.screen_share,
                          label: 'Share',
                          color: Colors.white,
                          onPressed: () {
                            // Screen sharing
                          },
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
    bool isEnabled = true,
  }) {
    if (!isEnabled) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white38, size: 28),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      );
    }

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