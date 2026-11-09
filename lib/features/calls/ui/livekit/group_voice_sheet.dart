// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:gamatutor_kanban/core/di/injection_container.dart';
// import 'package:gamatutor_kanban/core/network/websocket_manager.dart';
// import 'package:gamatutor_kanban/features/calls/repository/livekit_audio_service.dart'
//     as livekit_audio;
// import 'package:go_router/go_router.dart';
// import 'package:livekit_client/livekit_client.dart';

// import '../../../../core/di/injection_container.dart';
// import '../../../../core/network/websocket_manager.dart';

// import '../../bloc/livekit/call_bloc.dart';
// import '../../bloc/livekit/call_event.dart';
// import '../../bloc/livekit/call_state.dart';

// class GroupVoiceSheet extends StatelessWidget {
//   final String taskId;
//   final String taskTitle;

//   const GroupVoiceSheet({
//     super.key,
//     required this.taskId,
//     required this.taskTitle,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: context.read<CallBloc>(),
//       child: GroupVoiceSheetContent(taskId: taskId, taskTitle: taskTitle),
//     );
//   }
// }

// class GroupVoiceSheetContent extends StatefulWidget {
//   final String taskId;
//   final String taskTitle;

//   const GroupVoiceSheetContent({
//     super.key,
//     required this.taskId,
//     required this.taskTitle,
//   });

//   @override
//   State<GroupVoiceSheetContent> createState() => _GroupVoiceSheetContentState();
// }

// // class _GroupVoiceSheetContentState extends State<GroupVoiceSheetContent> {
// //   bool _hasJoined = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     // Auto-join when sheet opens
// //     Future.microtask(() {
// //       if (!_hasJoined && mounted) {
// //         _hasJoined = true;
// //         context.read<CallBloc>().add(JoinGroupVoiceEvent(widget.taskId));
// //       }
// //     });
// //   }

// //   @override
// //   void dispose() {
// //     // Only auto-leave if we actually joined and call is still active
// //     if (_hasJoined) {
// //       final bloc = context.read<CallBloc>();
// //       final state = bloc.state;
// //       if (state is! CallIdleState && state is! CallEndedState && state is! CallErrorState) {
// //         bloc.add(const LeaveCallEvent());
// //       }
// //     }
// //     super.dispose();
// //   }

// class _GroupVoiceSheetContentState extends State<GroupVoiceSheetContent> {
//   bool _hasJoined = false;
//   StreamSubscription? _wsSubscription;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       if (!_hasJoined && mounted) {
//         _hasJoined = true;
//         context.read<CallBloc>().add(JoinGroupVoiceEvent(widget.taskId));
//       }
//     });

//     // Dengarkan event group-call:ended
//     _wsSubscription = sl<WebSocketManager>().messageStream.listen((data) {
//       final event = data['event'];
//       if (event == 'group-call:ended') {
//         _handleCallEnded();
//       }
//     });
//   }

//   void _handleCallEnded() {
//     if (!mounted) return;
//     debugPrint('📞 Panggilan diakhiri oleh host. Memutus koneksi LiveKit...');

//     // 1. Putus koneksi LiveKit
//     sl<livekit_audio.LiveKitAudioService>().leaveRoom();

//     // 2. Beritahu BLoC untuk cleanup
//     context.read<CallBloc>().add(const LeaveCallEvent());

//     // 3. Tutup BottomSheet
//     if (Navigator.of(context).canPop()) {
//       Navigator.of(context).pop();
//     } else {
//       context.go('/board');
//     }

//     // 4. Kasih notifikasi ke user
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Panggilan diakhiri oleh host')),
//     );
//   }

//   @override
//   void dispose() {
//     _wsSubscription?.cancel();
//     if (_hasJoined) {
//       final bloc = context.read<CallBloc>();
//       final state = bloc.state;
//       if (state is! CallIdleState &&
//           state is! CallEndedState &&
//           state is! CallErrorState) {
//         bloc.add(const LeaveCallEvent());
//       }
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.6,
//       minChildSize: 0.4,
//       maxChildSize: 0.9,
//       expand: false,
//       builder: (context, scrollController) {
//         return BlocConsumer<CallBloc, CallState>(
//           listener: (context, state) {
//             if (state is CallErrorState) {
//               ScaffoldMessenger.of(context)
//                   .showSnackBar(SnackBar(content: Text(state.message)));
//             }
//           },
//           builder: (context, state) {
//             return Container(
//               decoration: BoxDecoration(
//                 color: Theme.of(context).scaffoldBackgroundColor,
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(20),
//                 ),
//               ),
//               child: Column(
//                 children: [
//                   // Handle bar
//                   Container(
//                     margin: const EdgeInsets.symmetric(vertical: 12),
//                     width: 40,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[400],
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),

//                   // Header
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Voice Collaboration',
//                                 style: Theme.of(context).textTheme.titleMedium
//                                     ?.copyWith(fontWeight: FontWeight.w600),
//                               ),
//                               Text(
//                                 widget.taskTitle,
//                                 style: Theme.of(context).textTheme.bodySmall
//                                     ?.copyWith(color: Colors.grey[600]),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (state is CallActiveState)
//                           _buildMuteButton(context, state),
//                         if (state is CallActiveState)
//                           _buildLeaveButton(context),
//                         if (state is CallActiveState && state.isHost)
//                           _buildEndCallButton(context),
//                       ],
//                     ),
//                   ),

//                   const Divider(height: 1),

//                   // Participants grid
//                   Expanded(
//                     child: _buildParticipantsView(state, scrollController),
//                   ),

//                   // Bottom bar with call status
//                   if (state is CallConnectingState) _buildConnectingBar(),
//                   if (state is CallRingingState)
//                     _buildRingingBar(context, state),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildParticipantsView(
//     CallState state,
//     ScrollController scrollController,
//   ) {
//     if (state is CallActiveState) {
//       final participants = state.participants;

//       if (participants.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.mic_off, size: 64, color: Colors.grey[400]),
//               const SizedBox(height: 16),
//               Text(
//                 'Waiting for participants...',
//                 style: TextStyle(color: Colors.grey[600], fontSize: 16),
//               ),
//             ],
//           ),
//         );
//       }

//       return GridView.builder(
//         controller: scrollController,
//         padding: const EdgeInsets.all(16),
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 3,
//           childAspectRatio: 0.85,
//           crossAxisSpacing: 12,
//           mainAxisSpacing: 12,
//         ),
//         itemCount: participants.length,
//         itemBuilder: (context, index) {
//           final participant = participants[index];
//           final isActiveSpeaker =
//               state.activeSpeakerId == participant.participantId;

//           return _buildParticipantTile(participant, isActiveSpeaker);
//         },
//       );
//     }

//     if (state is CallConnectingState) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             Text(
//               'Connecting to voice room...',
//               style: TextStyle(color: Colors.grey[600]),
//             ),
//           ],
//         ),
//       );
//     }

//     if (state is CallErrorState) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
//             const SizedBox(height: 16),
//             Text(
//               state.message,
//               style: TextStyle(color: Colors.red[600]),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () => context.read<CallBloc>().add(
//                 JoinGroupVoiceEvent(widget.taskId),
//               ),
//               child: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.mic, size: 64, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'Tap to join voice collaboration',
//             style: TextStyle(color: Colors.grey[600], fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildParticipantTile(
//     CallParticipant participant,
//     bool isActiveSpeaker,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         border: isActiveSpeaker
//             ? Border.all(color: Theme.of(context).colorScheme.primary, width: 3)
//             : Border.all(color: Colors.grey[300]!, width: 1),
//         color: isActiveSpeaker
//             ? Theme.of(context).colorScheme.primaryContainer
//                   .withValues(alpha: 0.3)
//             : null,
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // Avatar with speaking indicator
//           Stack(
//             alignment: Alignment.bottomRight,
//             children: [
//               CircleAvatar(
//                 radius: 36,
//                 backgroundColor: Theme.of(context).colorScheme.primaryContainer,
//                 backgroundImage: participant.userAvatar != null
//                     ? CachedNetworkImageProvider(participant.userAvatar!)
//                     : null,
//                 child: participant.userAvatar == null
//                     ? Text(
//                         participant.userName.isNotEmpty
//                             ? participant.userName[0].toUpperCase()
//                             : '?',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Theme.of(context)
//                               .colorScheme
//                               .onPrimaryContainer,
//                         ),
//                       )
//                     : null,
//               ),
//               // Speaking indicator
//               if (participant.isSpeaking && !participant.isLocal)
//                 Container(
//                   width: 16,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     color: Colors.green,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                 ),
//               // Muted indicator
//               if (participant.isMuted && participant.isLocal)
//                 Container(
//                   width: 16,
//                   height: 16,
//                   decoration: BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.white, width: 2),
//                   ),
//                   child: const Icon(
//                     Icons.mic_off,
//                     size: 10,
//                     color: Colors.white,
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           // Name
//           Text(
//             participant.userName,
//             style: TextStyle(
//               fontWeight: FontWeight.w500,
//               fontSize: 13,
//               color: isActiveSpeaker
//                   ? Theme.of(context).colorScheme.primary
//                   : Theme.of(context).textTheme.bodyMedium?.color,
//             ),
//             textAlign: TextAlign.center,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 2),
//           // Status
//           Text(
//             participant.isLocal
//                 ? 'You'
//                 : (participant.isMuted ? 'Muted' : 'Connected'),
//             style: TextStyle(fontSize: 11, color: Colors.grey[600]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMuteButton(BuildContext context, CallActiveState state) {
//     final localParticipant = state.participants.firstWhere(
//       (p) => p.isLocal,
//       orElse: () => state.participants.first,
//     );

//     return IconButton(
//       onPressed: () {
//         context.read<CallBloc>().add(
//           ToggleMicrophoneEvent(!localParticipant.isMuted),
//         );
//       },
//       icon: Icon(
//         localParticipant.isMuted ? Icons.mic_off : Icons.mic,
//         color: localParticipant.isMuted
//             ? Colors.red
//             : Theme.of(context).colorScheme.primary,
//       ),
//       style: IconButton.styleFrom(
//         backgroundColor: localParticipant.isMuted
//             ? Colors.red.withValues(alpha: 0.1)
//             : Theme.of(context).colorScheme.primaryContainer,
//       ),
//     );
//   }

//   Widget _buildLeaveButton(BuildContext context) {
//     return IconButton(
//       onPressed: () {
//         context.read<CallBloc>().add(const LeaveCallEvent());
//         Navigator.pop(context);
//       },
//       icon: const Icon(Icons.call_end),
//       style: IconButton.styleFrom(
//         backgroundColor: Colors.red.withValues(alpha: 0.1),
//         foregroundColor: Colors.red,
//       ),
//     );
//   }

//   Widget _buildEndCallButton(BuildContext context) {
//     return IconButton(
//       onPressed: () => _showEndCallConfirmDialog(context),
//       icon: const Icon(Icons.stop_circle),
//       style: IconButton.styleFrom(
//         backgroundColor: Colors.red.withValues(alpha: 0.1),
//         foregroundColor: Colors.red,
//       ),
//       tooltip: 'End call for everyone',
//     );
//   }

//   void _showEndCallConfirmDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         title: const Text('End Call for Everyone?'),
//         content: const Text(
//           'This will disconnect all participants and end the group voice call.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(dialogContext);
//               final callBloc = context.read<CallBloc>();
//               // 👇 PASTIKAN MEMANGGIL END GROUP CALL
//               callBloc.add(EndGroupCallEvent(callBloc.currentCallId ?? ''));
//               Navigator.pop(context);
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text(
//               'End Call',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildConnectingBar() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const SizedBox(
//             width: 20,
//             height: 20,
//             child: CircularProgressIndicator(strokeWidth: 2),
//           ),
//           const SizedBox(width: 12),
//           Text('Connecting...', style: TextStyle(color: Colors.grey[600])),
//         ],
//       ),
//     );
//   }

//   Widget _buildRingingBar(BuildContext context, CallRingingState state) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               'Incoming call from ${state.callerName}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               context.read<CallBloc>().add(RejectCallEvent(state.callId));
//             },
//             child: const Text('Decline'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               context.read<CallBloc>().add(AcceptCallEvent(state.callId));
//             },
//             child: const Text('Accept'),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/websocket_manager.dart';
import '../../repository/livekit_audio_service.dart' as livekit_audio;

import '../../bloc/livekit/call_bloc.dart';
import '../../bloc/livekit/call_event.dart';
import '../../bloc/livekit/call_state.dart';

class GroupVoiceSheet extends StatelessWidget {
  final String taskId;
  final String taskTitle;

  const GroupVoiceSheet({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<CallBloc>(),
      child: GroupVoiceSheetContent(taskId: taskId, taskTitle: taskTitle),
    );
  }
}

class GroupVoiceSheetContent extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const GroupVoiceSheetContent({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<GroupVoiceSheetContent> createState() => _GroupVoiceSheetContentState();
}

class _GroupVoiceSheetContentState extends State<GroupVoiceSheetContent> {
  bool _hasJoined = false;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!_hasJoined && mounted) {
        _hasJoined = true;
        context.read<CallBloc>().add(JoinGroupVoiceEvent(widget.taskId));
      }
    });

    _wsSubscription = sl<WebSocketManager>().messageStream.listen((data) {
      final event = data['event'];
      if (event == 'group-call:ended') {
        _handleCallEnded();
      }
    });
  }

  void _handleCallEnded() {
    if (!mounted) return;
    sl<livekit_audio.LiveKitAudioService>().leaveRoom();
    context.read<CallBloc>().add(const LeaveCallEvent());

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/board');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Panggilan diakhiri oleh host')),
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    if (_hasJoined) {
      final bloc = context.read<CallBloc>();
      final state = bloc.state;
      if (state is! CallIdleState &&
          state is! CallEndedState &&
          state is! CallErrorState) {
        bloc.add(const LeaveCallEvent());
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tema gelap sesuai referensi
    final theme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF161A2B), // Warna background navy gelap
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6B7CFF),
        surface: Color(0xFF1E243D),
      ),
    );

    return Theme(
      data: theme,
      child: DraggableScrollableSheet(
        initialChildSize: 1.0, // Full screen seperti desain
        minChildSize: 1.0,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) {
          return BlocConsumer<CallBloc, CallState>(
            listener: (context, state) {
              if (state is CallErrorState) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
            builder: (context, state) {
              return Container(
                color: theme.scaffoldBackgroundColor,
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildCustomAppBar(context, state),
                      const SizedBox(height: 16),
                      if (state is CallActiveState)
                        _buildRoomHeader(state),
                      const SizedBox(height: 24),
                      Expanded(
                        child: _buildParticipantsView(state, scrollController),
                      ),
                      if (state is CallActiveState)
                        _buildBottomControls(context, state),
                      if (state is CallConnectingState) _buildConnectingBar(),
                      if (state is CallRingingState)
                        _buildRingingBar(context, state),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 1. Custom App Bar (Back, Title, Options)
  Widget _buildCustomAppBar(BuildContext context, CallState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context), // Atau aksi minimize
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          const Text(
            'GROUP CALL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            onPressed: () {}, // Opsi tambahan
            icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Room Header (Info Task & Tombol Keluar)
  Widget _buildRoomHeader(CallActiveState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E243D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_up, color: Color(0xFF6B7CFF), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.taskTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${state.participants.length} anggota sedang berbicara',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Tombol Keluar
            TextButton(
              onPressed: () {
                context.read<CallBloc>().add(const LeaveCallEvent());
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.2),
                foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Participants Grid
  Widget _buildParticipantsView(CallState state, ScrollController scrollController) {
    if (state is CallActiveState) {
      final participants = state.participants;

      return GridView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: participants.length + 1, // +1 untuk tombol Undang
        itemBuilder: (context, index) {
          if (index == participants.length) {
            return _buildInviteButton();
          }
          final participant = participants[index];
          final isActiveSpeaker = state.activeSpeakerId == participant.participantId;
          return _buildParticipantTile(participant, isActiveSpeaker);
        },
      );
    }

    if (state is CallConnectingState) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6B7CFF)),
            const SizedBox(height: 16),
            Text(
              'Menghubungkan ke ruang suara...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mic, size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'Ketuk untuk bergabung',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantTile(CallParticipant participant, bool isActiveSpeaker) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActiveSpeaker ? const Color(0xFF00E5FF) : Colors.transparent, // Cyan jika speak
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF1E243D),
                backgroundImage: participant.userAvatar != null
                    ? CachedNetworkImageProvider(participant.userAvatar!)
                    : null,
                child: participant.userAvatar == null
                    ? Text(
                        participant.userName.isNotEmpty
                            ? participant.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            // Indikator Audio
            if (!participant.isMuted)
              Container(
                margin: const EdgeInsets.only(right: 4, bottom: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isActiveSpeaker ? const Color(0xFF00E5FF) : Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF161A2B), width: 2),
                ),
                child: const Icon(Icons.mic, size: 10, color: Colors.black),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 4, bottom: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF161A2B), width: 2),
                ),
                child: const Icon(Icons.mic_off, size: 10, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          participant.isLocal ? 'Kamu' : participant.userName,
          style: TextStyle(
            color: isActiveSpeaker ? const Color(0xFF00E5FF) : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInviteButton() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            color: Colors.white.withValues(alpha: 0.02),
          ),
          child: const Icon(Icons.add, color: Colors.white54, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          'Undang',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // 4. Bottom Controls
  Widget _buildBottomControls(BuildContext context, CallActiveState state) {
    final localParticipant = state.participants.firstWhere(
      (p) => p.isLocal,
      orElse: () => state.participants.first,
    );
    final isHost = state.isHost;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161A2B),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Column(
        children: [
          // Info Sedang Dibahas (Optional sesuai gambar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E243D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sedang dibahas', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                      Text(widget.taskTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
              ],
            ),
          ),
          
          // Baris Tombol Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: localParticipant.isMuted ? Icons.mic_off : Icons.mic,
                label: 'Mute',
                isActive: !localParticipant.isMuted,
                onTap: () {
                  context.read<CallBloc>().add(ToggleMicrophoneEvent(!localParticipant.isMuted));
                },
              ),
              _buildActionButton(
                icon: Icons.volume_up,
                label: 'Speaker',
                isActive: true,
                onTap: () {},
              ),
              _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                isActive: false,
                onTap: () {},
              ),
              
              // Tombol End Call Khusus Host (Merah)
              if (isHost)
                _buildEndCallButton()
              else
                _buildActionButton(
                  icon: Icons.call_end,
                  label: 'Leave',
                  isRed: true,
                  onTap: () {
                    context.read<CallBloc>().add(const LeaveCallEvent());
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    bool isActive = false,
    bool isRed = false,
    required VoidCallback onTap,
  }) {
    Color bgColor = const Color(0xFF1E243D);
    Color iconColor = Colors.white;

    if (isRed) {
      bgColor = Colors.red;
    } else if (isActive) {
      bgColor = const Color(0xFF28315C);
      iconColor = const Color(0xFF6B7CFF);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEndCallButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _showEndCallConfirmDialog(context),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        const Text('End Call', style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  void _showEndCallConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E243D),
        title: const Text('Akhiri Panggilan?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Ini akan memutus semua peserta dan mengakhiri panggilan grup.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final callBloc = context.read<CallBloc>();
              // Memanggil fungsi untuk End Call ke semua peserta
              callBloc.add(EndGroupCallEvent(callBloc.currentCallId ?? ''));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Akhiri', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B7CFF)),
          ),
          const SizedBox(width: 12),
          Text('Menghubungkan...', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ],
      ),
    );
  }

  Widget _buildRingingBar(BuildContext context, CallRingingState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E243D),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Panggilan masuk dari ${state.callerName}',
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<CallBloc>().add(RejectCallEvent(state.callId));
            },
            child: const Text('Tolak', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CallBloc>().add(AcceptCallEvent(state.callId));
            },
            child: const Text('Terima'),
          ),
        ],
      ),
    );
  }
}