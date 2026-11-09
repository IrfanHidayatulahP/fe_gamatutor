import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../bloc/group_call/group_call_bloc.dart';
import '../../bloc/group_call/group_call_event.dart';
import '../../bloc/group_call/group_call_state.dart';
import '../../repository/group_call_repository.dart';
import 'group_call_screen.dart';
import '../../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../../features/auth/bloc/auth_state.dart';

class GroupCallLobbyScreen extends StatefulWidget {
  final String? groupCallId;
  final String title;
  final bool isHost;
  final int maxParticipants;

  const GroupCallLobbyScreen({
    super.key,
    this.groupCallId,
    required this.title,
    this.isHost = true,
    this.maxParticipants = 10,
  });

  @override
  State<GroupCallLobbyScreen> createState() => _GroupCallLobbyScreenState();
}

class _GroupCallLobbyScreenState extends State<GroupCallLobbyScreen> {
  final GroupCallRepository _repository = sl<GroupCallRepository>();
  bool _isCreating = false;
  bool _isJoining = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.groupCallId == null && widget.isHost) {
      _createGroupCall();
    }
  }

  Future<void> _createGroupCall() async {
    setState(() {
      _isCreating = true;
      _error = null;
    });

    try {
      final groupCall = await _repository.createGroupCall(
        title: widget.title,
        type: 'audio', // Voice-only app
        maxParticipants: widget.maxParticipants,
      );

      if (mounted && groupCall != null) {
        context.read<GroupCallBloc>().add(HandleGroupCallInvite(groupCall: groupCall));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GroupCallScreen(
              groupCallId: groupCall.groupCallId,
            ),
          ),
        );
      } else if (mounted) {
        setState(() {
          _error = 'Failed to create group call';
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _joinGroupCall() async {
    if (widget.groupCallId == null) return;

    setState(() {
      _isJoining = true;
      _error = null;
    });

    try {
      final groupCall = await _repository.joinGroupCall(widget.groupCallId!);

      if (mounted && groupCall != null) {
        context.read<GroupCallBloc>().add(HandleGroupCallInvite(groupCall: groupCall));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GroupCallScreen(
              groupCallId: groupCall.groupCallId,
            ),
          ),
        );
      } else if (mounted) {
        setState(() {
          _error = 'Failed to join group call';
          _isJoining = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon/logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.call,
                  size: 48,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                widget.isHost ? 'Create a new group call' : 'Join group call',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 32),

              // Settings preview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.mic,
                              color: Colors.blue,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Voice Call',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white70, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Max ${widget.maxParticipants} participants',
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Error message
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_error != null) const SizedBox(height: 16),

              // Action buttons
              Column(
                children: [
                  if (widget.isHost)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createGroupCall,
                        icon: _isCreating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.call, size: 24),
                        label: Text(
                          _isCreating
                              ? 'Creating...'
                              : 'Start Voice Call',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _isJoining ? null : _joinGroupCall,
                        icon: _isJoining
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.login, size: 24),
                        label: Text(
                          _isJoining ? 'Joining...' : 'Join Call',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Cancel button
                  TextButton(
                    onPressed: (_isCreating || _isJoining) ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Tips for better call quality',
                          style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('Use headphones to prevent echo'),
                    _buildTip('Ensure stable internet connection'),
                    _buildTip('Grant microphone permissions'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 13)),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}