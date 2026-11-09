// import 'package:flutter/material.dart' hide Card;
// import 'package:flutter/services.dart';
// import 'package:gamatutor_kanban/model/card.dart';
// import 'package:gamatutor_kanban/model/cardlist.dart';
// import 'package:gamatutor_kanban/pages/card/newCard.dart';
// import 'package:gamatutor_kanban/pages/card/taskDetail.dart';
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
// import 'package:gamatutor_kanban/service/cardService.dart';
// import 'package:confetti/confetti.dart';
// import 'package:gamatutor_kanban/service/rekomendasiService.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// class KanbanBoardView extends StatefulWidget {
//   const KanbanBoardView({super.key});

//   @override
//   State<KanbanBoardView> createState() => _KanbanBoardViewState();
// }

// class _KanbanBoardViewState extends State<KanbanBoardView> {
//   final CardService _cardService = CardService();
//   List<Card> _cards = [];
//   bool _isLoading = true;
//   bool _hasError = false; // State untuk menampilkan error 404
//   String _errorMessage = '';
  
//   int _selectedStageIndex = 0;
//   late ConfettiController _confettiController;

//   // 🎨 Palette
//   static const _bg = Color(0xFFF8F9FE);
//   static const _primary = Color(0xFF3B82F6);
//   static const _primarySoft = Color(0xFFEFF6FF);
//   static const _ink = Color(0xFF0F172A);
//   static const _muted = Color(0xFF64748B);

//   @override
//   void initState() {
//     super.initState();
//     _fetchKanbanCards();
//     _confettiController = ConfettiController(
//       duration: const Duration(seconds: 3),
//     );
//   }

//   @override
//   void dispose() {
//     _confettiController.dispose();
//     super.dispose();
//   }

//   Future<void> _saveCardToBackend(Map<String, dynamic> cardData) async {
//     final token = await SecureTokenStorage.getToken();
//     if (token == null) throw Exception('Token tidak tersedia');

//     final createdCard = await _cardService.createCard(token, cardData);
//     final String cardId =
//         (createdCard['card_id'] ?? createdCard['cardId'] ?? createdCard['id'])
//             .toString();

//     if (cardData['subtasks'] != null &&
//         (cardData['subtasks'] as List).isNotEmpty) {
//       for (var subTitle in cardData['subtasks']) {
//         await _cardService.createCardList(token, cardId, {
//           'subTitle': subTitle,
//         });
//       }
//     }

//     if (cardData['collaborators'] != null &&
//         (cardData['collaborators'] as List).isNotEmpty) {
//       for (var friendUserId in cardData['collaborators']) {
//         await _cardService.addCollaborator(token, cardId, {
//           'friendId': friendUserId,
//           'role': 'member',
//         });
//       }
//     }
//   }

//   Future<void> _fetchKanbanCards() async {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });

//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (!mounted || token == null) return;

//       final fetchedCards = await _cardService.getCardsByUser(token);
//       if (!mounted) return;

//       setState(() {
//         _cards = fetchedCards;
//         _isLoading = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _isLoading = false;
//         _hasError = true;
//         // Jika error 404 atau sejenisnya
//         _errorMessage = e.toString().contains('404') 
//             ? 'Terjadi kesalahan di server (404).'
//             : 'Terjadi kesalahan saat memuat data.';
//       });
//     }
//   }

//   String getActiveColumn(Card card) {
//     if (card.reflectionCompletedAt != null &&
//         card.reflectionCompletedAt!.isNotEmpty) {
//       return 'reflection';
//     }

//     bool allSubtasksDone =
//         card.subtasks.isNotEmpty &&
//         card.subtasks.every((s) => s.endTimeList != null);
//     if (card.endTime != null || allSubtasksDone) {
//       return 'controlling';
//     }

//     if (card.startTime != null) {
//       return 'monitoring';
//     }

//     return 'planning';
//   }

//   Future<void> _advanceCardStage(Card card, String currentStage) async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       final nowStr = DateTime.now().toIso8601String();

//       if (currentStage == 'planning') {
//         if (card.startTime == null) {
//           await _cardService.updateCard(token, card.cardId!, {
//             'nmMatkul': card.courseName ?? '',
//             'title': card.title ?? '',
//             'description': card.description ?? '',
//             'learningId': card.learningId ?? '',
//             'priority': card.priority ?? 'sedang',
//             'difficulty': card.difficulty ?? 'sedang',
//             'deadline': card.deadline != null
//                 ? card.deadline!.toIso8601String().split('T')[0]
//                 : null,
//             'startTime': nowStr,
//           });
//         }
//       } else if (currentStage == 'monitoring') {
//         for (var subtask in card.subtasks) {
//           if (subtask.startTimeList == null && subtask.clId != null) {
//             await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
//               'subTitle': subtask.subTitle,
//               'startTimeList': nowStr,
//               'endTimeList': nowStr,
//             });
//           } else if (subtask.endTimeList == null && subtask.clId != null) {
//             await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
//               'subTitle': subtask.subTitle,
//               'startTimeList': subtask.startTimeList?.toIso8601String(),
//               'endTimeList': nowStr,
//             });
//           }
//         }
//         if (card.endTime == null) {
//           await _cardService.updateCard(token, card.cardId!, {'endTime': nowStr});
//         }
//       } else if (currentStage == 'controlling') {
//         _showReflectionDialog(card);
//         return;
//       }

//       await _fetchKanbanCards();
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Tugas berhasil digeser ke tahap selanjutnya! 🚀'),
//           backgroundColor: _primary,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       debugPrint('Gagal memajukan tahap tugas: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final planningCards = _cards.where((c) => getActiveColumn(c) == 'planning').toList();
//     final monitoringCards = _cards.where((c) => getActiveColumn(c) == 'monitoring').toList();
//     final controllingCards = _cards.where((c) => getActiveColumn(c) == 'controlling').toList();
//     final reflectionCards = _cards.where((c) => getActiveColumn(c) == 'reflection').toList();

//     List<Card> currentCards;
//     String currentStageName = 'planning';
//     if (_selectedStageIndex == 0) {
//       currentCards = planningCards;
//       currentStageName = 'planning';
//     } else if (_selectedStageIndex == 1) {
//       currentCards = monitoringCards;
//       currentStageName = 'monitoring';
//     } else if (_selectedStageIndex == 2) {
//       currentCards = controllingCards;
//       currentStageName = 'controlling';
//     } else {
//       currentCards = reflectionCards;
//       currentStageName = 'reflection';
//     }

//     return Stack(
//       children: [
//         Scaffold(
//           backgroundColor: _bg,
//           body: SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // ─── HEADER ───
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Tugas Saya',
//                             style: TextStyle(
//                               fontSize: 22,
//                               fontWeight: FontWeight.w800,
//                               color: _ink,
//                               letterSpacing: -0.5,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             _cards.isEmpty ? 'Belum ada tugas' : '${_cards.length} Tugas Aktif',
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: _muted,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Row(
//                         children: [
//                           Container(
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.grey.shade200),
//                             ),
//                             child: IconButton(
//                               icon: const Icon(Icons.volume_up_outlined, color: _primary, size: 20),
//                               onPressed: _showStrategyInfo,
//                             ),
//                           ),
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(color: Colors.grey.shade200),
//                             ),
//                             child: Row(
//                               children: const [
//                                 Icon(Icons.diamond_outlined, size: 16, color: _primary),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   '0',
//                                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink),
//                                 ),
//                                 SizedBox(width: 4),
//                                 Text(
//                                   'PERMATA ILMU',
//                                   style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _muted),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),

//                   // ─── BANNER ROADMAP ───
//                   Container(
//                     padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFE8EEF9),
//                       borderRadius: BorderRadius.circular(24),
//                     ),
//                     child: Column(
//                       children: [
//                         // Karakter & Node
//                         Stack(
//                           clipBehavior: Clip.none,
//                           children: [
//                             // Karakter Anak di Kiri
//                             Positioned(
//                               left: 0,
//                               bottom: 10,
//                               child: SizedBox(
//                                 width: 50,
//                                 height: 60,
//                                 child: CustomPaint(painter: _MiniCharacterPainter()),
//                               ),
//                             ),
//                             // Garis Putus-putus
//                             Positioned(
//                               top: 20,
//                               left: 50,
//                               right: 20,
//                               child: CustomPaint(
//                                 size: const Size(double.infinity, 2),
//                                 painter: _DashedLinePainter(color: _primary.withOpacity(0.3)),
//                               ),
//                             ),
//                             // Node Row
//                             Padding(
//                               padding: const EdgeInsets.only(left: 60),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   _buildNodeVisual(0, 'Planning', Icons.edit, planningCards.length, activeColor: _primary),
//                                   _buildNodeVisual(1, 'Monitoring', Icons.bolt, monitoringCards.length, activeColor: _primary),
//                                   _buildNodeVisual(2, 'Controlling', Icons.search, controllingCards.length, activeColor: _primary),
//                                   _buildNodeVisual(3, 'Reflection', Icons.emoji_events, reflectionCards.length, activeColor: _primary),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 16),
//                         // Indicator Dots
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: List.generate(4, (index) {
//                             bool isActive = _selectedStageIndex == index;
//                             return AnimatedContainer(
//                               duration: const Duration(milliseconds: 300),
//                               margin: const EdgeInsets.symmetric(horizontal: 3),
//                               height: 4,
//                               width: isActive ? 20 : 6,
//                               decoration: BoxDecoration(
//                                 color: isActive ? _primary : _primary.withOpacity(0.3),
//                                 borderRadius: BorderRadius.circular(2),
//                               ),
//                             );
//                           }),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // ─── LIST KARTU ATAU ERROR STATE ───
//                   Expanded(
//                     child: _isLoading
//                         ? const Center(child: CircularProgressIndicator(color: _primary))
//                         : _hasError
//                             ? _buildErrorState()
//                             : currentCards.isEmpty
//                                 ? _buildEmptyState()
//                                 : ListView.builder(
//                                     physics: const BouncingScrollPhysics(),
//                                     itemCount: currentCards.length + (_selectedStageIndex == 0 ? 1 : 0),
//                                     itemBuilder: (context, index) {
//                                       // Tombol Tambah Tugas (hanya di tab Planning)
//                                       if (_selectedStageIndex == 0 && index == currentCards.length) {
//                                         return Padding(
//                                           padding: const EdgeInsets.only(top: 8, bottom: 24),
//                                           child: InkWell(
//                                             onTap: () => _showAddCardDialog(),
//                                             child: Container(
//                                               padding: const EdgeInsets.symmetric(vertical: 16),
//                                               decoration: BoxDecoration(
//                                                 borderRadius: BorderRadius.circular(16),
//                                                 border: Border.all(
//                                                   color: Colors.grey.shade300,
//                                                   style: BorderStyle.solid,
//                                                 ),
//                                               ),
//                                               child: Center(
//                                                 child: Row(
//                                                   mainAxisSize: MainAxisSize.min,
//                                                   children: const [
//                                                     Icon(Icons.add, size: 16, color: _muted),
//                                                     SizedBox(width: 6),
//                                                     Text(
//                                                       'Tambah tugas',
//                                                       style: TextStyle(
//                                                         color: _muted,
//                                                         fontSize: 13,
//                                                         fontWeight: FontWeight.w600,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         );
//                                       }

//                                       // Render Card
//                                       final card = currentCards[index];
//                                       final totalSubtasks = card.subtasks.length;
//                                       final completedSubtasks = card.subtasks
//                                           .where((s) => s.endTimeList != null)
//                                           .length;

//                                       Color priorityColor = Colors.grey;
//                                       if (card.priority?.toLowerCase() == 'high') {
//                                         priorityColor = const Color(0xFFEF4444);
//                                       }
//                                       if (card.priority?.toLowerCase() == 'medium') {
//                                         priorityColor = const Color(0xFFF59E0B);
//                                       }
//                                       if (card.priority?.toLowerCase() == 'low') {
//                                         priorityColor = const Color(0xFF10B981);
//                                       }

//                                       return GestureDetector(
//                                         onTap: () {
//                                           Navigator.push(
//                                             context,
//                                             MaterialPageRoute(
//                                               builder: (context) => TaskDetailPage(
//                                                 card: card,
//                                                 onStartSubtask: (selectedCard, subtask) =>
//                                                     _handleStartSubtask(selectedCard, subtask),
//                                                 onStopSubtask: (selectedCard, subtask) =>
//                                                     _handleStopSubtask(selectedCard, subtask),
//                                                 onNavigateToReflection: () =>
//                                                     _showReflectionDialog(card),
//                                                 onEditCard: (updatedCard) {
//                                                   setState(() {
//                                                     int idx = _cards.indexWhere(
//                                                       (c) => c.cardId == updatedCard.cardId,
//                                                     );
//                                                     if (idx != -1) {
//                                                       _cards[idx] = updatedCard;
//                                                     }
//                                                   });
//                                                 },
//                                                 onDeleteCard: () async {
//                                                   final token = await SecureTokenStorage.getToken();
//                                                   final ok = await _cardService.deleteCard(
//                                                     token!,
//                                                     card.cardId!,
//                                                   );
//                                                   if (ok && mounted) {
//                                                     setState(
//                                                       () => _cards.removeWhere(
//                                                         (c) => c.cardId == card.cardId,
//                                                       ),
//                                                     );
//                                                   }
//                                                 },
//                                               ),
//                                             ),
//                                           ).then((_) => _fetchKanbanCards());
//                                         },
//                                         child: Container(
//                                           margin: const EdgeInsets.only(bottom: 14),
//                                           decoration: BoxDecoration(
//                                             color: Colors.white,
//                                             borderRadius: BorderRadius.circular(16),
//                                             border: Border.all(color: Colors.grey.shade200),
//                                             boxShadow: [
//                                               BoxShadow(
//                                                 color: Colors.black.withOpacity(0.02),
//                                                 blurRadius: 10,
//                                                 offset: const Offset(0, 4),
//                                               ),
//                                             ],
//                                           ),
//                                           child: ClipRRect(
//                                             borderRadius: BorderRadius.circular(16),
//                                             child: IntrinsicHeight(
//                                               child: Row(
//                                                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                                                 children: [
//                                                   Container(width: 6, color: priorityColor),
//                                                   Expanded(
//                                                     child: Column(
//                                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                                       children: [
//                                                         Padding(
//                                                           padding: const EdgeInsets.all(16),
//                                                           child: Column(
//                                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                                             children: [
//                                                               Row(
//                                                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                                 children: [
//                                                                   Expanded(
//                                                                     child: Column(
//                                                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                                                       children: [
//                                                                         Text(
//                                                                           card.title ?? 'Tanpa Judul',
//                                                                           style: const TextStyle(
//                                                                             fontWeight: FontWeight.w800,
//                                                                             fontSize: 14,
//                                                                             color: _ink,
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(height: 2),
//                                                                         Text(
//                                                                           card.courseName ?? 'Mata Kuliah',
//                                                                           style: const TextStyle(
//                                                                             fontSize: 11,
//                                                                             color: _muted,
//                                                                             fontWeight: FontWeight.w500,
//                                                                           ),
//                                                                         ),
//                                                                       ],
//                                                                     ),
//                                                                   ),
//                                                                   if (totalSubtasks > 0)
//                                                                     Container(
//                                                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                                                       decoration: BoxDecoration(
//                                                                         color: _primarySoft,
//                                                                         borderRadius: BorderRadius.circular(12),
//                                                                       ),
//                                                                       child: Text(
//                                                                         _selectedStageIndex == 0
//                                                                             ? '0/$totalSubtasks'
//                                                                             : '$completedSubtasks/$totalSubtasks',
//                                                                         style: const TextStyle(
//                                                                           fontSize: 11,
//                                                                           fontWeight: FontWeight.bold,
//                                                                           color: _primary,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                 ],
//                                                               ),
//                                                               if (card.description != null && card.description!.isNotEmpty) ...[
//                                                                 const SizedBox(height: 8),
//                                                                 Text(
//                                                                   card.description!,
//                                                                   maxLines: 2,
//                                                                   overflow: TextOverflow.ellipsis,
//                                                                   style: const TextStyle(
//                                                                     fontSize: 12,
//                                                                     color: _muted,
//                                                                     height: 1.4,
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                               _buildCollaboratorAvatars(card.collabList),
//                                                               if (card.subtasks.isNotEmpty) ...[
//                                                                 const SizedBox(height: 10),
//                                                                 ...card.subtasks.map((subtask) {
//                                                                   final bool isDone = subtask.endTimeList != null;
//                                                                   return Container(
//                                                                     margin: const EdgeInsets.symmetric(vertical: 4),
//                                                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                                                                     decoration: BoxDecoration(
//                                                                       color: const Color(0xFFF8FAFC),
//                                                                       borderRadius: BorderRadius.circular(8),
//                                                                       border: Border.all(color: Colors.grey.shade200),
//                                                                     ),
//                                                                     child: Row(
//                                                                       children: [
//                                                                         Expanded(
//                                                                           child: Text(
//                                                                             subtask.subTitle ?? '',
//                                                                             maxLines: 1,
//                                                                             overflow: TextOverflow.ellipsis,
//                                                                             style: TextStyle(
//                                                                               fontSize: 12,
//                                                                               color: isDone ? _muted : _ink,
//                                                                               decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
//                                                                             ),
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(width: 8),
//                                                                         if (subtask.startTimeList == null)
//                                                                           SizedBox(
//                                                                             width: 28, height: 28,
//                                                                             child: IconButton(
//                                                                               onPressed: () => _handleStartSubtask(card, subtask),
//                                                                               icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
//                                                                               padding: EdgeInsets.zero,
//                                                                               constraints: const BoxConstraints(),
//                                                                               style: IconButton.styleFrom(
//                                                                                 backgroundColor: _primary,
//                                                                                 shape: const CircleBorder(),
//                                                                               ),
//                                                                             ),
//                                                                           ),
//                                                                         if (subtask.startTimeList != null && subtask.endTimeList == null)
//                                                                           SizedBox(
//                                                                             width: 28, height: 28,
//                                                                             child: IconButton(
//                                                                               onPressed: () => _handleStopSubtask(card, subtask),
//                                                                               icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
//                                                                               padding: EdgeInsets.zero,
//                                                                               constraints: const BoxConstraints(),
//                                                                               style: IconButton.styleFrom(
//                                                                                 backgroundColor: const Color(0xFFEF4444),
//                                                                                 shape: const CircleBorder(),
//                                                                               ),
//                                                                             ),
//                                                                           ),
//                                                                       ],
//                                                                     ),
//                                                                   );
//                                                                 }),
//                                                               ],
//                                                             ],
//                                                           ),
//                                                         ),
//                                                         const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
//                                                         Container(
//                                                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                                                           color: const Color(0xFFFAFAFF),
//                                                           child: Row(
//                                                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                                             children: [
//                                                               if (card.priority != null)
//                                                                 Container(
//                                                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                                                                   decoration: BoxDecoration(
//                                                                     color: priorityColor.withOpacity(0.12),
//                                                                     borderRadius: BorderRadius.circular(6),
//                                                                   ),
//                                                                   child: Text(
//                                                                     card.priority!.toUpperCase(),
//                                                                     style: TextStyle(
//                                                                       fontSize: 10,
//                                                                       fontWeight: FontWeight.w900,
//                                                                       color: priorityColor,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               if (_selectedStageIndex < 3)
//                                                                 ElevatedButton.icon(
//                                                                   onPressed: () => _advanceCardStage(card, currentStageName),
//                                                                   icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
//                                                                   label: Text(
//                                                                     _selectedStageIndex == 2 ? 'Mulai Refleksi' : 'Lanjut Tahap',
//                                                                     style: const TextStyle(
//                                                                       fontSize: 11,
//                                                                       color: Colors.white,
//                                                                       fontWeight: FontWeight.bold,
//                                                                     ),
//                                                                   ),
//                                                                   style: ElevatedButton.styleFrom(
//                                                                     backgroundColor: _primary,
//                                                                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                                                                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                                                     elevation: 0,
//                                                                   ),
//                                                                 ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // ─── FLOATING ACTION BUTTON ───
//           // floatingActionButton: Padding(
//           //   padding: const EdgeInsets.only(bottom: 16, right: 8),
//           //   child: FloatingActionButton(
//           //     heroTag: null,
//           //     backgroundColor: _primary,
//           //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           //     onPressed: () {
//           //       HapticFeedback.lightImpact();
//           //       _showAddCardDialog();
//           //     },
//           //     child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
//           //   ),
//           // ),
//         ),
//         // Confetti Overlay
//         Align(
//           alignment: Alignment.topCenter,
//           child: ConfettiWidget(
//             confettiController: _confettiController,
//             blastDirectionality: BlastDirectionality.explosive,
//             particleDrag: 0.05,
//             emissionFrequency: 0.05,
//             numberOfParticles: 30,
//             gravity: 0.2,
//             colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
//           ),
//         ),
//       ],
//     );
//   }

//   // ─── WIDGET KOSONG (KETIKA BELUM ADA TUGAS) ───
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
//           const SizedBox(height: 16),
//           Text(
//             'Belum ada tugas di tahap ini.',
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Tekan tombol + untuk menambahkan tugas baru.',
//             style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── WIDGET ERROR STATE (SESUAI SCREENSHOT) ───
//   Widget _buildErrorState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey.shade400),
//           const SizedBox(height: 20),
//           Text(
//             _errorMessage.isNotEmpty ? _errorMessage : 'Terjadi kesalahan di server (404).',
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 20),
//           ElevatedButton(
//             onPressed: _fetchKanbanCards,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _primary,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               elevation: 0,
//             ),
//             child: const Text(
//               'Coba lagi',
//               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── NODE VISUAL ───
//   Widget _buildNodeVisual(int index, String label, IconData icon, int count, {required Color activeColor}) {
//     bool isSelected = _selectedStageIndex == index;

//     return GestureDetector(
//       onTap: () {
//         setState(() => _selectedStageIndex = index);
//       },
//       child: Column(
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: isSelected ? activeColor : Colors.white,
//                   boxShadow: [
//                     if (isSelected)
//                       BoxShadow(
//                         color: activeColor.withOpacity(0.4),
//                         blurRadius: 8,
//                         spreadRadius: 1,
//                       ),
//                   ],
//                 ),
//                 child: Icon(
//                   icon,
//                   size: 16,
//                   color: isSelected ? Colors.white : activeColor.withOpacity(0.6),
//                 ),
//               ),
//               Positioned(
//                 top: -4,
//                 right: -4,
//                 child: Container(
//                   padding: const EdgeInsets.all(3),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                     border: Border.all(color: Colors.grey.shade200),
//                   ),
//                   child: Text(
//                     '$count',
//                     style: TextStyle(
//                       fontSize: 8,
//                       fontWeight: FontWeight.w900,
//                       color: isSelected ? activeColor : Colors.grey.shade500,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 10,
//               fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//               color: isSelected ? _ink : _muted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── DIALOG TAMBAH CARD ───
//   void _showAddCardDialog() async {
//     final token = await SecureTokenStorage.getToken();
//     if (token == null) return;

//     final result = await Navigator.push<bool>(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddCardView(
//           token: token,
//           onCardCreated: (cardData) async {
//             await _saveCardToBackend(cardData);
//           },
//         ),
//       ),
//     );

//     if (result == true && mounted) {
//       await _fetchKanbanCards();
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Tugas baru berhasil ditambahkan ke Planning!'),
//           backgroundColor: Color(0xFF10B981),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   // ─── HANDLE SUBTASK ───
//   Future<void> _handleStartSubtask(Card card, CardList subtask) async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       final nowStr = DateTime.now().toIso8601String();

//       if (card.startTime == null) {
//         await _cardService.updateCard(token, card.cardId!, {
//           'nmMatkul': card.courseName ?? '',
//           'title': card.title ?? '',
//           'description': card.description ?? '',
//           'learningId': card.learningId ?? '',
//           'priority': card.priority ?? 'sedang',
//           'difficulty': card.difficulty ?? 'sedang',
//           'deadline': card.deadline != null
//               ? card.deadline!.toIso8601String().split('T')[0]
//               : null,
//           'startTime': nowStr,
//         });
//       }

//       if (subtask.clId != null) {
//         await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
//           'subTitle': subtask.subTitle,
//           'startTimeList': nowStr,
//         });
//       }

//       _fetchKanbanCards();
//     } catch (e) {
//       debugPrint('Gagal memulai subtask: $e');
//     }
//   }

//   Future<void> _handleStopSubtask(Card card, CardList subtask) async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       final nowStr = DateTime.now().toIso8601String();

//       if (subtask.clId != null) {
//         await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
//           'subTitle': subtask.subTitle,
//           'startTimeList': subtask.startTimeList?.toIso8601String(),
//           'endTimeList': nowStr,
//         });
//       }

//       final remainingUnfinished = card.subtasks
//           .where((s) => s.clId != subtask.clId && s.endTimeList == null)
//           .length;

//       if (remainingUnfinished == 0) {
//         await _cardService.updateCard(token, card.cardId!, {'endTime': nowStr});
//       }

//       _fetchKanbanCards();
//     } catch (e) {
//       debugPrint('Gagal menghentikan subtask: $e');
//     }
//   }

//   // ─── REFLEKSI DIALOG ───
//   void _showReflectionDialog(Card card) async {
//     String? strategyLabel = 'Strategi Belajar';
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token != null && card.learningId != null) {
//         final strategy = await CardService.getStrategyById(
//           token,
//           card.learningId!,
//         );
//         if (strategy != null) {
//           strategyLabel = strategy.learningStrategy;
//         }
//       }
//     } catch (e) {
//       debugPrint('Gagal memuat strategi: $e');
//     }
//     final String cardTitle = card.title ?? 'Tugas Ini';

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.white,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (BuildContext context) {
//         int selectedEffectiveness = 3;
//         int selectedConfidence = 3;
//         String goalAchievement = 'Ya';
//         final TextEditingController notesController = TextEditingController();

//         return StatefulBuilder(
//           builder: (BuildContext context, StateSetter setStateModal) {
//             return Container(
//               padding: EdgeInsets.only(
//                 left: 24,
//                 right: 24,
//                 top: 20,
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//               ),
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade300,
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     const Center(
//                       child: Text(
//                         'Sesi Selesai! Kamu Luar Biasa ✨',
//                         style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _ink),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       'Seberapa efektif strategi $strategyLabel bagimu?',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: List.generate(5, (index) {
//                         return IconButton(
//                           icon: Icon(
//                             Icons.sentiment_satisfied_alt,
//                             color: selectedEffectiveness == index + 1
//                                 ? _primary
//                                 : Colors.grey.shade400,
//                           ),
//                           onPressed: () {
//                             setStateModal(() {
//                               selectedEffectiveness = index + 1;
//                             });
//                           },
//                         );
//                       }),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Seberapa yakin kamu menguasai materi ini sekarang?',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink),
//                     ),
//                     const SizedBox(height: 8),
//                     Slider(
//                       value: selectedConfidence.toDouble(),
//                       min: 1,
//                       max: 5,
//                       divisions: 4,
//                       activeColor: _primary,
//                       label: '$selectedConfidence',
//                       onChanged: (val) {
//                         setStateModal(() {
//                           selectedConfidence = val.toInt();
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Apakah tugas ini membantumu mencapai $cardTitle?',
//                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: ['Ya', 'Sebagian', 'Tidak'].map((val) {
//                         bool isSelected = goalAchievement == val;
//                         return Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.symmetric(horizontal: 4.0),
//                             child: OutlinedButton(
//                               style: OutlinedButton.styleFrom(
//                                 backgroundColor: isSelected ? _primarySoft : Colors.white,
//                                 side: BorderSide(
//                                   color: isSelected ? _primary : Colors.grey.shade300,
//                                 ),
//                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                               ),
//                               onPressed: () {
//                                 setStateModal(() {
//                                   goalAchievement = val;
//                                 });
//                               },
//                               child: Text(
//                                 val,
//                                 style: TextStyle(
//                                   color: isSelected ? _primary : _muted,
//                                   fontSize: 12,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(height: 16),
//                     const Text(
//                       'Ada catatan untuk dirimu di masa depan? (Opsional)',
//                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink),
//                     ),
//                     const SizedBox(height: 8),
//                     TextField(
//                       controller: notesController,
//                       maxLines: 2,
//                       decoration: InputDecoration(
//                         hintText: 'Misal: Perlu latihan lebih banyak...',
//                         hintStyle: TextStyle(fontSize: 12, color: _muted),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey.shade300),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey.shade300),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: _primary),
//                         ),
//                         isDense: true,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: _primary,
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                         ),
//                         onPressed: () async {
//                           Navigator.pop(context);
//                           _confettiController.play();
//                           HapticFeedback.heavyImpact();
//                           try {
//                             final token = await SecureTokenStorage.getToken();
//                             if (token == null) return;

//                             await _cardService.updateCard(token, card.cardId!, {
//                               'reflectionCompletedAt': DateTime.now().toIso8601String(),
//                               'satisfactionRating': selectedEffectiveness,
//                               'reflectionQ1Strategy': selectedEffectiveness,
//                               'reflectionQ2Confidence': selectedConfidence,
//                               'reflectionQ3WhatLearned': goalAchievement,
//                               'reflectionQ4Value': notesController.text.trim(),
//                               'notes': notesController.text.trim(),
//                             });

//                             _fetchKanbanCards();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text('🔥 Kerja bagus! Kamu menyelesaikan 1 tugas.'),
//                                 backgroundColor: Color(0xFF10B981),
//                                 behavior: SnackBarBehavior.floating,
//                               ),
//                             );
//                           } catch (e) {
//                             debugPrint('Gagal menyimpan refleksi: $e');
//                           }
//                         },
//                         child: const Text(
//                           'Simpan & Selesaikan Tugas',
//                           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }

//   // ─── AVATAR KOLABORATOR ───
//   Widget _buildCollaboratorAvatars(List<dynamic>? collaborations) {
//     if (collaborations == null || collaborations.isEmpty) return const SizedBox.shrink();

//     return Padding(
//       padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
//       child: Row(
//         children: [
//           const Icon(Icons.group_rounded, size: 14, color: _muted),
//           const SizedBox(width: 6),
//           SizedBox(
//             height: 24,
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: collaborations.map((collab) {
//                 String initial = 'U';
//                 if (collab is Map) {
//                   final user = collab['user'] ?? collab['User'] ?? {};
//                   final username = user['username'] ?? user['name'] ?? 'User';
//                   if (username.isNotEmpty) initial = username[0].toUpperCase();
//                 } else {
//                   final username = (collab.userId ?? 'U').toString();
//                   if (username.isNotEmpty) initial = username[0].toUpperCase();
//                 }

//                 return Container(
//                   margin: const EdgeInsets.only(right: 4),
//                   child: CircleAvatar(
//                     radius: 11,
//                     backgroundColor: _primary,
//                     child: Text(
//                       initial,
//                       style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── INFO STRATEGI ───
//   Future<void> _showStrategyInfo() async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//         child: CircularProgressIndicator(color: _primary),
//       ),
//     );

//     List<dynamic> strategies = [];
//     List<String> unlocked = [];
//     String? error;

//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) throw Exception('Token tidak tersedia');

//       final decoded = JwtDecoder.decode(token);
//       final String userId = decoded['userId'] ?? decoded['id'] ?? decoded['sub'];
//       if (userId.isEmpty) {
//         throw Exception('userId tidak ada di token');
//       }

//       final results = await Future.wait([
//         CardService.getAllStrategies(),
//         rekomendasiService.getUnlockedFeatures(userId, token),
//       ]);

//       final allStrategies = results[0];
//       unlocked = (results[1]).map((e) => e.toString()).toList();

//       strategies = allStrategies.where((s) {
//         final keyCode = (s['keyCode'] ?? '').toString().toLowerCase();
//         return unlocked.any(
//           (u) => u.toLowerCase() == keyCode || u.toLowerCase().contains(keyCode),
//         );
//       }).toList();
//     } catch (e) {
//       error = e.toString();
//     }

//     if (!mounted) return;
//     Navigator.of(context, rootNavigator: true).pop();

//     if (error != null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal memuat strategi: $error'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     if (strategies.isEmpty) {
//       showModalBottomSheet(
//         context: context,
//         backgroundColor: Colors.transparent,
//         builder: (context) => _buildEmptyStrategiesSheet(),
//       );
//       return;
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => _buildStrategyInfoSheet(strategies),
//     );
//   }

//   Widget _buildEmptyStrategiesSheet() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             margin: const EdgeInsets.only(bottom: 16),
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const Text('🔒', style: TextStyle(fontSize: 56)),
//           const SizedBox(height: 16),
//           const Text(
//             'Belum Ada Strategi',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Kamu belum menyelesaikan kuis strategi belajar.\nIkuti kuis dulu untuk membuka strategi belajarmu.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 13, color: _muted),
//           ),
//           const SizedBox(height: 24),
//           SizedBox(
//             width: double.infinity,
//             height: 48,
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _primary,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               onPressed: () => Navigator.pop(context),
//               child: const Text(
//                 'Ikuti Kuis Sekarang',
//                 style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//         ],
//       ),
//     );
//   }

//   Widget _buildStrategyInfoSheet(List<dynamic> strategies) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.75,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: _bg,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             children: [
//               Container(
//                 margin: const EdgeInsets.only(top: 12, bottom: 8),
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
//                 child: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: _primarySoft,
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: const Text('🧠', style: TextStyle(fontSize: 20)),
//                     ),
//                     const SizedBox(width: 12),
//                     const Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Strategi Belajarmu',
//                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             'Strategi yang sudah kamu buka',
//                             style: TextStyle(fontSize: 12, color: _muted),
//                           ),
//                         ],
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: ListView.separated(
//                   controller: scrollController,
//                   padding: const EdgeInsets.all(20),
//                   itemCount: strategies.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 12),
//                   itemBuilder: (context, index) => _buildStrategyCard(strategies[index]),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildStrategyCard(dynamic strategy) {
//     final String label = strategy['learningStrategy'] ?? 'Strategi';
//     final String keyCode = (strategy['keyCode'] ?? '').toString().toLowerCase();
//     final String description = strategy['description'] ?? 'Belum ada deskripsi.';

//     String emoji = '🔹';
//     Color color = _primary;
//     Color bgColor = _primarySoft;
//     String category = 'Umum';

//     if (keyCode.contains('time')) {
//       emoji = '⏱️';
//       color = const Color(0xFFF59E0B);
//       bgColor = const Color(0xFFFFFBEB);
//       category = 'Manajemen Waktu';
//     } else if (keyCode.contains('help')) {
//       emoji = '🤝';
//       color = const Color(0xFFEC4899);
//       bgColor = const Color(0xFFFCE7F3);
//       category = 'Bantuan Sosial';
//     } else if (keyCode.contains('organization')) {
//       emoji = '🏗️';
//       color = const Color(0xFF3B82F6);
//       bgColor = const Color(0xFFDBEAFE);
//       category = 'Organisasi';
//     } else if (keyCode.contains('elaboration')) {
//       emoji = '🕸️';
//       color = const Color(0xFF8B5CF6);
//       bgColor = const Color(0xFFF3E8FF);
//       category = 'Elaborasi';
//     } else if (keyCode.contains('rehearsal')) {
//       emoji = '🧠';
//       color = const Color(0xFF10B981);
//       bgColor = const Color(0xFFECFDF5);
//       category = 'Hafalan';
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.02),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 48,
//             height: 48,
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Center(
//               child: Text(emoji, style: const TextStyle(fontSize: 24)),
//             ),
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                   decoration: BoxDecoration(
//                     color: bgColor,
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     category.toUpperCase(),
//                     style: TextStyle(
//                       fontSize: 9,
//                       fontWeight: FontWeight.w900,
//                       color: color,
//                       letterSpacing: 0.5,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   label,
//                   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink),
//                 ),
//                 const SizedBox(height: 6),
//                 Text(
//                   description,
//                   style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.5),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ═══════════════════════════════════════════════════════════════
// // CUSTOM PAINTERS (Garis putus-putus & Karakter Anak)
// // ═══════════════════════════════════════════════════════════════
// class _DashedLinePainter extends CustomPainter {
//   final Color color;
//   _DashedLinePainter({required this.color});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = 2
//       ..strokeCap = StrokeCap.round;
//     const dash = 4.0;
//     const gap = 4.0;
//     double x = 0;
//     while (x < size.width) {
//       canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
//       x += dash + gap;
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

// class _MiniCharacterPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     // Kepala
//     final headPaint = Paint()..color = const Color(0xFFFFD9C0);
//     canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), 12, headPaint);

//     // Rambut
//     final hairPaint = Paint()..color = const Color(0xFF1E293B);
//     canvas.drawArc(
//       Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.3), radius: 12),
//       3.14,
//       3.14,
//       true,
//       hairPaint,
//     );

//     // Badan
//     final bodyPaint = Paint()..color = const Color(0xFF6366F1);
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromLTWH(size.width * 0.25, size.height * 0.5, size.width * 0.5, size.height * 0.45),
//         const Radius.circular(6),
//       ),
//       bodyPaint,
//     );

//     // Tangan
//     final armPaint = Paint()
//       ..color = const Color(0xFFFFD9C0)
//       ..strokeWidth = 4
//       ..strokeCap = StrokeCap.round;
//     canvas.drawLine(
//       Offset(size.width * 0.25, size.height * 0.6),
//       Offset(size.width * 0.05, size.height * 0.55),
//       armPaint,
//     );
//     canvas.drawLine(
//       Offset(size.width * 0.75, size.height * 0.6),
//       Offset(size.width * 0.95, size.height * 0.55),
//       armPaint,
//     );

//     // Kaki
//     final legPaint = Paint()
//       ..color = const Color(0xFF1E293B)
//       ..strokeWidth = 5
//       ..strokeCap = StrokeCap.round;
//     canvas.drawLine(
//       Offset(size.width * 0.4, size.height * 0.95),
//       Offset(size.width * 0.4, size.height),
//       legPaint,
//     );
//     canvas.drawLine(
//       Offset(size.width * 0.6, size.height * 0.95),
//       Offset(size.width * 0.6, size.height),
//       legPaint,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/pages/card/newCard.dart';
import 'package:gamatutor_kanban/pages/card/taskDetail.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:confetti/confetti.dart';
import 'package:gamatutor_kanban/service/rekomendasiService.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class KanbanBoardView extends StatefulWidget {
  const KanbanBoardView({super.key});

  @override
  State<KanbanBoardView> createState() => _KanbanBoardViewState();
}

class _KanbanBoardViewState extends State<KanbanBoardView> {
  final CardService _cardService = CardService();
  List<Card> _cards = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  int _selectedStageIndex = 0;
  late ConfettiController _confettiController;

  // 🎨 Palette
  static const _bg = Color(0xFFF8F9FE);
  static const _primary = Color(0xFF3B82F6);
  static const _primarySoft = Color(0xFFEFF6FF);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _fetchKanbanCards();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _saveCardToBackend(Map<String, dynamic> cardData) async {
    final token = await SecureTokenStorage.getToken();
    if (token == null) throw Exception('Token tidak tersedia');

    final createdCard = await _cardService.createCard(token, cardData);
    final String cardId =
        (createdCard['card_id'] ?? createdCard['cardId'] ?? createdCard['id']).toString();

    if (cardData['subtasks'] != null && (cardData['subtasks'] as List).isNotEmpty) {
      for (var subTitle in cardData['subtasks']) {
        await _cardService.createCardList(token, cardId, {'subTitle': subTitle});
      }
    }

    if (cardData['collaborators'] != null && (cardData['collaborators'] as List).isNotEmpty) {
      for (var friendUserId in cardData['collaborators']) {
        await _cardService.addCollaborator(token, cardId, {
          'friendId': friendUserId,
          'role': 'member',
        });
      }
    }
  }

  Future<void> _fetchKanbanCards() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = await SecureTokenStorage.getToken();
      if (!mounted || token == null) return;

      final fetchedCards = await _cardService.getCardsByUser(token);
      if (!mounted) return;

      setState(() {
        _cards = fetchedCards;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().contains('404')
            ? 'Terjadi kesalahan di server (404).'
            : 'Terjadi kesalahan saat memuat data.';
      });
    }
  }

  String getActiveColumn(Card card) {
    if (card.reflectionCompletedAt != null && card.reflectionCompletedAt!.isNotEmpty) {
      return 'reflection';
    }

    bool allSubtasksDone =
        card.subtasks.isNotEmpty && card.subtasks.every((s) => s.endTimeList != null);
    if (card.endTime != null || allSubtasksDone) {
      return 'controlling';
    }

    if (card.startTime != null) {
      return 'monitoring';
    }

    return 'planning';
  }

  Future<void> _advanceCardStage(Card card, String currentStage) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final nowStr = DateTime.now().toIso8601String();

      if (currentStage == 'planning') {
        if (card.startTime == null) {
          await _cardService.updateCard(token, card.cardId!, {
            'nmMatkul': card.courseName ?? '',
            'title': card.title ?? '',
            'description': card.description ?? '',
            'learningId': card.learningId ?? '',
            'priority': card.priority ?? 'sedang',
            'difficulty': card.difficulty ?? 'sedang',
            'deadline': card.deadline != null ? card.deadline!.toIso8601String().split('T')[0] : null,
            'startTime': nowStr,
          });
        }
      } else if (currentStage == 'monitoring') {
        for (var subtask in card.subtasks) {
          if (subtask.startTimeList == null && subtask.clId != null) {
            await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
              'subTitle': subtask.subTitle,
              'startTimeList': nowStr,
              'endTimeList': nowStr,
            });
          } else if (subtask.endTimeList == null && subtask.clId != null) {
            await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
              'subTitle': subtask.subTitle,
              'startTimeList': subtask.startTimeList?.toIso8601String(),
              'endTimeList': nowStr,
            });
          }
        }
        if (card.endTime == null) {
          await _cardService.updateCard(token, card.cardId!, {'endTime': nowStr});
        }
      } else if (currentStage == 'controlling') {
        _showReflectionDialog(card);
        return;
      }

      await _fetchKanbanCards();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil digeser ke tahap selanjutnya! 🚀'),
          backgroundColor: _primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Gagal memajukan tahap tugas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final planningCards = _cards.where((c) => getActiveColumn(c) == 'planning').toList();
    final monitoringCards = _cards.where((c) => getActiveColumn(c) == 'monitoring').toList();
    final controllingCards = _cards.where((c) => getActiveColumn(c) == 'controlling').toList();
    final reflectionCards = _cards.where((c) => getActiveColumn(c) == 'reflection').toList();

    List<Card> currentCards;
    String currentStageName = 'planning';
    if (_selectedStageIndex == 0) {
      currentCards = planningCards;
      currentStageName = 'planning';
    } else if (_selectedStageIndex == 1) {
      currentCards = monitoringCards;
      currentStageName = 'monitoring';
    } else if (_selectedStageIndex == 2) {
      currentCards = controllingCards;
      currentStageName = 'controlling';
    } else {
      currentCards = reflectionCards;
      currentStageName = 'reflection';
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── HEADER TUGAS SAYA ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tugas Saya',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cards.isEmpty ? 'Belum ada tugas' : '${_cards.length} Tugas Aktif',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.volume_up_outlined, color: _primary, size: 20),
                              onPressed: _showStrategyInfo,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.diamond_outlined, size: 16, color: _primary),
                                SizedBox(width: 4),
                                Text('0', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink)),
                                SizedBox(width: 4),
                                Text('PERMATA ILMU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── BANNER ROADMAP (REFERENSI UI) ───
                  Container(
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD5DFF5), Color(0xFFE6EBF8), Color(0xFFF0EDF6)],
                        stops: [0, 0.55, 1],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 110, // Tinggi area peta
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              // 1. Background Gunung
                              Positioned.fill(
                                bottom: 0,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: CustomPaint(painter: _FlowScenePainter()),
                                ),
                              ),
                              
                              // 2. Karakter di Kiri
                              Positioned(
                                left: 5,
                                bottom: 5,
                                child: SizedBox(
                                  width: 64,
                                  height: 85,
                                  child: Image.asset(
                                    'assets/img/mid.png', // Pastikan file ada
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => 
                                        const Icon(Icons.person, size: 50, color: Colors.blue),
                                  ),
                                ),
                              ),

                              // 3. Garis Putus-putus Melengkung
                              Positioned(
                                left: 65, 
                                right: 10,
                                top: 45, 
                                child: CustomPaint(
                                  size: const Size(double.infinity, 2),
                                  painter: _DashedLinePainter(color: _primary.withOpacity(0.4)),
                                ),
                              ),

                              // 4. Node & Label
                              Positioned(
                                left: 60, 
                                right: 10,
                                top: 25,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildNodeVisual(0, 'Planning', Icons.edit, planningCards.length, activeColor: _primary),
                                    _buildNodeVisual(1, 'Monitoring', Icons.bolt, monitoringCards.length, activeColor: _primary),
                                    _buildNodeVisual(2, 'Controlling', Icons.search, controllingCards.length, activeColor: _primary),
                                    _buildNodeVisual(3, 'Reflection', Icons.emoji_events, reflectionCards.length, activeColor: _primary),
                                  ],
                                ),
                              ),
                              
                              // 5. Hiasan Bendera Kanan Atas
                              Positioned(
                                right: 15,
                                top: 0,
                                child: Icon(Icons.flag_rounded, color: Colors.pink.shade300, size: 24),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Indicator Dots Bawah
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            bool isActive = _selectedStageIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 4,
                              width: isActive ? 20 : 6,
                              decoration: BoxDecoration(
                                color: isActive ? _primary : _primary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── LIST KARTU / ERROR STATE ───
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: _primary))
                        : _hasError
                            ? _buildErrorState()
                            : currentCards.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: currentCards.length + (_selectedStageIndex == 0 ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      // Tombol Tambah Tugas (hanya di tab Planning)
                                      if (_selectedStageIndex == 0 && index == currentCards.length) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                                          child: InkWell(
                                            onTap: () => _showAddCardDialog(),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: Center(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Icons.add, size: 16, color: _muted),
                                                    SizedBox(width: 6),
                                                    Text('Tambah tugas', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }

                                      // Render Card
                                      final card = currentCards[index];
                                      final totalSubtasks = card.subtasks.length;
                                      final completedSubtasks = card.subtasks.where((s) => s.endTimeList != null).length;

                                      Color priorityColor = Colors.grey;
                                      if (card.priority?.toString() == 'high') priorityColor = const Color(0xFFEF4444);
                                      if (card.priority?.toString() == 'medium') priorityColor = const Color(0xFFF59E0B);
                                      if (card.priority?.toString() == 'low') priorityColor = const Color(0xFF10B981);

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaskDetailPage(
                                                card: card,
                                                onStartSubtask: (selectedCard, subtask) => _handleStartSubtask(selectedCard, subtask),
                                                onStopSubtask: (selectedCard, subtask) => _handleStopSubtask(selectedCard, subtask),
                                                onNavigateToReflection: () => _showReflectionDialog(card),
                                                onEditCard: (updatedCard) {
                                                  setState(() {
                                                    int idx = _cards.indexWhere((c) => c.cardId == updatedCard.cardId);
                                                    if (idx != -1) _cards[idx] = updatedCard;
                                                  });
                                                },
                                                onDeleteCard: () async {
                                                  final token = await SecureTokenStorage.getToken();
                                                  final ok = await _cardService.deleteCard(token!, card.cardId!);
                                                  if (ok && mounted) {
                                                    setState(() => _cards.removeWhere((c) => c.cardId == card.cardId));
                                                  }
                                                },
                                              ),
                                            ),
                                          ).then((_) => _fetchKanbanCards());
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 14),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: Colors.grey.shade200),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: IntrinsicHeight(
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                children: [
                                                  Container(width: 6, color: priorityColor),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets.all(16),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        Text(
                                                                          card.title ?? 'Tanpa Judul',
                                                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink),
                                                                        ),
                                                                        const SizedBox(height: 2),
                                                                        Text(
                                                                          card.courseName ?? 'Mata Kuliah',
                                                                          style: const TextStyle(fontSize: 11, color: _muted, fontWeight: FontWeight.w500),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  if (totalSubtasks > 0)
                                                                    Container(
                                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                      decoration: BoxDecoration(color: _primarySoft, borderRadius: BorderRadius.circular(12)),
                                                                      child: Text(
                                                                        _selectedStageIndex == 0 ? '0/$totalSubtasks' : '$completedSubtasks/$totalSubtasks',
                                                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primary),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                              if (card.description != null && card.description!.isNotEmpty) ...[
                                                                const SizedBox(height: 8),
                                                                Text(
                                                                  card.description!,
                                                                  maxLines: 2,
                                                                  overflow: TextOverflow.ellipsis,
                                                                  style: const TextStyle(fontSize: 12, color: _muted, height: 1.4),
                                                                ),
                                                              ],
                                                              _buildCollaboratorAvatars(card.collabList),
                                                              if (card.subtasks.isNotEmpty) ...[
                                                                const SizedBox(height: 10),
                                                                ...card.subtasks.map((subtask) {
                                                                  final bool isDone = subtask.endTimeList != null;
                                                                  return Container(
                                                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                                    decoration: BoxDecoration(
                                                                      color: const Color(0xFFF8FAFC),
                                                                      borderRadius: BorderRadius.circular(8),
                                                                      border: Border.all(color: Colors.grey.shade200),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Text(
                                                                            subtask.subTitle ?? '',
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            style: TextStyle(
                                                                              fontSize: 12,
                                                                              color: isDone ? _muted : _ink,
                                                                              decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 8),
                                                                        if (subtask.startTimeList == null)
                                                                          SizedBox(
                                                                            width: 28, height: 28,
                                                                            child: IconButton(
                                                                              onPressed: () => _handleStartSubtask(card, subtask),
                                                                              icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                                                              padding: EdgeInsets.zero,
                                                                              constraints: const BoxConstraints(),
                                                                              style: IconButton.styleFrom(backgroundColor: _primary, shape: const CircleBorder()),
                                                                            ),
                                                                          ),
                                                                        if (subtask.startTimeList != null && subtask.endTimeList == null)
                                                                          SizedBox(
                                                                            width: 28, height: 28,
                                                                            child: IconButton(
                                                                              onPressed: () => _handleStopSubtask(card, subtask),
                                                                              icon: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                                                                              padding: EdgeInsets.zero,
                                                                              constraints: const BoxConstraints(),
                                                                              style: IconButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: const CircleBorder()),
                                                                            ),
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                }),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                          color: const Color(0xFFFAFAFF),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                            children: [
                                                              if (card.priority != null)
                                                                Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                                  decoration: BoxDecoration(color: priorityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                                                  child: Text(
                                                                    card.priority!.toUpperCase(),
                                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: priorityColor),
                                                                  ),
                                                                ),
                                                              if (_selectedStageIndex < 3)
                                                                ElevatedButton.icon(
                                                                  onPressed: () => _advanceCardStage(card, currentStageName),
                                                                  icon: const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                                                                  label: Text(
                                                                    _selectedStageIndex == 2 ? 'Mulai Refleksi' : 'Lanjut Tahap',
                                                                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                                                  ),
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor: _primary,
                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                    elevation: 0,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
          ),
          
          // ─── FLOATING ACTION BUTTON ───
          // floatingActionButton: Padding(
          //   padding: const EdgeInsets.only(bottom: 16, right: 8),
          //   child: FloatingActionButton(
          //     heroTag: null,
          //     backgroundColor: _primary,
          //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          //     onPressed: () {
          //       HapticFeedback.lightImpact();
          //       _showAddCardDialog();
          //     },
          //     child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          //   ),
          // ),
        ),
        // Confetti Overlay
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
          ),
        ),
      ],
    );
  }

  // ─── WIDGET KOSONG ───
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Belum ada tugas di tahap ini.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Tekan tombol + untuk menambahkan tugas baru.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ─── WIDGET ERROR STATE ───
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            _errorMessage.isNotEmpty ? _errorMessage : 'Terjadi kesalahan di server (404).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchKanbanCards,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text('Coba lagi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ─── NODE VISUAL ───
  Widget _buildNodeVisual(int index, String label, IconData icon, int count, {required Color activeColor}) {
    bool isSelected = _selectedStageIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedStageIndex = index),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? activeColor : Colors.white,
                  border: isSelected ? null : Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 8, spreadRadius: 1),
                  ],
                ),
                child: Icon(icon, size: 16, color: isSelected ? Colors.white : activeColor.withOpacity(0.6)),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? activeColor : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? _ink : _muted,
            ),
          ),
        ],
      ),
    );
  }

  // ─── DIALOG TAMBAH CARD ───
  void _showAddCardDialog() async {
    final token = await SecureTokenStorage.getToken();
    if (token == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardView(
          token: token,
          onCardCreated: (cardData) async {
            await _saveCardToBackend(cardData);
          },
        ),
      ),
    );

    if (result == true && mounted) {
      await _fetchKanbanCards();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas baru berhasil ditambahkan ke Planning!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ─── HANDLE SUBTASK ───
  Future<void> _handleStartSubtask(Card card, CardList subtask) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final nowStr = DateTime.now().toIso8601String();

      if (card.startTime == null) {
        await _cardService.updateCard(token, card.cardId!, {
          'nmMatkul': card.courseName ?? '',
          'title': card.title ?? '',
          'description': card.description ?? '',
          'learningId': card.learningId ?? '',
          'priority': card.priority ?? 'sedang',
          'difficulty': card.difficulty ?? 'sedang',
          'deadline': card.deadline != null ? card.deadline!.toIso8601String().split('T')[0] : null,
          'startTime': nowStr,
        });
      }

      if (subtask.clId != null) {
        await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
          'subTitle': subtask.subTitle,
          'startTimeList': nowStr,
        });
      }

      _fetchKanbanCards();
    } catch (e) {
      debugPrint('Gagal memulai subtask: $e');
    }
  }

  Future<void> _handleStopSubtask(Card card, CardList subtask) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final nowStr = DateTime.now().toIso8601String();

      if (subtask.clId != null) {
        await _cardService.updateCardList(token, card.cardId!, subtask.clId!, {
          'subTitle': subtask.subTitle,
          'startTimeList': subtask.startTimeList?.toIso8601String(),
          'endTimeList': nowStr,
        });
      }

      final remainingUnfinished = card.subtasks.where((s) => s.clId != subtask.clId && s.endTimeList == null).length;

      if (remainingUnfinished == 0) {
        await _cardService.updateCard(token, card.cardId!, {'endTime': nowStr});
      }

      _fetchKanbanCards();
    } catch (e) {
      debugPrint('Gagal menghentikan subtask: $e');
    }
  }

  // ─── REFLEKSI DIALOG ───
  void _showReflectionDialog(Card card) async {
    String? strategyLabel = 'Strategi Belajar';
    try {
      final token = await SecureTokenStorage.getToken();
      if (token != null && card.learningId != null) {
        final strategy = await CardService.getStrategyById(token, card.learningId!);
        if (strategy != null) strategyLabel = strategy.learningStrategy;
      }
    } catch (e) {
      debugPrint('Gagal memuat strategi: $e');
    }
    final String cardTitle = card.title ?? 'Tugas Ini';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext context) {
        int selectedEffectiveness = 3;
        int selectedConfidence = 3;
        String goalAchievement = 'Ya';
        final TextEditingController notesController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text('Sesi Selesai! Kamu Luar Biasa ✨',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: _ink)),
                    ),
                    const SizedBox(height: 24),
                    Text('Seberapa efektif strategi $strategyLabel bagimu?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            Icons.sentiment_satisfied_alt,
                            color: selectedEffectiveness == index + 1 ? _primary : Colors.grey.shade400,
                          ),
                          onPressed: () => setStateModal(() => selectedEffectiveness = index + 1),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text('Seberapa yakin kamu menguasai materi ini sekarang?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink)),
                    const SizedBox(height: 8),
                    Slider(
                      value: selectedConfidence.toDouble(),
                      min: 1, max: 5, divisions: 4,
                      activeColor: _primary,
                      label: '$selectedConfidence',
                      onChanged: (val) => setStateModal(() => selectedConfidence = val.toInt()),
                    ),
                    const SizedBox(height: 16),
                    Text('Apakah tugas ini membantumu mencapai $cardTitle?',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Ya', 'Sebagian', 'Tidak'].map((val) {
                        bool isSelected = goalAchievement == val;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: isSelected ? _primarySoft : Colors.white,
                                side: BorderSide(color: isSelected ? _primary : Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => setStateModal(() => goalAchievement = val),
                              child: Text(
                                val,
                                style: TextStyle(
                                  color: isSelected ? _primary : _muted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ada catatan untuk dirimu di masa depan? (Opsional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _ink)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Misal: Perlu latihan lebih banyak...',
                        hintStyle: TextStyle(fontSize: 12, color: _muted),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _primary),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          _confettiController.play();
                          HapticFeedback.heavyImpact();
                          try {
                            final token = await SecureTokenStorage.getToken();
                            if (token == null) return;

                            await _cardService.updateCard(token, card.cardId!, {
                              'reflectionCompletedAt': DateTime.now().toIso8601String(),
                              'satisfactionRating': selectedEffectiveness,
                              'reflectionQ1Strategy': selectedEffectiveness,
                              'reflectionQ2Confidence': selectedConfidence,
                              'reflectionQ3WhatLearned': goalAchievement,
                              'reflectionQ4Value': notesController.text.trim(),
                              'notes': notesController.text.trim(),
                            });

                            _fetchKanbanCards();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('🔥 Kerja bagus! Kamu menyelesaikan 1 tugas.'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Gagal menyimpan refleksi: $e');
                          }
                        },
                        child: const Text('Simpan & Selesaikan Tugas',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── AVATAR KOLABORATOR ───
  Widget _buildCollaboratorAvatars(List<dynamic>? collaborations) {
    if (collaborations == null || collaborations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 4.0),
      child: Row(
        children: [
          const Icon(Icons.group_rounded, size: 14, color: _muted),
          const SizedBox(width: 6),
          SizedBox(
            height: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: collaborations.map((collab) {
                String initial = 'U';
                if (collab is Map) {
                  final user = collab['user'] ?? collab['User'] ?? {};
                  final username = user['username'] ?? user['name'] ?? 'User';
                  if (username.isNotEmpty) initial = username[0].toUpperCase();
                } else {
                  final username = (collab.userId ?? 'U').toString();
                  if (username.isNotEmpty) initial = username[0].toUpperCase();
                }

                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: _primary,
                    child: Text(initial, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── INFO STRATEGI ───
  Future<void> _showStrategyInfo() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: _primary)),
    );

    List<dynamic> strategies = [];
    List<String> unlocked = [];
    String? error;

    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) throw Exception('Token tidak tersedia');

      final decoded = JwtDecoder.decode(token);
      final String userId = decoded['userId'] ?? decoded['id'] ?? decoded['sub'];
      if (userId.isEmpty) throw Exception('userId tidak ada di token');

      final results = await Future.wait([
        CardService.getAllStrategies(),
        rekomendasiService.getUnlockedFeatures(userId, token),
      ]);

      final allStrategies = results[0];
      unlocked = (results[1]).map((e) => e.toString()).toList();

      strategies = allStrategies.where((s) {
        final keyCode = (s['keyCode'] ?? '').toString().toString();
        return unlocked.any((u) => u.toString() == keyCode || u.toString().contains(keyCode));
      }).toList();
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat strategi: $error'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (strategies.isEmpty) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildEmptyStrategiesSheet(),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildStrategyInfoSheet(strategies),
    );
  }

  Widget _buildEmptyStrategiesSheet() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('🔒', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('Belum Ada Strategi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
          const SizedBox(height: 8),
          Text(
            'Kamu belum menyelesaikan kuis strategi belajar.\nIkuti kuis dulu untuk membuka strategi belajarmu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Ikuti Kuis Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStrategyInfoSheet(List<dynamic> strategies) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: _primarySoft, borderRadius: BorderRadius.circular(12)),
                      child: const Text('🧠', style: TextStyle(fontSize: 20)),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Strategi Belajarmu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _ink)),
                          SizedBox(height: 2),
                          Text('Strategi yang sudah kamu buka', style: TextStyle(fontSize: 12, color: _muted)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: strategies.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildStrategyCard(strategies[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStrategyCard(dynamic strategy) {
    final String label = strategy['learningStrategy'] ?? 'Strategi';
    final String keyCode = (strategy['keyCode'] ?? '').toString().toString();
    final String description = strategy['description'] ?? 'Belum ada deskripsi.';

    String emoji = '🔹';
    Color color = _primary;
    Color bgColor = _primarySoft;
    String category = 'Umum';

    if (keyCode.contains('time')) {
      emoji = '⏱️'; color = const Color(0xFFF59E0B); bgColor = const Color(0xFFFFFBEB); category = 'Manajemen Waktu';
    } else if (keyCode.contains('help')) {
      emoji = '🤝'; color = const Color(0xFFEC4899); bgColor = const Color(0xFFFCE7F3); category = 'Bantuan Sosial';
    } else if (keyCode.contains('organization')) {
      emoji = '🏗️'; color = const Color(0xFF3B82F6); bgColor = const Color(0xFFDBEAFE); category = 'Organisasi';
    } else if (keyCode.contains('elaboration')) {
      emoji = '🕸️'; color = const Color(0xFF8B5CF6); bgColor = const Color(0xFFF3E8FF); category = 'Elaborasi';
    } else if (keyCode.contains('rehearsal')) {
      emoji = '🧠'; color = const Color(0xFF10B981); bgColor = const Color(0xFFECFDF5); category = 'Hafalan';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _ink)),
                const SizedBox(height: 6),
                Text(description, style: const TextStyle(fontSize: 12.5, color: _muted, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM PAINTER UNTUK GARIS PUTUS-PUTUS & GUNUNG
// ═══════════════════════════════════════════════════════════════

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 6.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dash, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlowScenePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path poly(List<List<double>> pts) {
      final p = Path();
      for (var i = 0; i < pts.length; i++) {
        i == 0 ? p.moveTo(pts[i][0], pts[i][1]) : p.lineTo(pts[i][0], pts[i][1]);
      }
      return p..close();
    }

    // Layer gunung belakang
    canvas.drawPath(
      poly([
        [0, size.height], 
        [0, size.height * 0.7], 
        [size.width * 0.3, size.height * 0.4], 
        [size.width * 0.7, size.height * 0.8], 
        [size.width, size.height * 0.5], 
        [size.width, size.height]
      ]),
      Paint()..color = const Color(0xFFCBD2ED).withOpacity(0.6),
    );
    
    // Layer gunung depan
    canvas.drawPath(
      poly([
        [0, size.height], 
        [0, size.height * 0.85], 
        [size.width * 0.4, size.height * 0.6], 
        [size.width * 0.8, size.height * 0.9], 
        [size.width, size.height * 0.75], 
        [size.width, size.height]
      ]),
      Paint()..color = const Color(0xFFB1BBE2).withOpacity(0.6),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}