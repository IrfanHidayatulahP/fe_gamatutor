import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../bloc/call/call_bloc.dart';
import '../../bloc/call/call_event.dart';
import '../../bloc/call/call_state.dart';
import '../../repository/call_repository.dart';
import 'call_screen.dart';
import '../../../../../features/auth/bloc/auth_bloc.dart';
import '../../../../../features/auth/bloc/auth_state.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callId;
  final String callerId;
  final String callerName;
  final Function(String?)? onClosed;

  const IncomingCallScreen({
    super.key,
    required this.callId,
    required this.callerId,
    required this.callerName,
    this.onClosed,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  final CallRepository _callRepository = sl<CallRepository>();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    // Emit ringing state for incoming call (isOutgoing: false)
    context.read<CallBloc>().add(CallIncoming(
      callId: widget.callId,
      callerId: widget.callerId,
      callerName: widget.callerName,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    widget.onClosed?.call(widget.callId);
    super.dispose();
  }

  Future<void> _answerCall() async {
    try {
      await _callRepository.answerCall(callId: widget.callId, signalingData: {});
      if (mounted) {
        context.read<CallBloc>().add(CallAnswered(
          callId: widget.callId,
        ));
      }
    } catch (e) {
      if (mounted) {
        context.read<CallBloc>().add(CallErrorOccurred(message: e.toString()));
      }
    }
  }

  Future<void> _rejectCall() async {
    try {
      await _callRepository.rejectCall(widget.callId);
      if (mounted) {
        context.read<CallBloc>().add(CallEnded(callId: widget.callId));
      }
    } catch (e) {
      if (mounted) {
        context.read<CallBloc>().add(CallErrorOccurred(message: e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallState>(
      listener: (context, state) {
        // Navigate to CallScreen when connected
        if (state is CallConnected) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CallScreen(
                callId: state.callId,
                isInitiator: state.isInitiator,
              ),
            ),
          );
        } else if (state is CallEndedState) {
          Navigator.pop(context);
        } else if (state is CallError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        // Check if we're in incoming ringing state
        final isIncomingRinging = state is CallRingingState && !state.isOutgoing;

        return Scaffold(
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
                          scale: isIncomingRinging ? _pulseAnimation.value : 1.0,
                          child: CircleAvatar(
                            radius: 70,
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
                    Text(
                      isIncomingRinging
                          ? 'Incoming voice call...'
                          : 'Connecting...',
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 48),
                    if (isIncomingRinging) ...[
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
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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