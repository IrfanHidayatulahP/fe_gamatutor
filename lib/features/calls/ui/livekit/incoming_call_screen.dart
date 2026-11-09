import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/livekit/call_bloc.dart' as livekit_bloc;
import '../../bloc/livekit/call_event.dart';
import '../../bloc/livekit/call_state.dart' as livekit_bloc;
import '../../repository/call_livekit_repository.dart';
import '../../../../../core/di/injection_container.dart';
import 'active_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final String token;
  final String roomName;
  final String livekitUrl;
  final Function(String?)? onClosed;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    required this.token,
    required this.roomName,
    required this.livekitUrl,
    this.onClosed,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  final CallLiveKitRepository _callRepository = sl<CallLiveKitRepository>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAnswering = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.onClosed?.call(widget.callId);
    super.dispose();
  }

  Future<void> _answerCall() async {
    if (_isAnswering) return;
    setState(() => _isAnswering = true);

    try {
      // Call API to accept call and get LiveKit token
      final call = await _callRepository.acceptCall(widget.callId);

      if (!mounted) return;

      // Navigate to active call screen with callee's token
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveKitActiveCallScreen(
            callId: widget.callId,
            roomName: call.roomName,
            token: call.token,
            livekitUrl: call.livekitUrl,
            otherParticipantName: widget.callerName,
            isInitiator: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to answer call: $e')),
        );
        setState(() => _isAnswering = false);
      }
    }
  }

    Future<void> _rejectCall() async {
    if (_isRejecting) return;
    setState(() => _isRejecting = true);

    try {
      await _callRepository.endCall(widget.callId);
    } catch (e) {
      // Ignore error
    }

    if (!mounted) return;

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      try {
        GoRouter.of(context).go('/board');
      } catch (_) {
        navigator.maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button during incoming call
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Back button pressed - treat as reject
          debugPrint('📞 Back button pressed on incoming call, rejecting');
          _rejectCall();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.green[700],
                          child: Text(
                            widget.callerName.isNotEmpty
                                ? widget.callerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 56,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    widget.callerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Incoming audio call...',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 48),
                  if (!_isAnswering && !_isRejecting) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Reject button
                        _buildActionButton(
                          icon: Icons.call_end,
                          label: 'Decline',
                          color: Colors.red,
                          onPressed: _rejectCall,
                        ),
                        const SizedBox(width: 48),
                        // Answer button
                        _buildActionButton(
                          icon: Icons.call,
                          label: 'Accept',
                          color: Colors.green,
                          onPressed: _answerCall,
                        ),
                      ],
                    ),
                  ] else ...[
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      _isAnswering ? 'Answering...' : 'Declining...',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
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
            icon: Icon(icon, color: Colors.white, size: 32),
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