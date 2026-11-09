// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:cached_network_image/cached_network_image.dart';

// // import '../../../../core/di/injection_container.dart';
// // import '../bloc/collaborative_tasks_bloc.dart';
// // import '../bloc/collaborative_tasks_event.dart';
// // import '../bloc/collaborative_tasks_state.dart';
// // import '../data/collaborative_task_model.dart';
// // import '../../calls/ui/livekit/group_voice_sheet.dart';

// // class CollaborativeTasksScreen extends StatelessWidget {
// //   final bool showAppBar;
// //   const CollaborativeTasksScreen({super.key, this.showAppBar = true});

// //   @override
// //   Widget build(BuildContext context) {
// //     return BlocProvider(
// //       create: (context) =>
// //           sl<CollaborativeTasksBloc>()..add(LoadCollaborativeTasks()),
// //       child: CollaborativeTasksView(showAppBar: showAppBar),
// //     );
// //   }
// // }

// // class CollaborativeTasksView extends StatelessWidget {
// //   final bool showAppBar;
// //   const CollaborativeTasksView({super.key, this.showAppBar = true});

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: showAppBar
// //           ? AppBar(
// //               title: const Text('Collaborative Tasks'),
// //               actions: [
// //                 IconButton(
// //                   icon: const Icon(Icons.refresh),
// //                   onPressed: () => context.read<CollaborativeTasksBloc>().add(
// //                     RefreshCollaborativeTasks(),
// //                   ),
// //                   tooltip: 'Refresh',
// //                 ),
// //               ],
// //             )
// //           : null,
// //       body: BlocConsumer<CollaborativeTasksBloc, CollaborativeTasksState>(
// //         listener: (context, state) {
// //           if (state is CollaborativeTasksError) {
// //             ScaffoldMessenger.of(context)
// //                 .showSnackBar(SnackBar(content: Text(state.message)));
// //           }
// //         },
// //         builder: (context, state) {
// //           if (state is CollaborativeTasksLoading) {
// //             return const Center(child: CircularProgressIndicator());
// //           }

// //           if (state is CollaborativeTasksError) {
// //             return Center(
// //               child: Column(
// //                 mainAxisAlignment: MainAxisAlignment.center,
// //                 children: [
// //                   Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
// //                   const SizedBox(height: 16),
// //                   Text(
// //                     state.message,
// //                     style: TextStyle(color: Colors.red[600]),
// //                     textAlign: TextAlign.center,
// //                   ),
// //                   const SizedBox(height: 16),
// //                   ElevatedButton(
// //                     onPressed: () => context.read<CollaborativeTasksBloc>().add(
// //                       LoadCollaborativeTasks(),
// //                     ),
// //                     child: const Text('Retry'),
// //                   ),
// //                 ],
// //               ),
// //             );
// //           }

// //           if (state is CollaborativeTasksLoaded) {
// //             final tasks = state.tasks;

// //             if (tasks.isEmpty) {
// //               return Center(
// //                 child: Column(
// //                   mainAxisAlignment: MainAxisAlignment.center,
// //                   children: [
// //                     Icon(Icons.group_work, size: 64, color: Colors.grey[400]),
// //                     const SizedBox(height: 16),
// //                     Text(
// //                       'No collaborative tasks yet',
// //                       style: TextStyle(color: Colors.grey[600], fontSize: 16),
// //                     ),
// //                     const SizedBox(height: 8),
// //                     Text(
// //                       'Tasks you own or collaborate on will appear here',
// //                       style: TextStyle(color: Colors.grey[500], fontSize: 14),
// //                     ),
// //                   ],
// //                 ),
// //               );
// //             }

// //             return RefreshIndicator(
// //               onRefresh: () async {
// //                 context.read<CollaborativeTasksBloc>().add(
// //                   RefreshCollaborativeTasks(),
// //                 );
// //               },
// //               child: ListView.builder(
// //                 padding: const EdgeInsets.all(16),
// //                 itemCount: tasks.length,
// //                 itemBuilder: (context, index) {
// //                   final task = tasks[index];
// //                   return _CollaborativeTaskCard(task: task);
// //                 },
// //               ),
// //             );
// //           }

// //           return const SizedBox.shrink();
// //         },
// //       ),
// //     );
// //   }
// // }

// // class _CollaborativeTaskCard extends StatelessWidget {
// //   final CollaborativeTaskModel task;

// //   const _CollaborativeTaskCard({required this.task});

// //   @override
// //   Widget build(BuildContext context) {
// //     final hasActiveCall =
// //         task.activeGroupCall != null &&
// //         (task.activeGroupCall!.isActive || task.activeGroupCall!.isWaiting);

// //     return Card(
// //       margin: const EdgeInsets.only(bottom: 12),
// //       elevation: 2,
// //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
// //       child: Padding(
// //         padding: const EdgeInsets.all(16),
// //         child: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Row(
// //               crossAxisAlignment: CrossAxisAlignment.start,
// //               children: [
// //                 Expanded(
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: [
// //                       Text(
// //                         task.title,
// //                         style: Theme.of(context).textTheme.titleMedium
// //                             ?.copyWith(fontWeight: FontWeight.w600),
// //                       ),
// //                       if (task.courseName != null) ...[
// //                         const SizedBox(height: 4),
// //                         Text(
// //                           task.courseName!,
// //                           style: Theme.of(context).textTheme.bodySmall
// //                               ?.copyWith(color: Colors.grey[600]),
// //                         ),
// //                       ],
// //                     ],
// //                   ),
// //                 ),
// //                 Container(
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 10,
// //                     vertical: 4,
// //                   ),
// //                   decoration: BoxDecoration(
// //                     color: task.isOwner
// //                         ? Theme.of(context).colorScheme.primaryContainer
// //                         : Theme.of(context).colorScheme.secondaryContainer,
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                   child: Text(
// //                     task.isOwner ? 'Owner' : task.role.toUpperCase(),
// //                     style: TextStyle(
// //                       fontSize: 11,
// //                       fontWeight: FontWeight.w600,
// //                       color: task.isOwner
// //                           ? Theme.of(context).colorScheme.onPrimaryContainer
// //                           : Theme.of(context).colorScheme.onSecondaryContainer,
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //             const SizedBox(height: 12),
// //             Wrap(
// //               spacing: 12,
// //               runSpacing: 8,
// //               children: [
// //                 _buildMetaChip(
// //                   context,
// //                   icon: Icons.signal_cellular_alt,
// //                   label: task.difficultyLabel,
// //                   color: _difficultyColor(task.difficulty),
// //                 ),
// //                 _buildMetaChip(
// //                   context,
// //                   icon: Icons.priority_high,
// //                   label: task.priorityLabel,
// //                   color: _priorityColor(task.priority),
// //                 ),
// //                 if (task.deadline != null && task.deadline!.isNotEmpty)
// //                   _buildMetaChip(
// //                     context,
// //                     icon: Icons.calendar_today,
// //                     label: _formatDeadline(task.deadline!),
// //                     color: Colors.blue,
// //                   ),
// //               ],
// //             ),
// //             const SizedBox(height: 16),
// //             if (hasActiveCall) ...[
// //               Container(
// //                 padding: const EdgeInsets.all(12),
// //                 decoration: BoxDecoration(
// //                   color: task.activeGroupCall!.isActive
// //                       ? Colors.green.withValues(alpha: 0.1)
// //                       : Colors.orange.withValues(alpha: 0.1),
// //                   borderRadius: BorderRadius.circular(12),
// //                   border: Border.all(
// //                     color: task.activeGroupCall!.isActive
// //                         ? Colors.green.withValues(alpha: 0.3)
// //                         : Colors.orange.withValues(alpha: 0.3),
// //                   ),
// //                 ),
// //                 child: Row(
// //                   children: [
// //                     Icon(
// //                       Icons.mic,
// //                       color: task.activeGroupCall!.isActive
// //                           ? Colors.green
// //                           : Colors.orange,
// //                       size: 20,
// //                     ),
// //                     const SizedBox(width: 8),
// //                     Expanded(
// //                       child: Column(
// //                         crossAxisAlignment: CrossAxisAlignment.start,
// //                         children: [
// //                           Text(
// //                             task.activeGroupCall!.isActive
// //                                 ? 'Voice call active'
// //                                 : 'Call waiting',
// //                             style: TextStyle(
// //                               fontWeight: FontWeight.w600,
// //                               color: task.activeGroupCall!.isActive
// //                                   ? Colors.green[800]
// //                                   : Colors.orange[800],
// //                             ),
// //                           ),
// //                           Text(
// //                             '${task.activeGroupCall!.participantCount} participant${task.activeGroupCall!.participantCount != 1 ? 's' : ''}',
// //                             style: TextStyle(
// //                               fontSize: 12,
// //                               color: task.activeGroupCall!.isActive
// //                                   ? Colors.green[700]
// //                                   : Colors.orange[700],
// //                             ),
// //                           ),
// //                         ],
// //                       ),
// //                     ),
// //                     ElevatedButton.icon(
// //                       onPressed: () => _showGroupVoiceSheet(context),
// //                       icon: const Icon(Icons.call, size: 18),
// //                       label: const Text('Join'),
// //                       style: ElevatedButton.styleFrom(
// //                         backgroundColor: task.activeGroupCall!.isActive
// //                             ? Colors.green
// //                             : Colors.orange,
// //                         foregroundColor: Colors.white,
// //                         padding: const EdgeInsets.symmetric(
// //                           horizontal: 16,
// //                           vertical: 8,
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               ),
// //             ] else ...[
// //               SizedBox(
// //                 width: double.infinity,
// //                 child: ElevatedButton.icon(
// //                   onPressed: () => _showGroupVoiceSheet(context),
// //                   icon: const Icon(Icons.mic),
// //                   label: const Text('Start Voice Collaboration'),
// //                   style: ElevatedButton.styleFrom(
// //                     backgroundColor: Theme.of(context).colorScheme.primary,
// //                     foregroundColor: Colors.white,
// //                     padding: const EdgeInsets.symmetric(vertical: 14),
// //                     shape: RoundedRectangleBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                   ),
// //                 ),
// //               ),
// //             ],
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   Widget _buildMetaChip(
// //     BuildContext context, {
// //     required IconData icon,
// //     required String label,
// //     required Color color,
// //   }) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
// //       decoration: BoxDecoration(
// //         color: color.withValues(alpha: 0.1),
// //         borderRadius: BorderRadius.circular(8),
// //       ),
// //       child: Row(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(icon, size: 14, color: color),
// //           const SizedBox(width: 6),
// //           Text(
// //             label,
// //             style: TextStyle(
// //               fontSize: 12,
// //               fontWeight: FontWeight.w500,
// //               color: color,
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Color _difficultyColor(String difficulty) {
// //     switch (difficulty) {
// //       case 'easy':
// //         return Colors.green;
// //       case 'medium':
// //         return Colors.orange;
// //       case 'hard':
// //         return Colors.red;
// //       case 'expert':
// //         return Colors.deepOrange;
// //       default:
// //         return Colors.grey;
// //     }
// //   }

// //   Color _priorityColor(String priority) {
// //     switch (priority) {
// //       case 'low':
// //         return Colors.green;
// //       case 'medium':
// //         return Colors.orange;
// //       case 'high':
// //         return Colors.red;
// //       case 'critical':
// //         return Colors.deepOrange;
// //       default:
// //         return Colors.grey;
// //     }
// //   }

// //   String _formatDeadline(String deadline) {
// //     try {
// //       final date = DateTime.parse(deadline);
// //       return '${date.day}/${date.month}/${date.year}';
// //     } catch (_) {
// //       return deadline;
// //     }
// //   }

// //   void _showGroupVoiceSheet(BuildContext context) {
// //     showModalBottomSheet(
// //       context: context,
// //       isScrollControlled: true,
// //       useSafeArea: true,
// //       backgroundColor: Colors.transparent,
// //       builder: (sheetContext) =>
// //           GroupVoiceSheet(taskId: task.cardId, taskTitle: task.title),
// //     );
// //   }
// // }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../../../core/di/injection_container.dart';
// import '../../../../core/network/api_client.dart';
// import '../../../../core/network/websocket_manager.dart'; 
// import '../bloc/collaborative_tasks_bloc.dart';
// import '../bloc/collaborative_tasks_event.dart';
// import '../bloc/collaborative_tasks_state.dart';
// import '../data/collaborative_task_model.dart';
// import '../../calls/ui/livekit/group_voice_sheet.dart';

// class CollaborativeTasksScreen extends StatefulWidget {
//   final bool showAppBar;
//   const CollaborativeTasksScreen({super.key, this.showAppBar = true});

//   @override
//   State<CollaborativeTasksScreen> createState() => _CollaborativeTasksScreenState();
// }

// class _CollaborativeTasksScreenState extends State<CollaborativeTasksScreen> {
//   late CollaborativeTasksBloc _tasksBloc;
//   StreamSubscription? _wsSubscription;

//   @override
//   void initState() {
//     super.initState();
//     _tasksBloc = sl<CollaborativeTasksBloc>();
//     _tasksBloc.add(LoadCollaborativeTasks());
//     _setupWebSocketListener();
//   }

//   void _setupWebSocketListener() {
//     _wsSubscription = sl<WebSocketManager>().messageStream.listen((data) {
//       final event = data['event'];
//       if (event == 'group-call:ended' || event == 'group-call:user-joined' || event == 'group-call:user-left') {
//         _tasksBloc.add(RefreshCollaborativeTasks());
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _wsSubscription?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _tasksBloc,
//       child: CollaborativeTasksView(showAppBar: widget.showAppBar),
//     );
//   }
// }

// class CollaborativeTasksView extends StatelessWidget {
//   final bool showAppBar;
//   const CollaborativeTasksView({super.key, this.showAppBar = true});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: showAppBar
//           ? AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               title: const Text(
//                 'GROUP CALL',
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   letterSpacing: 1.0,
//                 ),
//               ),
//               centerTitle: true,
//               actions: [
//                 IconButton(
//                   icon: const Icon(Icons.more_vert, color: Colors.black87),
//                   onPressed: () {},
//                 ),
//               ],
//             )
//           : null,
//       body: BlocConsumer<CollaborativeTasksBloc, CollaborativeTasksState>(
//         listener: (context, state) {
//           if (state is CollaborativeTasksError) {
//             ScaffoldMessenger.of(context)
//                 .showSnackBar(SnackBar(content: Text(state.message)));
//           }
//         },
//         builder: (context, state) {
//           if (state is CollaborativeTasksLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (state is CollaborativeTasksError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
//                   const SizedBox(height: 16),
//                   Text(
//                     state.message,
//                     style: TextStyle(color: Colors.red[600]),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: () => context.read<CollaborativeTasksBloc>().add(
//                       LoadCollaborativeTasks(),
//                     ),
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             );
//           }

//           if (state is CollaborativeTasksLoaded) {
//             // Pindahkan logika pencarian ke dalam widget Stateful terpisah
//             // agar input text tidak me-rebuild seluruh layar, melainkan hanya list-nya saja.
//             return _SearchableTasksList(tasks: state.tasks);
//           }

//           return const SizedBox.shrink();
//         },
//       ),
//     );
//   }
// }

// // =========================================================
// // WIDGET BARU: Menangani State untuk Pencarian
// // =========================================================
// class _SearchableTasksList extends StatefulWidget {
//   final List<CollaborativeTaskModel> tasks;
//   const _SearchableTasksList({required this.tasks});

//   @override
//   State<_SearchableTasksList> createState() => _SearchableTasksListState();
// }

// class _SearchableTasksListState extends State<_SearchableTasksList> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Logika Filter
//     final filteredTasks = widget.tasks.where((task) {
//       final titleMatch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
//       final courseMatch = (task.courseName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
//       return titleMatch || courseMatch;
//     }).toList();

//     return RefreshIndicator(
//       onRefresh: () async {
//         context.read<CollaborativeTasksBloc>().add(RefreshCollaborativeTasks());
//       },
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Text(
//               'Aktivitas Diskusi',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
//             ),
//           ),
          
//           // Search Bar Fungsional
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF3F4F6),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: (value) {
//                   setState(() {
//                     _searchQuery = value;
//                   });
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'Cari grup...',
//                   hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
//                   prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
//                   suffixIcon: _searchQuery.isNotEmpty 
//                       ? IconButton(
//                           icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
//                           onPressed: () {
//                             _searchController.clear();
//                             setState(() {
//                               _searchQuery = '';
//                             });
//                           },
//                         )
//                       : null,
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//               ),
//             ),
//           ),
          
//           // Tabs (Visual saja)

//           // List yang sudah difilter
//           Expanded(
//             child: filteredTasks.isEmpty
//                 ? Center(
//                     child: Text(
//                       'Grup tidak ditemukan',
//                       style: TextStyle(color: Colors.grey.shade500),
//                     ),
//                   )
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                     itemCount: filteredTasks.length,
//                     itemBuilder: (context, index) {
//                       final task = filteredTasks[index];
//                       return _CollaborativeTaskCard(task: task);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterTab(String label, {int badgeCount = 0, bool isSelected = false}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: isSelected ? Colors.white : Colors.transparent,
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(
//           color: isSelected ? const Color(0xFF6366F1) : Colors.grey.shade300,
//           width: 1.5,
//         ),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: isSelected ? const Color(0xFF6366F1) : Colors.grey[600],
//               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//               fontSize: 13,
//             ),
//           ),
//           if (badgeCount > 0) ...[
//             const SizedBox(width: 6),
//             Container(
//               padding: const EdgeInsets.all(5),
//               decoration: const BoxDecoration(
//                 color: Color(0xFF6366F1),
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 '$badgeCount',
//                 style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ]
//         ],
//       ),
//     );
//   }
// }

// extension on String {
//   toLowerCase() {}
// }

// // =========================================================
// // CARD (SAMA SEPERTI SEBELUMNYA)
// // =========================================================
// class _CollaborativeTaskCard extends StatelessWidget {
//   final CollaborativeTaskModel task;

//   const _CollaborativeTaskCard({required this.task});

//   @override
//   Widget build(BuildContext context) {
//     final hasActiveCall = task.activeGroupCall != null &&
//         (task.activeGroupCall!.isActive || task.activeGroupCall!.isWaiting);

//     return Card(
//       elevation: 0,
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//         side: BorderSide(
//           color: hasActiveCall ? Colors.green.shade300 : Colors.grey.shade200,
//           width: hasActiveCall ? 1.5 : 1.0,
//         ),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(16),
//         onTap: () => _showTaskDetailPopup(context),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Icon(Icons.assignment, color: Colors.redAccent, size: 18),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       task.title,
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   if (hasActiveCall)
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.green.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(Icons.phone_in_talk, color: Colors.green, size: 12),
//                           SizedBox(width: 4),
//                           Text(
//                             'In Calling',
//                             style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   SizedBox(
//                     width: 50,
//                     height: 24,
//                     child: Stack(
//                       children: [
//                         _buildAvatar(0, Colors.grey.shade200),
//                         _buildAvatar(14, Colors.blue.shade100),
//                         _buildAvatar(28, Colors.orange.shade100),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       '${task.courseName ?? "Umum"} dan lainnya',
//                       style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                   Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: hasActiveCall ? Colors.green : const Color(0xFFEEF2FF),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.call, 
//                       color: hasActiveCall ? Colors.white : const Color(0xFF6366F1), 
//                       size: 20
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAvatar(double left, Color bgColor) {
//     return Positioned(
//       left: left,
//       child: CircleAvatar(
//         radius: 12,
//         backgroundColor: bgColor,
//         child: const Icon(Icons.person, size: 14, color: Colors.grey),
//       ),
//     );
//   }

//   void _showTaskDetailPopup(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (sheetContext) {
//         return Container(
//           height: MediaQuery.of(context).size.height * 0.75,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Colors.black54),
//                       onPressed: () => Navigator.pop(sheetContext),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(Icons.shield, size: 64, color: Colors.redAccent.shade100),
//               const SizedBox(height: 16),
//               Text(
//                 task.title,
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 'Detail Group',
//                 style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//               ),
//               const SizedBox(height: 24),
//               Expanded(
//                 child: FutureBuilder<Map<String, dynamic>?>(
//                   future: _fetchCardCollaborators(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return const Center(child: CircularProgressIndicator());
//                     }

//                     if (snapshot.hasError) {
//                       return Center(
//                         child: Text(
//                           'Gagal memuat anggota',
//                           style: TextStyle(color: Colors.grey.shade600),
//                         ),
//                       );
//                     }

//                     final cardData = snapshot.data;
//                     final collaborations = cardData?['collaborations'] as List<dynamic>? ?? [];
//                     final owner = cardData?['user'];

//                     final List<Map<String, dynamic>> allMembers = [];
//                     if (owner != null) {
//                       allMembers.add({
//                         'name': '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim(),
//                         'isOwner': true,
//                       });
//                     }
//                     for (var collab in collaborations) {
//                       if (collab['user'] != null) {
//                         allMembers.add({
//                           'name': '${collab['user']['firstName'] ?? ''} ${collab['user']['lastName'] ?? ''}'.trim(),
//                           'isOwner': false,
//                         });
//                       }
//                     }

//                     if (allMembers.isEmpty) {
//                       return Center(
//                         child: Text(
//                           'Belum ada anggota',
//                           style: TextStyle(color: Colors.grey.shade500),
//                         ),
//                       );
//                     }

//                     return ListView.separated(
//                       padding: const EdgeInsets.symmetric(horizontal: 24),
//                       itemCount: allMembers.length,
//                       separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
//                       itemBuilder: (context, index) {
//                         final member = allMembers[index];
//                         final isOnline = index % 2 == 0; 
                        
//                         return _buildParticipantTile(
//                           member['name'] ?? 'Unknown', 
//                           isOnline ? 'Online' : 'Offline', 
//                           isOnline,
//                           isOwner: member['isOwner'],
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton.icon(
//                     onPressed: () {
//                       Navigator.pop(sheetContext);
//                       showModalBottomSheet(
//                         context: context,
//                         isScrollControlled: true,
//                         useSafeArea: true,
//                         backgroundColor: Colors.transparent,
//                         builder: (voiceContext) =>
//                             GroupVoiceSheet(taskId: task.cardId, taskTitle: task.title),
//                       );
//                     },
//                     icon: const Icon(Icons.call, color: Colors.white),
//                     label: const Text(
//                       'GROUP CALL',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF6366F1),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Future<Map<String, dynamic>?> _fetchCardCollaborators() async {
//     try {
//       final response = await sl<ApiClient>().get<Map<String, dynamic>>('/cards/${task.cardId}');
//       if (response.statusCode == 200 && response.data != null) {
//         if (response.data!['card'] != null) {
//           return response.data!['card'] as Map<String, dynamic>;
//         }
//         return response.data;
//       }
//     } catch (e) {
//       debugPrint('Gagal mengambil data card: $e');
//     }
//     return null;
//   }

//   Widget _buildParticipantTile(String name, String status, bool isOnline, {bool isOwner = false}) {
//     return ListTile(
//       contentPadding: EdgeInsets.zero,
//       leading: CircleAvatar(
//         radius: 24,
//         backgroundColor: Colors.grey.shade200,
//         child: const Icon(Icons.person, color: Colors.grey),
//       ),
//       title: Row(
//         children: [
//           Text(
//             name,
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//           ),
//           if (isOwner) ...[
//             const SizedBox(width: 4),
//             const Icon(Icons.star, color: Colors.amber, size: 16),
//           ],
//         ],
//       ),
//       subtitle: Row(
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(
//               color: isOnline ? Colors.green : Colors.grey,
//               shape: BoxShape.circle,
//             ),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             status,
//             style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_manager.dart'; 
import '../bloc/collaborative_tasks_bloc.dart';
import '../bloc/collaborative_tasks_event.dart';
import '../bloc/collaborative_tasks_state.dart';
import '../data/collaborative_task_model.dart';
import '../../calls/ui/livekit/group_voice_sheet.dart';

class CollaborativeTasksScreen extends StatefulWidget {
  final bool showAppBar;
  const CollaborativeTasksScreen({super.key, this.showAppBar = true});

  @override
  State<CollaborativeTasksScreen> createState() => _CollaborativeTasksScreenState();
}

class _CollaborativeTasksScreenState extends State<CollaborativeTasksScreen> {
  late CollaborativeTasksBloc _tasksBloc;
  StreamSubscription? _wsSubscription;

  @override
  void initState() {
    super.initState();
    _tasksBloc = sl<CollaborativeTasksBloc>();
    _tasksBloc.add(LoadCollaborativeTasks());
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    _wsSubscription = sl<WebSocketManager>().messageStream.listen((data) {
      final event = data['event'];
      if (event == 'group-call:ended' || event == 'group-call:user-joined' || event == 'group-call:user-left') {
        _tasksBloc.add(RefreshCollaborativeTasks());
      }
    });
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _tasksBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _tasksBloc,
      child: CollaborativeTasksView(showAppBar: widget.showAppBar),
    );
  }
}

class CollaborativeTasksView extends StatelessWidget {
  final bool showAppBar;
  const CollaborativeTasksView({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'GROUP CALL',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black87),
                  onPressed: () => context.read<CollaborativeTasksBloc>().add(RefreshCollaborativeTasks()),
                ),
              ],
            )
          : null,
      body: BlocConsumer<CollaborativeTasksBloc, CollaborativeTasksState>(
        listener: (context, state) {
          if (state is CollaborativeTasksError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is CollaborativeTasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CollaborativeTasksError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.red[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CollaborativeTasksBloc>().add(
                      LoadCollaborativeTasks(),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CollaborativeTasksLoaded) {
            if (state.tasks.isEmpty) {
              return const Center(
                child: Text('Belum ada tugas kolaborasi', style: TextStyle(color: Colors.grey)),
              );
            }
            return _SearchableTasksList(tasks: state.tasks);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SearchableTasksList extends StatefulWidget {
  final List<CollaborativeTaskModel> tasks;
  const _SearchableTasksList({required this.tasks});

  @override
  State<_SearchableTasksList> createState() => _SearchableTasksListState();
}

class _SearchableTasksListState extends State<_SearchableTasksList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = widget.tasks.where((task) {
      final titleMatch = task.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final courseMatch = (task.courseName ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return titleMatch || courseMatch;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CollaborativeTasksBloc>().add(RefreshCollaborativeTasks());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Aktivitas Diskusi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari grup...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredTasks.isEmpty
                ? Center(
                    child: Text(
                      'Grup tidak ditemukan',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return _CollaborativeTaskCard(task: task);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  toLowerCase() {}
}

class _CollaborativeTaskCard extends StatelessWidget {
  final CollaborativeTaskModel task;

  const _CollaborativeTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final hasActiveCall = task.activeGroupCall != null &&
        (task.activeGroupCall!.isActive || task.activeGroupCall!.isWaiting);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hasActiveCall ? Colors.green.shade300 : Colors.grey.shade200,
          width: hasActiveCall ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showTaskDetailPopup(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasActiveCall)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.phone_in_talk, color: Colors.green, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'In Calling',
                            style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(
                    width: 50,
                    height: 24,
                    child: Stack(
                      children: [
                        _buildAvatar(0, Colors.grey.shade200),
                        _buildAvatar(14, Colors.blue.shade100),
                        _buildAvatar(28, Colors.orange.shade100),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${task.courseName ?? "Umum"} dan lainnya',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasActiveCall ? Colors.green : const Color(0xFFEEF2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.call, 
                      color: hasActiveCall ? Colors.white : const Color(0xFF6366F1), 
                      size: 20
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(double left, Color bgColor) {
    return Positioned(
      left: left,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: bgColor,
        child: const Icon(Icons.person, size: 14, color: Colors.grey),
      ),
    );
  }

  void _showTaskDetailPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              Icon(Icons.shield, size: 64, color: Colors.redAccent.shade100),
              const SizedBox(height: 16),
              Text(
                task.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Detail Group',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: _fetchCardCollaborators(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Gagal memuat anggota',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    final cardData = snapshot.data;
                    final collaborations = cardData?['collaborations'] as List<dynamic>? ?? [];
                    final owner = cardData?['user'];

                    final List<Map<String, dynamic>> allMembers = [];
                    if (owner != null) {
                      allMembers.add({
                        'name': '${owner['firstName'] ?? ''} ${owner['lastName'] ?? ''}'.trim(),
                        'isOwner': true,
                      });
                    }
                    for (var collab in collaborations) {
                      if (collab['user'] != null) {
                        allMembers.add({
                          'name': '${collab['user']['firstName'] ?? ''} ${collab['user']['lastName'] ?? ''}'.trim(),
                          'isOwner': false,
                        });
                      }
                    }

                    if (allMembers.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada anggota',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: allMembers.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final member = allMembers[index];
                        final isOnline = index % 2 == 0; 
                        
                        return _buildParticipantTile(
                          member['name'] ?? 'Unknown', 
                          isOnline ? 'Online' : 'Offline', 
                          isOnline,
                          isOwner: member['isOwner'],
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (voiceContext) =>
                            GroupVoiceSheet(taskId: task.cardId, taskTitle: task.title),
                      );
                    },
                    icon: const Icon(Icons.call, color: Colors.white),
                    label: const Text(
                      'GROUP CALL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<Map<String, dynamic>?> _fetchCardCollaborators() async {
    try {
      final response = await sl<ApiClient>().get<Map<String, dynamic>>('/cards/${task.cardId}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data!['card'] != null) {
          return response.data!['card'] as Map<String, dynamic>;
        }
        return response.data;
      }
    } catch (e) {
      debugPrint('Gagal mengambil data card: $e');
    }
    return null;
  }

  Widget _buildParticipantTile(String name, String status, bool isOnline, {bool isOwner = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey.shade200,
        child: const Icon(Icons.person, color: Colors.grey),
      ),
      title: Row(
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          if (isOwner) ...[
            const SizedBox(width: 4),
            const Icon(Icons.star, color: Colors.amber, size: 16),
          ],
        ],
      ),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}