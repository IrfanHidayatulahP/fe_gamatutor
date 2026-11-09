// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';

// import '../bloc/board_bloc.dart';
// import '../bloc/board_event.dart';
// import '../bloc/board_state.dart';
// import '../data/board_model.dart';
// import '../data/column_model.dart';
// import '../../notification/ui/notification_badge.dart';
// import '../../../../core/navigation/call_navigation_service.dart';
// import 'collaborative_tasks_screen.dart'; // Import halaman kolaborasi

// class BoardScreen extends StatefulWidget {
//   const BoardScreen({super.key});

//   @override
//   State<BoardScreen> createState() => _BoardScreenState();
// }

// class _BoardScreenState extends State<BoardScreen> {
//   final List<String> _columnOrder = ['planning', 'monitoring', 'controlling', 'reflection'];
//   final Map<String, String> _columnTitles = {
//     'planning': 'Planning',
//     'monitoring': 'Monitoring',
//     'controlling': 'Controlling',
//     'reflection': 'Reflection',
//   };
//   final Map<String, IconData> _columnIcons = {
//     'planning': Icons.calendar_today_outlined,
//     'monitoring': Icons.visibility_outlined,
//     'controlling': Icons.tune_outlined,
//     'reflection': Icons.psychology_outlined,
//   };
//   final Map<String, Color> _columnColors = {
//     'planning': Colors.blue,
//     'monitoring': Colors.orange,
//     'controlling': Colors.purple,
//     'reflection': Colors.green,
//   };

//   @override
//   void initState() {
//     super.initState();
//     context.read<BoardBloc>().add(const LoadBoard());

//     // Trigger deferred call navigation check after first frame
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (mounted) {
//         CallNavigationService.checkAndNavigateToCall();
//       }
//     });
//   }

//   void _showFabMenu(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               margin: const EdgeInsets.only(bottom: 16),
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             Text(
//               'Tambah Baru',
//               style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//             ),
//             const SizedBox(height: 16),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.primaryContainer,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   Icons.add_card,
//                   color: Theme.of(context).colorScheme.onPrimaryContainer,
//                 ),
//               ),
//               title: const Text('Add Card'),
//               subtitle: const Text('Buat kartu baru (Coming soon)'),
//               onTap: () {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Add Card - Coming soon')),
//                 );
//               },
//             ),
//             ListTile(
//               leading: Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.primaryContainer,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Icon(
//                   Icons.people,
//                   color: Theme.of(context).colorScheme.onPrimaryContainer,
//                 ),
//               ),
//               title: const Text('Collaboration'),
//               subtitle: const Text('Buka layar kolaborasi'),
//               onTap: () {
//                 Navigator.pop(context);
//                 context.go('/collaboration');
//               },
//             ),
//             const SizedBox(height: 8),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Board'),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           // TOMBOL UNTUK MASUK KE COLLABORATIVE KANBAN
//           IconButton(
//             icon: const Icon(Icons.people_outline, color: Colors.black87),
//             tooltip: 'Collaborative Kanban',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const CollaborativeTasksScreen(),
//                 ),
//               );
//             },
//           ),
//           const NotificationIconButton(),
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => context.read<BoardBloc>().add(const LoadBoard()),
//           ),
//         ],
//       ),
//       body: BlocConsumer<BoardBloc, BoardState>(
//         listener: (context, state) {
//           if (state is BoardError) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text(state.message)),
//             );
//           }
//         },
//         builder: (context, state) {
//           if (state is BoardLoading) {
//             return _buildSkeletonLoader();
//           }

//           if (state is BoardError) {
//             return _buildErrorState(state.message);
//           }

//           if (state is BoardLoaded) {
//             final board = state.board;
//             final columns = state.columns.columns;

//             if (board.totalCards == 0) {
//               return _buildEmptyState();
//             }

//             return RefreshIndicator(
//               onRefresh: () async {
//                 context.read<BoardBloc>().add(const LoadBoard());
//               },
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: _columnOrder.map((columnId) {
//                     final columnData = columns.firstWhere(
//                       (c) => c.id == columnId,
//                       orElse: () => ColumnModel(
//                         id: columnId,
//                         title: _columnTitles[columnId] ?? columnId,
//                         order: _columnOrder.indexOf(columnId),
//                       ),
//                     );
//                     final cards = board.getCardsForColumn(columnId);
//                     return Expanded(
//                       child: _buildColumn(
//                         columnId: columnId,
//                         columnTitle: columnData.title,
//                         columnIcon: _columnIcons[columnId] ?? Icons.circle,
//                         columnColor: _columnColors[columnId] ?? Colors.grey,
//                         cards: cards,
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             );
//           }

//           return _buildEmptyState();
//         },
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showFabMenu(context),
//         icon: const Icon(Icons.add),
//         label: const Text('Tambah'),
//       ),
//     );
//   }

//   Widget _buildSkeletonLoader() {
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: _columnOrder.map((columnId) {
//           return Expanded(
//             child: _buildSkeletonColumn(columnId),
//           );
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildSkeletonColumn(String columnId) {
//     return Card(
//       margin: const EdgeInsets.only(right: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   width: 24,
//                   height: 24,
//                   decoration: BoxDecoration(
//                     color: _columnColors[columnId]?.withValues(alpha: 0.1) ?? Colors.grey[200],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Container(
//                     height: 20,
//                     color: Colors.grey[200],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             ListView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               itemCount: 3,
//               itemBuilder: (context, index) => _buildSkeletonCard(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSkeletonCard() {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               height: 16,
//               width: double.infinity,
//               color: Colors.grey[200],
//             ),
//             const SizedBox(height: 8),
//             Container(
//               height: 12,
//               width: 100,
//               color: Colors.grey[200],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     height: 20,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Container(
//                     height: 20,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(4),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.primaryContainer,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.dashboard_outlined,
//                 size: 60,
//                 color: Theme.of(context).colorScheme.onPrimaryContainer,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'Belum ada board',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: Theme.of(context).colorScheme.onSurface,
//                   ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Mulai buat board pertama Anda untuk mengelola tugas dan kolaborasi dengan tim.',
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                   ),
//             ),
//             const SizedBox(height: 32),
//             FilledButton.icon(
//               onPressed: () => _showFabMenu(context),
//               icon: const Icon(Icons.add),
//               label: const Text('Buat Board Baru'),
//               style: FilledButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState(String message) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Theme.of(context).colorScheme.errorContainer,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.error_outline,
//                 size: 60,
//                 color: Theme.of(context).colorScheme.onErrorContainer,
//               ),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               'Gagal Memuat Board',
//               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
//                     fontWeight: FontWeight.w600,
//                     color: Theme.of(context).colorScheme.onSurface,
//                   ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Theme.of(context).colorScheme.onSurfaceVariant,
//                   ),
//             ),
//             const SizedBox(height: 32),
//             FilledButton.icon(
//               onPressed: () => context.read<BoardBloc>().add(const LoadBoard()),
//               icon: const Icon(Icons.refresh),
//               label: const Text('Coba Lagi'),
//               style: FilledButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildColumn({
//     required String columnId,
//     required String columnTitle,
//     required IconData columnIcon,
//     required Color columnColor,
//     required List<BoardCard> cards,
//   }) {
//     return Card(
//       margin: const EdgeInsets.only(right: 12),
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: columnColor.withValues(alpha: 0.2),
//             width: 1.5,
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Column header
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: columnColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Icon(
//                     columnIcon,
//                     color: columnColor,
//                     size: 20,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     columnTitle,
//                     style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                           color: columnColor,
//                         ),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: columnColor.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     '${cards.length}',
//                     style: TextStyle(
//                       color: columnColor,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             // Cards list
//             if (cards.isEmpty)
//               Center(
//                 child: Padding(
//                   padding: const EdgeInsets.all(24),
//                   child: Column(
//                     children: [
//                       Icon(
//                         Icons.add_circle_outline,
//                         size: 32,
//                         color: Colors.grey[400],
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         'Kosong',
//                         style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                               color: Colors.grey[500],
//                             ),
//                       ),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: cards.length,
//                 itemBuilder: (context, index) => _buildCard(cards[index], columnColor),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCard(BoardCard card, Color columnColor) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 1,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: columnColor.withValues(alpha: 0.2),
//           width: 1,
//         ),
//       ),
//       child: InkWell(
//         borderRadius: BorderRadius.circular(12),
//         onTap: () {
//           context.read<BoardBloc>().add(SelectCard(card: card));
//           // TODO: Navigate to card detail
//         },
//         child: Padding(
//           padding: const EdgeInsets.all(12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 card.title,
//                 style: Theme.of(context).textTheme.titleSmall?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   _buildChip(
//                     label: card.difficultyLabel,
//                     color: _getDifficultyColor(card.difficulty),
//                     icon: Icons.trending_up,
//                   ),
//                   const SizedBox(width: 8),
//                   _buildChip(
//                     label: card.priorityLabel,
//                     color: card.priorityColor,
//                     icon: Icons.priority_high,
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               if (card.cardList?.learningStrat != null)
//                 _buildChip(
//                   label: card.cardList!.learningStrat!.strategyLabel,
//                   color: Theme.of(context).colorScheme.primary,
//                   icon: Icons.psychology_outlined,
//                   isLarge: true,
//                 ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   Icon(
//                     Icons.calendar_today_outlined,
//                     size: 14,
//                     color: Colors.grey[500],
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     _formatDeadline(card.deadline),
//                     style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                           color: Colors.grey[600],
//                         ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildChip({
//     required String label,
//     required Color color,
//     required IconData icon,
//     bool isLarge = false,
//   }) {
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: isLarge ? 10 : 8,
//         vertical: isLarge ? 6 : 4,
//       ),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(isLarge ? 8 : 6),
//         border: Border.all(color: color.withValues(alpha: 0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, size: isLarge ? 14 : 12, color: color),
//           const SizedBox(width: 4),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontWeight: FontWeight.w600,
//               fontSize: isLarge ? 12 : 10,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Color _getDifficultyColor(String difficulty) {
//     switch (difficulty) {
//       case 'easy':
//         return Colors.green;
//       case 'medium':
//         return Colors.orange;
//       case 'hard':
//         return Colors.red;
//       case 'expert':
//         return Colors.deepPurple;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _formatDeadline(String deadline) {
//     try {
//       final date = DateTime.parse(deadline);
//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);
//       final deadlineDate = DateTime(date.year, date.month, date.day);
//       final diff = deadlineDate.difference(today).inDays;

//       if (diff < 0) {
//         return 'Terlambat ${(-diff)} hari';
//       } else if (diff == 0) {
//         return 'Hari ini';
//       } else if (diff == 1) {
//         return 'Besok';
//       } else if (diff <= 7) {
//         return '$diff hari lagi';
//       } else {
//         return '${date.day}/${date.month}/${date.year}';
//       }
//     } catch (_) {
//       return deadline;
//     }
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/board_bloc.dart';
import '../bloc/board_event.dart';
import '../bloc/board_state.dart';
import '../data/board_model.dart';
import '../data/column_model.dart';
import '../../notification/ui/notification_badge.dart';
import '../../../../core/navigation/call_navigation_service.dart';
import 'collaborative_tasks_screen.dart'; 
import '../../../../core/network/websocket_manager.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final List<String> _columnOrder = ['planning', 'monitoring', 'controlling', 'reflection'];
  final Map<String, String> _columnTitles = {
    'planning': 'Planning',
    'monitoring': 'Monitoring',
    'controlling': 'Controlling',
    'reflection': 'Reflection',
  };
  final Map<String, IconData> _columnIcons = {
    'planning': Icons.calendar_today_outlined,
    'monitoring': Icons.visibility_outlined,
    'controlling': Icons.tune_outlined,
    'reflection': Icons.psychology_outlined,
  };
  final Map<String, Color> _columnColors = {
    'planning': Colors.blue,
    'monitoring': Colors.orange,
    'controlling': Colors.purple,
    'reflection': Colors.green,
  };

  StreamSubscription? _wsSubscription;
  bool _isWaitingForFocusApproval = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Tab: Pribadi & Kolaborasi
    context.read<BoardBloc>().add(const LoadBoard());
    _setupWebSocketListener();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        CallNavigationService.checkAndNavigateToCall();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wsSubscription?.cancel();
    super.dispose();
  }

  void _setupWebSocketListener() {
    _wsSubscription = sl<WebSocketManager>().messageStream.listen((data) {
      final event = data['event'];
      
      if (event == 'focus:request_received') {
        _showFocusRequestDialog(data);
      } else if (event == 'focus:approved') {
        if (_isWaitingForFocusApproval && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isWaitingForFocusApproval = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesi fokus disetujui oleh ${data['responderName']}!'),
            backgroundColor: Colors.green,
          ),
        );
        context.read<BoardBloc>().add(const LoadBoard());
      } else if (event == 'focus:rejected') {
        if (_isWaitingForFocusApproval && mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _isWaitingForFocusApproval = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sesi fokus ditolak oleh ${data['responderName']}.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _showFocusRequestDialog(Map<String, dynamic> data) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permintaan Sesi Fokus'),
          content: Text('${data['requesterName']} ingin memulai sesi fokus untuk tugas "${data['cardTitle']}". Apakah Anda setuju?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _respondFocus(data['cardId'], 'reject');
              },
              child: const Text('Tolak', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _respondFocus(data['cardId'], 'accept');
              },
              child: const Text('Setujui'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _respondFocus(String cardId, String action) async {
    try {
      await sl<ApiClient>().post('/cards/$cardId/respond-focus', data: {'action': action});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal merespon: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _requestFocusSession(String cardId) async {
    try {
      final response = await sl<ApiClient>().post('/cards/$cardId/request-focus');
      
      if (response.statusCode == 200) {
        final waiting = response.data['waiting'] as bool? ?? false;
        
        if (waiting) {
          _isWaitingForFocusApproval = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Expanded(child: Text("Menunggu persetujuan kolaborator...")),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sesi fokus dimulai!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai sesi fokus: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFabMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Tambah Baru',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_card,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Add Card'),
              subtitle: const Text('Buat kartu baru (Coming soon)'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Card - Coming soon')),
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Collaboration'),
              subtitle: const Text('Buka layar kolaborasi'),
              onTap: () {
                Navigator.pop(context);
                context.go('/collaboration');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Board'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tugas Saya'),
            Tab(text: 'Kolaborasi'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
        actions: [
          const NotificationIconButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<BoardBloc>().add(const LoadBoard()),
          ),
        ],
      ),
      // TAB VIEW UTAMA
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Tugas Pribadi
          BlocConsumer<BoardBloc, BoardState>(
            listener: (context, state) {
              if (state is BoardError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is BoardLoading) {
                return _buildSkeletonLoader();
              }

              if (state is BoardError) {
                return _buildErrorState(state.message);
              }

              if (state is BoardLoaded) {
                final board = state.board;
                final columns = state.columns.columns;

                if (board.totalCards == 0) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<BoardBloc>().add(const LoadBoard());
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _columnOrder.map((columnId) {
                        final columnData = columns.firstWhere(
                          (c) => c.id == columnId,
                          orElse: () => ColumnModel(
                            id: columnId,
                            title: _columnTitles[columnId] ?? columnId,
                            order: _columnOrder.indexOf(columnId),
                          ),
                        );
                        final cards = board.getCardsForColumn(columnId);
                        return Expanded(
                          child: _buildColumn(
                            columnId: columnId,
                            columnTitle: columnData.title,
                            columnIcon: _columnIcons[columnId] ?? Icons.circle,
                            columnColor: _columnColors[columnId] ?? Colors.grey,
                            cards: cards,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }

              return _buildEmptyState();
            },
          ),

          // TAB 2: Kolaborasi
          const CollaborativeTasksScreen(showAppBar: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFabMenu(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _columnOrder.map((columnId) {
          return Expanded(
            child: _buildSkeletonColumn(columnId),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkeletonColumn(String columnId) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _columnColors[columnId]?.withValues(alpha: 0.1) ?? Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 20,
                    color: Colors.grey[200],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => _buildSkeletonCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: double.infinity,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 100,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard_outlined,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada board',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Mulai buat board pertama Anda untuk mengelola tugas dan kolaborasi dengan tim.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showFabMenu(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Board Baru'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Gagal Memuat Board',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.read<BoardBloc>().add(const LoadBoard()),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn({
    required String columnId,
    required String columnTitle,
    required IconData columnIcon,
    required Color columnColor,
    required List<BoardCard> cards,
  }) {
    return Card(
      margin: const EdgeInsets.only(right: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: columnColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: columnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    columnIcon,
                    color: columnColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    columnTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: columnColor,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: columnColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cards.length}',
                    style: TextStyle(
                      color: columnColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cards.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 32,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kosong',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                itemBuilder: (context, index) => _buildCard(cards[index], columnColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BoardCard card, Color columnColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: columnColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.read<BoardBloc>().add(SelectCard(card: card));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      card.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _requestFocusSession(card.cardId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildChip(
                    label: card.difficultyLabel,
                    color: _getDifficultyColor(card.difficulty),
                    icon: Icons.trending_up,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    label: card.priorityLabel,
                    color: card.priorityColor,
                    icon: Icons.priority_high,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (card.cardList?.learningStrat != null)
                _buildChip(
                  label: card.cardList!.learningStrat!.strategyLabel,
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.psychology_outlined,
                  isLarge: true,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDeadline(card.deadline),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
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

  Widget _buildChip({
    required String label,
    required Color color,
    required IconData icon,
    bool isLarge = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 10 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isLarge ? 8 : 6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isLarge ? 14 : 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: isLarge ? 12 : 10,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      case 'expert':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _formatDeadline(String deadline) {
    try {
      final date = DateTime.parse(deadline);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final deadlineDate = DateTime(date.year, date.month, date.day);
      final diff = deadlineDate.difference(today).inDays;

      if (diff < 0) {
        return 'Terlambat ${(-diff)} hari';
      } else if (diff == 0) {
        return 'Hari ini';
      } else if (diff == 1) {
        return 'Besok';
      } else if (diff <= 7) {
        return '$diff hari lagi';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (_) {
      return deadline;
    }
  }
}