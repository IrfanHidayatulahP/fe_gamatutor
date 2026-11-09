import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../bloc/livekit/call_bloc.dart' as livekit_bloc;
import '../../bloc/livekit/call_event.dart';
import '../../bloc/livekit/call_state.dart' as livekit_bloc;
import 'active_call_screen.dart';

class LiveKitOutgoingCallScreen extends StatefulWidget {
  final String calleeId;
  final String calleeName;

  const LiveKitOutgoingCallScreen({
    super.key,
    required this.calleeId,
    required this.calleeName,
  });

  @override
  State<LiveKitOutgoingCallScreen> createState() => _LiveKitOutgoingCallScreenState();
}

  

class _LiveKitOutgoingCallScreenState extends State<LiveKitOutgoingCallScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  void _safePopOrGoBoard(BuildContext context) {
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
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initiateCall();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initiateCall() async {
    context.read<livekit_bloc.CallBloc>().add(Initiate1on1CallEvent(widget.calleeId));
  }

  void _cancelCall() {
    context.read<livekit_bloc.CallBloc>().add(RejectCallEvent(''));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<livekit_bloc.CallBloc, livekit_bloc.CallState>(
      listener: (context, state) {
        // Navigate to ActiveCallScreen only when call is actually connected
        if (state is livekit_bloc.CallActiveState) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LiveKitActiveCallScreen(
                callId: state.callId,
                roomName: state.roomName,
                token: state.token ?? '',
                livekitUrl: state.livekitUrl ?? '',
                otherParticipantName: widget.calleeName,
                isInitiator: true,
              ),
            ),
          );
        } else if (state is livekit_bloc.CallEndedState) {
          _safePopOrGoBoard(context);
        } else if (state is livekit_bloc.CallErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          _safePopOrGoBoard(context);
        }
      },
      builder: (context, state) {
        final isRinging = state is livekit_bloc.CallRingingState && state.isOutgoing;
        final isConnecting = state is livekit_bloc.CallConnectingState;
        final showError = state is livekit_bloc.CallErrorState;

        String statusText;
        if (isRinging) {
          statusText = 'Calling...';
        } else if (isConnecting) {
          statusText = 'Connecting...';
        } else if (showError) {
          statusText = 'Error occurred';
        } else {
          statusText = 'Connecting...';
        }

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
                          scale: isRinging ? _pulseAnimation.value : 1.0,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: isRinging ? Colors.blue[700] : Colors.green[700],
                            child: Text(
                              widget.calleeName.isNotEmpty
                                  ? widget.calleeName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 48,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.calleeName,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      statusText,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    if (isRinging) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Ringing...',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              // Top bar with cancel/end button
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BlocBuilder<livekit_bloc.CallBloc, livekit_bloc.CallState>(
                      builder: (context, state) {
                        final isLoading = state is livekit_bloc.CallConnectingState;
                        final isRingingState = state is livekit_bloc.CallRingingState && state.isOutgoing;
                        return IconButton(
                          onPressed: isLoading || isRingingState
                              ? null
                              : _cancelCall,
                          icon: (isLoading || isRingingState)
                              ? const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.close, color: Colors.white, size: 28),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Cancel button at bottom when ringing
              if (isRinging)
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: _cancelCall,
                      icon: const Icon(Icons.call_end, color: Colors.white),
                      label: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}