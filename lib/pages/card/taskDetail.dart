// import 'package:flutter/material.dart' hide Card;
// import 'package:flutter/services.dart';
// import 'package:gamatutor_kanban/model/card.dart';
// import 'package:gamatutor_kanban/model/cardlist.dart';
// import 'package:gamatutor_kanban/pages/card/editCard.dart';
// import 'package:gamatutor_kanban/pages/card/focusSession.dart';
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
// import 'package:gamatutor_kanban/service/cardService.dart';

// class TaskDetailPage extends StatefulWidget {
//   final Card card;
//   final Function(Card, CardList) onStartSubtask;
//   final Function(Card, CardList) onStopSubtask;
//   final VoidCallback onNavigateToReflection;
//   final Function(Card)? onEditCard;
//   final VoidCallback? onDeleteCard;

//   const TaskDetailPage({
//     super.key,
//     required this.card,
//     required this.onStartSubtask,
//     required this.onStopSubtask,
//     required this.onNavigateToReflection,
//     this.onEditCard,
//     this.onDeleteCard,
//   });

//   @override
//   State<TaskDetailPage> createState() => _TaskDetailPageState();
// }

// // 💡 Fungsi helper untuk menampilkan daftar kolaborator di Detail Tugas
// Widget _buildTaskCollaborators(List<dynamic>? collaborations) {
//   if (collaborations == null || collaborations.isEmpty) return const SizedBox.shrink();

//   return Container(
//     margin: const EdgeInsets.symmetric(vertical: 8),
//     padding: const EdgeInsets.all(14),
//     decoration: BoxDecoration(
//       color: Colors.white,
//       borderRadius: BorderRadius.circular(16),
//       border: Border.all(color: Colors.grey.shade200),
//       boxShadow: [
//         BoxShadow(
//           color: Colors.black.withValues(alpha: 0.02),
//           blurRadius: 8,
//           offset: const Offset(0, 2),
//         ),
//       ],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Kolaborator Tugas 👥',
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
//         ),
//         const SizedBox(height: 10),
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: collaborations.map((collab) {
//             String name = 'Teman';
//             if (collab is Map) {
//               final user = collab['user'] ?? collab['User'] ?? {};
//               name = user['username'] ?? user['name'] ?? 'Teman';
//             } else {
//               name = collab.userId ?? 'Teman';
//             }
//             return Chip(
//               avatar: CircleAvatar(
//                 backgroundColor: const Color(0xFF6366F1),
//                 child: Text(
//                   name.isNotEmpty ? name[0].toUpperCase() : 'U',
//                   style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//               ),
//               label: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
//               backgroundColor: const Color(0xFFEEF2FF),
//             );
//           }).toList(),
//         ),
//       ],
//     ),
//   );
// }

// class _TaskDetailPageState extends State<TaskDetailPage> {
//   final CardService _cardService = CardService();
//   String? _strategyName;
//   bool _isLoadingStrategy = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadLearningStrategy();
//   }

//   Future<void> _loadLearningStrategy() async {
//     if (widget.card.learningId == null || widget.card.learningId!.isEmpty) {
//       if (mounted) {
//         setState(() {
//           _strategyName = 'Pomodoro';
//           _isLoadingStrategy = false;
//         });
//       }
//       return;
//     }

//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token != null) {
//         final strategy = await CardService.getStrategyById(token, widget.card.learningId!);
//         if (mounted) {
//           setState(() {
//             _strategyName = strategy?.learningStrategy ?? 'Pomodoro';
//             _isLoadingStrategy = false;
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _strategyName = 'Pomodoro';
//             _isLoadingStrategy = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _strategyName = 'Pomodoro';
//           _isLoadingStrategy = false;
//         });
//       }
//     }
//   }

//   // ★ FUNGSI KONFIRMASI HAPUS
//   void _showDeleteConfirmation() {
//     HapticFeedback.mediumImpact();
    
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         title: const Row(
//           children: [
//             Text('🗑️', style: TextStyle(fontSize: 24)),
//             SizedBox(width: 8),
//             Text('Hapus Tugas?', style: TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//         content: const Text(
//           'Tugas ini akan dihapus permanen beserta seluruh subtask dan catatannya. Kamu yakin?',
//           style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFFEF4444),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//               elevation: 0,
//             ),
//             onPressed: () {
//               Navigator.pop(dialogContext); // Tutup dialog
//               widget.onDeleteCard?.call(); // Panggil fungsi hapus dari parent (board.dart)
//               Navigator.pop(context, true); // Kembali ke Board
//             },
//             child: const Text('Ya, Hapus', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final card = widget.card;
//     final String currentColumn = card.computedColumn.toLowerCase();

//     final bool isTaskStarted = card.startTime != null;
//     final bool isStrikeThroughEnabled = currentColumn != 'planning';

//     // Konfigurasi Tombol Bawah
//     String bottomButtonText = 'Mulai Sesi Fokus';
//     Color bottomButtonColor = const Color(0xFF6366F1);
//     VoidCallback? onBottomButtonPressed;

//     if (currentColumn == 'planning') {
//       bottomButtonText = 'Mulai Sesi Fokus';
//       bottomButtonColor = const Color(0xFF6366F1);
//       onBottomButtonPressed = () => _handleStartSession();
//     } else if (currentColumn == 'monitoring') {
//       bottomButtonText = 'Lanjut Sesi Fokus';
//       bottomButtonColor = const Color(0xFF3B82F6);
//       onBottomButtonPressed = () => _handleResumeSession();
//     } else if (currentColumn == 'controlling') {
//       bottomButtonText = 'Mulai Reflection';
//       bottomButtonColor = const Color(0xFF10B981);
//       onBottomButtonPressed = widget.onNavigateToReflection;
//     } else if (currentColumn == 'reflection') {
//       bottomButtonText = 'Tugas Selesai 🎉';
//       bottomButtonColor = const Color(0xFF10B981);
//       onBottomButtonPressed = null;
//     }

//     final totalSub = card.subtasks.length;
//     final completedSub = card.subtasks.where((s) => s.endTimeList != null).length;
//     final double progressRatio = totalSub > 0 ? (completedSub / totalSub) : 0.0;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC), // Background abu terang
//       appBar: AppBar(
//         leading: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: CircleAvatar(
//             backgroundColor: Colors.white,
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
//               onPressed: () => Navigator.pop(context, true),
//             ),
//           ),
//         ),
//         title: const Text(
//           'Detail Tugas 📝',
//           style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w900),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ═══════════════════════════════════════════
//             // 1. HEADER (Status, Title, Strategy)
//             // ═══════════════════════════════════════════
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFEF3C7),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFFD97706)),
//                             const SizedBox(width: 4),
//                             Text(
//                               currentColumn.toUpperCase(),
//                               style: const TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
//                             ),
//                           ],
//                         ),
//                       ),
//                       // Strategy Badge
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFF3E8FF),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF9333EA)),
//                             const SizedBox(width: 4),
//                             _isLoadingStrategy
//                                 ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2))
//                                 : Text(
//                                     _strategyName ?? 'Pomodoro',
//                                     style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF9333EA)),
//                                   ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     card.title ?? 'Tanpa Judul',
//                     style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.3),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     card.courseName ?? 'Mata Kuliah',
//                     style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // ═══════════════════════════════════════════
//             // 2. BENTO GRID: Due Date & Priority
//             // ═══════════════════════════════════════════
//             Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Row(
//                           children: [
//                             Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF94A3B8)),
//                             SizedBox(width: 6),
//                             Text('Deadline', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           card.deadline != null ? '${card.deadline!.day}/${card.deadline!.month}/${card.deadline!.year}' : 'Tidak ada',
//                           style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Row(
//                           children: [
//                             Icon(Icons.flag_rounded, size: 14, color: Color(0xFF94A3B8)),
//                             SizedBox(width: 6),
//                             Text('Prioritas', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           card.priority?.toUpperCase() ?? 'MEDIUM',
//                           style: TextStyle(
//                             fontSize: 14, fontWeight: FontWeight.w900,
//                             color: card.priority?.toLowerCase() == 'high' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // ═══════════════════════════════════════════
//             // 3. DESKRIPSI & CATATAN
//             // ═══════════════════════════════════════════
//             if (card.description != null && card.description!.isNotEmpty) ...[
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Deskripsi 📄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
//                     const SizedBox(height: 8),
//                     Text(card.description!, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5)),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],

//             if (card.notes != null && card.notes!.isNotEmpty) ...[
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFDE68A))),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Row(
//                       children: [
//                         Icon(Icons.note_alt_rounded, size: 16, color: Color(0xFFD97706)),
//                         SizedBox(width: 6),
//                         Text('Catatan Fokus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(card.notes!, style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.5, fontStyle: FontStyle.italic)),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],

//             // ═══════════════════════════════════════════
//             // 4. SUBTASKS
//             // ═══════════════════════════════════════════
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text('Langkah Kecil 🪜', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
//                       Text('$completedSub/$totalSub', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(10),
//                     child: LinearProgressIndicator(
//                       value: currentColumn == 'planning' ? 0.0 : progressRatio,
//                       backgroundColor: const Color(0xFFF1F5F9),
//                       valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
//                       minHeight: 8,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   if (card.subtasks.isEmpty)
//                     const Padding(
//                       padding: EdgeInsets.all(8.0),
//                       child: Text('Belum ada langkah kecil.', style: TextStyle(fontSize: 12, color: Colors.grey)),
//                     )
//                   else
//                     ...card.subtasks.map((subtask) {
//                       final bool isDone = isStrikeThroughEnabled && (subtask.endTimeList != null);
//                       final bool isStarted = subtask.startTimeList != null;

//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                         decoration: BoxDecoration(
//                           color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFE2E8F0)),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
//                               color: isDone ? const Color(0xFF10B981) : Colors.grey.shade400,
//                               size: 20,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 subtask.subTitle ?? '',
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   fontWeight: isDone ? FontWeight.normal : FontWeight.w600,
//                                   color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF334155),
//                                   decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
                            
//                             // Tombol Play/Stop Subtask
//                             if (!isStarted && !isDone)
//                               InkWell(
//                                 onTap: () async {
//                                   await widget.onStartSubtask(card, subtask);
//                                   if (mounted) setState(() {});
//                                 },
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
//                                   child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
//                                 ),
//                               ),
//                             if (isStarted && !isDone)
//                               InkWell(
//                                 onTap: () async {
//                                   await widget.onStopSubtask(card, subtask);
//                                   if (mounted) setState(() {});
//                                 },
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
//                                   child: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
//                                 ),
//                               ),
//                             if (isDone)
//                               const Text('Selesai', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
//                           ],
//                         ),
//                       );
//                     }),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),

//             // ═══════════════════════════════════════════
//             // 5. REFERENCES (URL)
//             // ═══════════════════════════════════════════
//             if (card.urlCount > 0) ...[
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('Link Referensi 🔗', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
//                     const SizedBox(height: 12),
//                     ...card.urlList.map((urlItem) {
//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
//                         child: Row(
//                           children: [
//                             const Icon(Icons.link_rounded, size: 16, color: Color(0xFF3B82F6)),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 urlItem,
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6), decoration: TextDecoration.underline),
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//             ],
//           ],
//         ),
//       ),
      
//       // ═══════════════════════════════════════════
//       // BOTTOM NAVIGATION BAR (FLOATING STYLE)
//       // ═══════════════════════════════════════════
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
//         ),
//         child: SafeArea(
//           child: Row(
//             children: [
//               // Tombol Edit
//               Container(
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF1F5F9),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: IconButton(
//                   onPressed: (currentColumn == 'controlling' || currentColumn == 'reflection')
//                       ? null // Disable edit jika sudah selesai
//                       : () async {
//                           await Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => EditTaskPage(
//                                 card: widget.card,
//                                 onSaveUpdatedCard: (updatedCard) {
//                                   if (widget.onEditCard != null) {
//                                     widget.onEditCard!(updatedCard);
//                                   }
//                                 },
//                               ),
//                             ),
//                           );
//                           if (mounted) {
//                             setState(() => _isLoadingStrategy = true);
//                             _loadLearningStrategy();
//                           }
//                         },
//                   icon: Icon(
//                     Icons.edit_rounded,
//                     color: (currentColumn == 'controlling' || currentColumn == 'reflection')
//                         ? Colors.grey.shade400
//                         : const Color.fromARGB(255, 81, 84, 241),
//                     size: 20,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
              
//               // Tombol Utama (Fokus/Reflection)
//               Expanded(
//                 child: SizedBox(
//                   height: 50,
//                   child: ElevatedButton.icon(
//                     onPressed: onBottomButtonPressed,
//                     icon: Icon(
//                       currentColumn == 'planning' || currentColumn == 'monitoring' 
//                           ? Icons.play_circle_fill_rounded 
//                           : Icons.rate_review_rounded, 
//                       color: Colors.white, 
//                       size: 20
//                     ),
//                     label: Text(
//                       bottomButtonText,
//                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: bottomButtonColor,
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),

//               // Tombol Hapus
//               Container(
//                 decoration: BoxDecoration(
//                   color: isTaskStarted ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 child: IconButton(
//                   // ★ LOGIKA HAPUS: Jika sudah mulai (startTime != null), tombol mati.
//                   onPressed: isTaskStarted ? null : _showDeleteConfirmation,
//                   icon: Icon(
//                     Icons.delete_outline_rounded,
//                     color: isTaskStarted ? Colors.grey.shade400 : const Color(0xFFEF4444),
//                     size: 20,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // Fungsi untuk memulai sesi fokus dari planning
//   void _handleStartSession() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('Mulai Belajar? 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//         content: const Text('Kamu mau belajar card ini? Semua subtask akan langsung dimulai secara bersamaan.'),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
//             onPressed: () async {
//               Navigator.pop(dialogContext);
//               try {
//                 final token = await SecureTokenStorage.getToken();
//                 if (token != null) {
//                   final nowStr = DateTime.now().toIso8601String();
//                   if (widget.card.startTime == null) {
//                     await _cardService.updateCard(token, widget.card.cardId!, {
//                       'nmMatkul': widget.card.courseName ?? '',
//                       'title': widget.card.title ?? '',
//                       'description': widget.card.description ?? '',
//                       'learningId': widget.card.learningId ?? '',
//                       'priority': widget.card.priority ?? 'sedang',
//                       'difficulty': widget.card.difficulty ?? 'sedang',
//                       'deadline': widget.card.deadline != null ? widget.card.deadline!.toIso8601String().split('T')[0] : null,
//                       'startTime': nowStr,
//                     });
//                   }
//                   for (var sub in widget.card.subtasks) {
//                     if (sub.startTimeList == null && sub.clId != null) {
//                       await _cardService.updateCardList(token, widget.card.cardId!, sub.clId!, {'subTitle': sub.subTitle, 'startTimeList': nowStr});
//                       sub.startTimeList = DateTime.parse(nowStr);
//                     }
//                   }
//                   widget.card.startTime = DateTime.parse(nowStr);
//                 }
//               } catch (e) {
//                 debugPrint('Gagal mencatat start otomatis: $e');
//               }

//               if (!mounted) return;
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => FocusSessionPage(
//                     card: widget.card,
//                     onStartSubtask: widget.onStartSubtask,
//                     onStopSubtask: widget.onStopSubtask,
//                     onNavigateToReflection: () {
//                       Navigator.pop(context);
//                       widget.onNavigateToReflection();
//                     },
//                   ),
//                 ),
//               ).then((_) {
//                 if (mounted) setState(() {});
//               });
//             },
//             child: const Text('Ya, Mulai', style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   // Fungsi untuk lanjut sesi fokus dari monitoring
//   void _handleResumeSession() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => FocusSessionPage(
//           card: widget.card,
//           onStartSubtask: widget.onStartSubtask,
//           onStopSubtask: widget.onStopSubtask,
//           onNavigateToReflection: () {
//             Navigator.pop(context);
//             widget.onNavigateToReflection();
//           },
//         ),
//       ),
//     ).then((_) {
//       if (mounted) setState(() {});
//     });
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/pages/card/editCard.dart';
import 'package:gamatutor_kanban/pages/card/focusSession.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

// IMPORT REFERENSI UI BARU
import '../../utils/reference_ui/theme.dart';

// IMPORT UNTUK WEBSOCKET & API CLIENT (Sesuaikan path jika berbeda)
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_manager.dart';

class TaskDetailPage extends StatefulWidget {
  final Card card;
  final Function(Card, CardList) onStartSubtask;
  final Function(Card, CardList) onStopSubtask;
  final VoidCallback onNavigateToReflection;
  final Function(Card)? onEditCard;
  final VoidCallback? onDeleteCard;

  const TaskDetailPage({
    super.key,
    required this.card,
    required this.onStartSubtask,
    required this.onStopSubtask,
    required this.onNavigateToReflection,
    this.onEditCard,
    this.onDeleteCard,
  });

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final CardService _cardService = CardService();
  String? _strategyName;
  bool _isLoadingStrategy = true;

  // State untuk list teman
  List<dynamic> _friendsList = [];
  bool _isLoadingFriends = false;
  
  // State untuk WebSocket Sesi Fokus
  StreamSubscription? _focusWsSubscription;

  // 🎨 PALETTE
  static const _bg = Color(0xFFF5F5FF);
  static const _primary = Color(0xFF6C5CE7);
  static const _primarySoft = Color(0xFFEDE9FE);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFEEF0F5);

  @override
  void initState() {
    super.initState();
    _loadLearningStrategy();
    _loadFriendsData();
  }

  @override
  void dispose() {
    // Bersihkan listener WebSocket saat halaman ditutup
    _focusWsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLearningStrategy() async {
    if (widget.card.learningId == null || widget.card.learningId!.isEmpty) {
      if (mounted) {
        setState(() {
          _strategyName = 'Pomodoro';
          _isLoadingStrategy = false;
        });
      }
      return;
    }

    try {
      final token = await SecureTokenStorage.getToken();
      if (token != null) {
        final strategy = await CardService.getStrategyById(token, widget.card.learningId!);
        if (mounted) {
          setState(() {
            _strategyName = strategy?.learningStrategy ?? 'Pomodoro';
            _isLoadingStrategy = false;
          });
        }
      } else {
        if (mounted) setState(() { _strategyName = 'Pomodoro'; _isLoadingStrategy = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _strategyName = 'Pomodoro'; _isLoadingStrategy = false; });
    }
  }

  Future<void> _loadFriendsData() async {
    setState(() => _isLoadingFriends = true);
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'), 
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List rawFriendships = data['friendships'] ?? [];
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final currentUserId = decodedToken['userId'] ?? decodedToken['id'];

        List parsedFriends = [];
        for (var item in rawFriendships) {
          final requester = item['requester'] ?? {};
          final friend = item['friend'] ?? {};
          final targetUser = (requester['userId'] == currentUserId || requester['user_id'] == currentUserId) ? friend : requester;
          if (targetUser != null && targetUser.isNotEmpty) {
            parsedFriends.add({
              'userId': targetUser['userId'] ?? targetUser['user_id'],
              'username': targetUser['username'] ?? 'User',
              'name': '${targetUser['firstName'] ?? ''} ${targetUser['lastName'] ?? ''}'.trim(),
            });
          }
        }
        setState(() => _friendsList = parsedFriends);
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  void _showDeleteConfirmation() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Text('🗑️', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text('Hapus Tugas?', style: inter(size: 16, weight: FontWeight.w900, color: _ink)),
          ],
        ),
        content: Text(
          'Tugas ini akan dihapus permanen beserta seluruh subtask dan catatannya. Kamu yakin?', 
          style: inter(size: 13, color: _muted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: inter(size: 13, color: _muted, weight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onDeleteCard?.call();
              Navigator.pop(context, true);
            },
            child: Text('Ya, Hapus', style: inter(size: 13, color: Colors.white, weight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    
    // PERBAIKAN: Gunakan raw column (huruf kecil) untuk pengecekan logika
    final String currentColumnRaw = card.computedColumn;
    final String currentColumn = currentColumnRaw.toUpperCase();
    final bool isTaskStarted = card.startTime != null;
    final bool isStrikeThroughEnabled = currentColumnRaw != 'planning';

    String bottomButtonText = 'Mulai Sesi Fokus';
    Color bottomButtonColor = _primary;
    VoidCallback? onBottomButtonPressed;

    // PERBAIKAN: Pengecekan menggunakan currentColumnRaw
    if (currentColumnRaw == 'planning') {
      bottomButtonText = 'Mulai Sesi Fokus';
      bottomButtonColor = _primary;
      onBottomButtonPressed = () => _handleStartSession();
    } else if (currentColumnRaw == 'monitoring') {
      bottomButtonText = 'Lanjut Sesi Fokus';
      bottomButtonColor = const Color(0xFF3B82F6);
      onBottomButtonPressed = () => _handleResumeSession();
    } else if (currentColumnRaw == 'controlling') {
      bottomButtonText = 'Mulai Reflection';
      bottomButtonColor = const Color(0xFF10B981);
      onBottomButtonPressed = widget.onNavigateToReflection;
    } else if (currentColumnRaw == 'reflection') {
      bottomButtonText = 'Tugas Selesai 🎉';
      bottomButtonColor = const Color(0xFF10B981);
      onBottomButtonPressed = null;
    }

    final totalSub = card.subtasks.length;
    final completedSub = card.subtasks.where((s) => s.endTimeList != null).length;
    final double progressRatio = totalSub > 0 ? (completedSub / totalSub) : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _border),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 18),
              onPressed: () => Navigator.pop(context, true),
            ),
          ),
        ),
        title: Text('Detail Tugas', style: inter(size: 18, weight: FontWeight.w900, color: _ink)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (Status, Title, Strategy)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.show_chart_rounded, size: 14, color: Color(0xFFD97706)),
                            const SizedBox(width: 4),
                            Text(currentColumn, style: inter(size: 10, weight: FontWeight.w900, color: const Color(0xFFD97706), spacing: 0.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: _primarySoft, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 14, color: _primary),
                            const SizedBox(width: 4),
                            _isLoadingStrategy
                                ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
                                : Text(_strategyName ?? 'Pomodoro', style: inter(size: 10.5, weight: FontWeight.w900, color: _primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(card.title ?? 'Tanpa Judul', style: inter(size: 24, weight: FontWeight.w900, color: _ink, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(card.courseName ?? 'Mata Kuliah', style: inter(size: 13, weight: FontWeight.w600, color: _muted)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // BENTO GRID: Due Date & Priority
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 14, color: _muted),
                            const SizedBox(width: 6),
                            Text('Deadline', style: inter(size: 11, weight: FontWeight.bold, color: _muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.deadline != null ? '${card.deadline!.day}/${card.deadline!.month}/${card.deadline!.year}' : 'Tidak ada',
                          style: inter(size: 14, weight: FontWeight.w900, color: const Color(0xFFEF4444)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag_rounded, size: 14, color: _muted),
                            const SizedBox(width: 6),
                            Text('Prioritas', style: inter(size: 11, weight: FontWeight.bold, color: _muted)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.priority?.toUpperCase() ?? 'MEDIUM',
                          style: inter(
                            size: 14, weight: FontWeight.w900,
                            color: card.priority?.toUpperCase() == 'HIGH' ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // DESKRIPSI
            if (card.description != null && card.description!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deskripsi 📄', style: inter(size: 12, weight: FontWeight.bold, color: _muted)),
                    const SizedBox(height: 8),
                    Text(card.description!, style: inter(size: 13, color: _ink, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // KOLABORASI TEMAN
            if (card.collabList.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kolaborasi Teman 🤝', style: inter(size: 14, weight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: card.collabList.map((collab) {
                        String name = 'Teman';
                        final String cId = (collab is Map ? collab['userId'] : collab.userId).toString();
                        final match = _friendsList.firstWhere((f) => f['userId'].toString() == cId, orElse: () => null);
                        if (match != null) {
                          name = match['name'].toString().isNotEmpty ? match['name'] : match['username'];
                        }
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: _primary,
                            child: Text(name[0].toUpperCase(), style: inter(size: 10, color: Colors.white, weight: FontWeight.bold)),
                          ),
                          label: Text(name, style: inter(size: 12, weight: FontWeight.w600)),
                          backgroundColor: _bg,
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // CATATAN FOKUS
            if (card.notes != null && card.notes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.note_alt_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text('Catatan Fokus', style: inter(size: 12, weight: FontWeight.bold, color: const Color(0xFFD97706))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(card.notes!, style: inter(size: 13, color: const Color(0xFF92400E), height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // SUBTASKS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Langkah Kecil', style: inter(size: 14, weight: FontWeight.w900, color: _ink)),
                      Text('$completedSub/$totalSub', style: inter(size: 12, weight: FontWeight.w900, color: _primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: currentColumnRaw == 'planning' ? 0.0 : progressRatio,
                      backgroundColor: _primarySoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(_primary),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (card.subtasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Belum ada langkah kecil.', style: inter(size: 12, color: _muted)),
                    )
                  else
                    ...card.subtasks.map((subtask) {
                      final bool isDone = isStrikeThroughEnabled && (subtask.endTimeList != null);
                      final bool isStarted = subtask.startTimeList != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDone ? const Color(0xFFDCFCE7) : _border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              color: isDone ? const Color(0xFF10B981) : _muted.withOpacity(0.5),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subtask.subTitle ?? '',
                                style: inter(
                                  size: 13,
                                  weight: isDone ? FontWeight.normal : FontWeight.w600,
                                  color: isDone ? _muted : _ink,
                                  decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            if (!isStarted && !isDone)
                              InkWell(
                                onTap: () async {
                                  await widget.onStartSubtask(card, subtask);
                                  if (mounted) setState(() {});
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                                  child: const Icon(Icons.play_arrow_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            if (isStarted && !isDone)
                              InkWell(
                                onTap: () async {
                                  await widget.onStopSubtask(card, subtask);
                                  if (mounted) setState(() {});
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                  child: const Icon(Icons.stop_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            if (isDone)
                              Text('Selesai', style: inter(size: 10, color: const Color(0xFF10B981), weight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // REFERENCES (URL)
            if (card.urlCount > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Link Referensi 🔗', style: inter(size: 14, weight: FontWeight.w900, color: _ink)),
                    const SizedBox(height: 12),
                    ...card.urlList.map((urlItem) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.link_rounded, size: 16, color: _primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                urlItem,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: inter(size: 12, weight: FontWeight.w600, color: _primary, decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
      
      // BOTTOM NAVIGATION BAR
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Tombol Edit
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: (currentColumnRaw == 'controlling' || currentColumnRaw == 'reflection')
                      ? null 
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskPage(
                                card: widget.card,
                                onSaveUpdatedCard: (updatedCard) {
                                  if (widget.onEditCard != null) widget.onEditCard!(updatedCard);
                                },
                              ),
                            ),
                          );
                          if (mounted) {
                            setState(() => _isLoadingStrategy = true);
                            _loadLearningStrategy();
                          }
                        },
                  icon: Icon(
                    Icons.edit_rounded,
                    color: (currentColumnRaw == 'controlling' || currentColumnRaw == 'reflection') ? Colors.grey.shade400 : _primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // Tombol Utama
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onBottomButtonPressed,
                    icon: Icon(
                      currentColumnRaw == 'planning' || currentColumnRaw == 'monitoring' ? Icons.play_circle_fill_rounded : Icons.rate_review_rounded, 
                      color: Colors.white, size: 20
                    ),
                    label: Text(bottomButtonText, style: inter(size: 14, weight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bottomButtonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Tombol Hapus
              Container(
                decoration: BoxDecoration(
                  color: isTaskStarted ? const Color(0xFFF1F5F9) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  onPressed: isTaskStarted ? null : _showDeleteConfirmation,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: isTaskStarted ? Colors.grey.shade400 : const Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LOGIKA KONFIRMASI & IZIN KOLABORATOR ---
  void _handleStartSession() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text('Mulai Belajar? 🚀', style: inter(size: 16, weight: FontWeight.w900, color: _ink)),
        content: Text('Kamu mau belajar card ini? Semua subtask akan langsung dimulai secara bersamaan.', style: inter(size: 13, color: _muted, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: Text('Batal', style: inter(size: 13, color: _muted, weight: FontWeight.bold))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            onPressed: () async {
              Navigator.pop(dialogContext); // Tutup dialog konfirmasi
              await _requestFocusAndStart();
            },
            child: Text('Ya, Mulai', style: inter(size: 13, color: Colors.white, weight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestFocusAndStart() async {
    // 1. Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text("Meminta izin kolaborator...")),
          ],
        ),
      ),
    );

    try {
      // 2. Tembak API ke backend
      final response = await sl<ApiClient>().post('/cards/${widget.card.cardId}/request-focus');
      
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      final waiting = response.data['waiting'] as bool? ?? false;

      if (waiting) {
        // 3. Tunggu balasan WebSocket
        _focusWsSubscription = sl<WebSocketManager>().messageStream.listen((data) {
          final event = data['event'];
          
          if (event == 'focus:approved') {
            _focusWsSubscription?.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Disetujui! Memulai sesi fokus...'), backgroundColor: Colors.green)
              );
              _proceedToFocusSession(); // Lanjut masuk ke sesi
            }
          } else if (event == 'focus:rejected') {
            _focusWsSubscription?.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Ditolak oleh ${data['responderName'] ?? 'Kolaborator'}'), backgroundColor: Colors.red)
              );
            }
          }
        });
      } else {
        // Tidak ada kolaborator, langsung masuk
        _proceedToFocusSession();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meminta izin: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _proceedToFocusSession() async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token != null) {
        final nowStr = DateTime.now().toIso8601String();
        if (widget.card.startTime == null) {
          await _cardService.updateCard(token, widget.card.cardId!, {
            'nmMatkul': widget.card.courseName ?? '',
            'title': widget.card.title ?? '',
            'description': widget.card.description ?? '',
            'learningId': widget.card.learningId ?? '',
            'priority': widget.card.priority ?? 'sedang',
            'difficulty': widget.card.difficulty ?? 'sedang',
            'deadline': widget.card.deadline != null ? widget.card.deadline!.toIso8601String().split('T')[0] : null,
            'startTime': nowStr,
          });
        }
        for (var sub in widget.card.subtasks) {
          if (sub.startTimeList == null && sub.clId != null) {
            await _cardService.updateCardList(token, widget.card.cardId!, sub.clId!, {'subTitle': sub.subTitle, 'startTimeList': nowStr});
            sub.startTimeList = DateTime.parse(nowStr);
          }
        }
        widget.card.startTime = DateTime.parse(nowStr);
      }
    } catch (e) {
      debugPrint('Gagal mencatat start otomatis: $e');
    }

    if (!mounted) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusSessionPage(
          card: widget.card,
          onStartSubtask: widget.onStartSubtask,
          onStopSubtask: widget.onStopSubtask,
          onNavigateToReflection: () {
            Navigator.pop(context);
            widget.onNavigateToReflection();
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _handleResumeSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusSessionPage(
          card: widget.card,
          onStartSubtask: widget.onStartSubtask,
          onStopSubtask: widget.onStopSubtask,
          onNavigateToReflection: () {
            Navigator.pop(context);
            widget.onNavigateToReflection();
          },
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }
}