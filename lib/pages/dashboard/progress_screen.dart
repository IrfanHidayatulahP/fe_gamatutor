// import 'package:flutter/material.dart' hide Card;
// import 'package:gamatutor_kanban/model/card.dart';
// import 'package:gamatutor_kanban/model/Rekomendasi.dart';
// import 'package:fl_chart/fl_chart.dart';

// class ProgressScreen extends StatefulWidget {
//   final List<Card> cardsList;
//   final Rekomendasi? quizProfile;

//   const ProgressScreen({Key? key, required this.cardsList, this.quizProfile})
//     : super(key: key);

//   @override
//   State<ProgressScreen> createState() => _ProgressScreenState();
// }

// class _ProgressScreenState extends State<ProgressScreen> {
//   @override
//   Widget build(BuildContext context) {
//     List<Card> cards = widget.cardsList;

//     // ─── 1. DATA DASAR ───
//     int totalCards = cards.length;
//     int completedCards = cards
//         .where((c) => c.computedColumn.toLowerCase() == 'reflection')
//         .length;
//     double completionRate = totalCards > 0
//         ? (completedCards / totalCards) * 100
//         : 0;

//     int planningCount = cards
//         .where((c) => c.computedColumn.toLowerCase() == 'planning')
//         .length;
//     int monitoringCount = cards
//         .where((c) => c.computedColumn.toLowerCase() == 'monitoring')
//         .length;
//     int controllingCount = cards
//         .where((c) => c.computedColumn.toLowerCase() == 'controlling')
//         .length;
//     int reflectionCount = cards
//         .where((c) => c.computedColumn.toLowerCase() == 'reflection')
//         .length;

//     // ─── 2. DETEKSI TUGAS MACET (> 7 Hari) ───
//     final stalledCards = cards.where((c) {
//       final col = c.computedColumn.toLowerCase();
//       if (col == 'reflection') return false;
//       if (c.createdAt == null) return false;
//       final diff = DateTime.now().difference(c.createdAt!).inDays;
//       return diff > 7;
//     }).toList();

//     // ─── 3. DATA MSLQ ───
//     final scores = widget.quizProfile?.normalizedScores ?? {};
//     final categories = [
//       'organization',
//       'time_management',
//       'metacognitive_self_regulation',
//       'help_seeking',
//       'elaboration',
//       'rehearsal',
//     ];
//     final values = categories.map((c) {
//       final val = scores[c];
//       return val is num ? val?.toDouble() : 0.0;
//     }).toList();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         // ✅ 1. BUNGKUS DENGAN LAYOUTBUILDER UNTUK RESPONSIVE
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             // Jika lebar > 600 (Tablet), maka isTablet = true
//             final bool isTablet = constraints.maxWidth > 600;

//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Your Stats ✨',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w900,
//                     color: Color(0xFF0F172A),
//                   ),
//                 ),
//                 const SizedBox(height: 20),

//                 // ★ PERINGATAN TUGAS MACET (Jika Ada)
//                 if (stalledCards.isNotEmpty) ...[
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     margin: const EdgeInsets.only(bottom: 20),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFEF2F2),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: const Color(0xFFFECACA)),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.warning_amber_rounded,
//                               color: Color(0xFFEF4444),
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               '${stalledCards.length} Tugas Macet',
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                                 color: Color(0xFF991B1B),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           'Tugas ini udah nganggur > 7 hari. Yuk, mulai dikit-dikit!',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Color(0xFFB91C1C),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],

//                 // ★ HERO CARD (Completion Rate)
//                 Container(
//                   padding: const EdgeInsets.all(24),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [
//                       BoxShadow(
//                         color: const Color(0xFF8B5CF6).withOpacity(0.3),
//                         blurRadius: 20,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Completion Rate',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Text(
//                             '${completionRate.toInt()}%',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 40,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '$completedCards dari $totalCards Tugas',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.2),
//                           shape: BoxShape.circle,
//                         ),
//                         child: const Icon(
//                           Icons.emoji_events_rounded,
//                           color: Colors.white,
//                           size: 40,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 24),

//                 // ✅ 2. LOGIKA RESPONSIVE UNTUK WEEKLY RECAP & MISI
//                 if (isTablet) ...[
//                   // --- TAMPILAN TABLET: Berdampingan (Kiri & Kanan) ---
//                   IntrinsicHeight(
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         Expanded(child: _buildWeeklyRecap(cards)),
//                         const SizedBox(width: 12),
//                         Expanded(child: _buildDynamicTrainingMission()),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 24),
//                 ] else ...[
//                   // --- TAMPILAN HP: Weekly Recap Full Width di bawah Completion Rate ---
//                   _buildWeeklyRecap(cards),
//                   const SizedBox(height: 24),
//                 ],

//                 // ★ BENTO GRID: FOKUS & PROFIL KEMAMPUAN (Tetap Berdampingan)
//                 IntrinsicHeight(
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       // KIRI: FOKUS (Donut)
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Colors.white, Colors.white],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color.fromARGB(
//                                   255,
//                                   248,
//                                   248,
//                                   248,
//                                 ).withOpacity(0.3),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 5),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Fokus Kamu 🎯',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   SizedBox(
//                                     height: 120,
//                                     child: PieChart(
//                                       PieChartData(
//                                         sectionsSpace: 3,
//                                         centerSpaceRadius: 35,
//                                         sections: [
//                                           PieChartSectionData(
//                                             color: const Color(0xFF10B981),
//                                             value: reflectionCount.toDouble(),
//                                             radius: 15,
//                                             showTitle: false,
//                                           ),
//                                           PieChartSectionData(
//                                             color: const Color(0xFF3B82F6),
//                                             value: controllingCount.toDouble(),
//                                             radius: 15,
//                                             showTitle: false,
//                                           ),
//                                           PieChartSectionData(
//                                             color: const Color(0xFFF59E0B),
//                                             value: monitoringCount.toDouble(),
//                                             radius: 15,
//                                             showTitle: false,
//                                           ),
//                                           PieChartSectionData(
//                                             color: const Color(0xFFEF4444),
//                                             value: planningCount.toDouble(),
//                                             radius: 15,
//                                             showTitle: false,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 12),
//                               Column(
//                                 children: [
//                                   _buildLegend(
//                                     'Selesai',
//                                     const Color(0xFF10B981),
//                                     reflectionCount,
//                                   ),
//                                   _buildLegend(
//                                     'Cek',
//                                     const Color(0xFF3B82F6),
//                                     controllingCount,
//                                   ),
//                                   _buildLegend(
//                                     'Proses',
//                                     const Color(0xFFF59E0B),
//                                     monitoringCount,
//                                   ),
//                                   _buildLegend(
//                                     'Rencana',
//                                     const Color(0xFFEF4444),
//                                     planningCount,
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//                       // KANAN: PROFIL (Radar)
//                       Expanded(
//                         child: Container(
//                           padding: const EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Colors.white, Colors.white],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(20),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color.fromARGB(
//                                   255,
//                                   248,
//                                   248,
//                                   248,
//                                 ).withOpacity(0.3),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 5),
//                               ),
//                             ],
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Profil Kemampuan 🧠',
//                                     style: TextStyle(
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 16),
//                                   SizedBox(
//                                     height: 220,
//                                     child: RadarChart(
//                                       RadarChartData(
//                                         dataSets: [
//                                           // 1. Data Asli Anda
//                                           RadarDataSet(
//                                             fillColor: const Color(0xFF8B5CF6)
//                                                 .withOpacity(0.2),
//                                             borderColor: const Color(
//                                               0xFF8B5CF6,
//                                             ),
//                                             borderWidth: 2,
//                                             entryRadius: 2,
//                                             dataEntries: values
//                                                 .map(
//                                                   (v) => RadarEntry(
//                                                     value: v ?? 0.0,
//                                                   ),
//                                                 )
//                                                 .toList(),
//                                           ),
//                                           // 2. ✅ DATA BAYANGAN (Memaksa skala 0-100 agar tidak jadi titik)
//                                           RadarDataSet(
//                                             fillColor: Colors.transparent,
//                                             borderColor: Colors.transparent,
//                                             borderWidth: 0,
//                                             entryRadius: 0,
//                                             dataEntries: const [
//                                               RadarEntry(value: 100),
//                                               RadarEntry(value: 100),
//                                               RadarEntry(value: 100),
//                                               RadarEntry(value: 100),
//                                               RadarEntry(value: 100),
//                                               RadarEntry(value: 100),
//                                             ],
//                                           ),
//                                         ],
//                                         radarShape: RadarShape.polygon,
//                                         radarBackgroundColor:
//                                             Colors.transparent,
//                                         borderData: FlBorderData(show: false),
//                                         radarBorderData: BorderSide(
//                                           color: Colors.grey.withOpacity(0.2),
//                                         ),
//                                         titlePositionPercentageOffset: 0.15,
//                                         getTitle: (index, angle) {
//                                           const shortLabels = [
//                                             'Organisasi 🏗️',
//                                             'Waktu ⚔️',
//                                             'Metakognitif 🪞',
//                                             'Bantuan 🤝',
//                                             'Elaborasi 🧠',
//                                             'Latihan 📚',
//                                           ];
//                                           return RadarChartTitle(
//                                             text: shortLabels[index],
//                                             angle: 0,
//                                           );
//                                         },
//                                         titleTextStyle: const TextStyle(
//                                           fontSize: 8,
//                                           color: Colors.grey,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                         tickCount: 2,
//                                         ticksTextStyle: const TextStyle(
//                                           color: Colors.transparent,
//                                         ),
//                                         tickBorderData: BorderSide(
//                                           color: Colors.grey.withOpacity(0.1),
//                                         ),
//                                         gridBorderData: BorderSide(
//                                           color: Colors.grey.withOpacity(0.1),
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ✅ 3. FOOTER (Misi Latihan di bawah khusus HP)
//                 if (!isTablet) ...[
//                   const SizedBox(height: 24),
//                   _buildDynamicTrainingMission(),
//                 ],
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildLegend(String label, Color color, int count) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6),
//       child: Row(
//         children: [
//           Container(
//             width: 8,
//             height: 8,
//             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               label,
//               style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
//             ),
//           ),
//           Text(
//             '$count',
//             style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   Map<String, dynamic> _getStrategyInfo(String? key) {
//     switch (key?.toLowerCase()) {
//       case 'organization':
//         return {'name': 'Organization', 'emoji': '🏗️'};
//       case 'time_management':
//         return {'name': 'Time Management', 'emoji': '⚔️'};
//       case 'metacognitive_self_regulation':
//         return {'name': 'Metacognitive', 'emoji': '🪞'};
//       case 'help_seeking':
//         return {'name': 'Help Seeking', 'emoji': '🤝'};
//       case 'elaboration':
//         return {'name': 'Elaboration', 'emoji': '🧠'};
//       case 'rehearsal':
//         return {'name': 'Rehearsal', 'emoji': '📚'};
//       default:
//         return {'name': 'Misterius', 'emoji': '❓'};
//     }
//   }

//   Widget _buildDynamicTrainingMission() {
//   if (widget.quizProfile == null || !widget.quizProfile!.hasQuiz) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
//       ),
//       child: const Center(child: Text('Belum ada profil.', style: TextStyle(fontSize: 14, color: Colors.grey))),
//     );
//   }

//   // ✅ Cek apakah dia The All-Rounder
//   final bool isAllRounder = widget.quizProfile!.userProfile?.toLowerCase().contains('all-rounder') ?? false;
  
//   final strongestKey = widget.quizProfile!.dominantStrategy;
//   final strongestInfo = _getStrategyInfo(strongestKey);
//   final unlocked = widget.quizProfile!.unlockedFeatures;

//   // Jika semua kemampuan sudah seimbang (tidak ada yang di-unlock)
//   if (unlocked.isEmpty) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const Text('🌟', style: TextStyle(fontSize: 32)),
//           const SizedBox(height: 12),
//           Text(
//             isAllRounder 
//               ? 'Kamu The All-Rounder! Semua strategimu seimbang dan sangat baik.' 
//               : 'Kemampuanmu sudah seimbang!',
//             textAlign: TextAlign.center,
//             style: const TextStyle(fontSize: 14, color: Color(0xFF047857), fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   // ... (Sisa kode untuk menampilkan Chips misi latihan tetap sama seperti sebelumnya)
//   final List<Map<String, dynamic>> weakestInfos = unlocked.map((key) => _getStrategyInfo(key)).toList();

//   return Container(
//     // ... (Kode Container Misi Latihan Anda)
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: const [
//             Icon(Icons.track_changes_rounded, color: Color(0xFF8B5CF6), size: 20),
//             SizedBox(width: 8),
//             Text('Misi Latihan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
//           ],
//         ),
//         const SizedBox(height: 12),
//         RichText(
//           text: TextSpan(
//             style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
//             children: [
//               // ✅ Ubah teks jika dia All-Rounder
//               if (isAllRounder)
//                 const TextSpan(
//                   text: 'Kamu sudah sangat hebat di semua bidang! 🌟\nNamun, kamu masih bisa memoles beberapa strategi berikut:',
//                   style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
//                 )
//               else ...[
//                 const TextSpan(text: 'Kamu hebat dalam '),
//                 TextSpan(
//                   text: '${strongestInfo['name']} ${strongestInfo['emoji']}',
//                   style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
//                 ),
//                 const TextSpan(text: '.\n\nTapi, strategi berikut masih perlu ditingkatkan:'),
//               ]
//             ],
//           ),
//         ),
//         const SizedBox(height: 12),
        
//         // Chips Misi
//         Wrap(
//           spacing: 8,
//           runSpacing: 8,
//           children: weakestInfos.map((info) {
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFEF2F2),
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: const Color(0xFFFECACA)),
//               ),
//               child: Text(
//                 '${info['name']} ${info['emoji']}',
//                 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
//               ),
//             );
//           }).toList(),
//         ),
//         const SizedBox(height: 12),
//         const Text(
//           'Yuk, fokus latih itu bulan ini agar belajarmu lebih seimbang!',
//           style: TextStyle(fontSize: 12, color: Color(0xFF475569), fontStyle: FontStyle.italic),
//         ),
//       ],
//     ),
//   );
// }

//   Widget _buildWeeklyRecap(List<Card> cards) {
//     final now = DateTime.now();

//     // Tentukan awal minggu ini (Senin) dan awal minggu lalu
//     final startOfWeek = DateTime(
//       now.year,
//       now.month,
//       now.day,
//     ).subtract(Duration(days: now.weekday - 1));
//     final startOfLastWeek = startOfWeek.subtract(const Duration(days: 7));

//     int completedThisWeek = 0;
//     int completedLastWeek = 0;
//     double focusHoursThisWeek = 0;

//     for (var card in cards) {
//       // ★ 1. Ambil data sebagai String
//       final String? compDateStr = card.reflectionCompletedAt;

//       if (compDateStr != null && compDateStr.isNotEmpty) {
//         // ★ 2. Ubah String menjadi DateTime (gunakan tryParse agar tidak crash jika format salah)
//         final DateTime? compDate = DateTime.tryParse(compDateStr);

//         if (compDate != null) {
//           // Cek apakah selesai minggu ini
//           if (compDate.isAfter(startOfWeek) ||
//               compDate.isAtSameMomentAs(startOfWeek)) {
//             completedThisWeek++;

//             // Hitung total jam fokus minggu ini
//             final String? startTimeStr = card.startTime.toString();
//             if (startTimeStr != null && startTimeStr.isNotEmpty) {
//               final DateTime? startTime = DateTime.tryParse(startTimeStr);
//               if (startTime != null) {
//                 focusHoursThisWeek +=
//                     compDate.difference(startTime).inMinutes / 60.0;
//               }
//             }
//           }
//           // Cek apakah selesai minggu lalu
//           else if (compDate.isAfter(startOfLastWeek) ||
//               compDate.isAtSameMomentAs(startOfLastWeek)) {
//             completedLastWeek++;
//           }
//         }
//       }
//     }

//     // Hitung tren (naik/turun) dengan nada yang empatik
//     int trend = completedThisWeek - completedLastWeek;
//     String trendText;
//     Color trendBgColor;

//     if (trend > 0) {
//       trendText = 'Mantap! Naik $trend tugas dari minggu lalu. Pertahankan! 🔥';
//       trendBgColor = const Color.fromARGB(
//         255,
//         68,
//         120,
//         223,
//       ).withOpacity(0.2); // Hijau
//     } else if (trend < 0) {
//       trendText = 'Sepertinya minggu ini berat ya? Nggak apa-apa, istirahat sejenak itu penting. 💙';
//       trendBgColor = const Color(0xFFF59E0B).withOpacity(0.2); // Oranye
//     } else {
//       trendText =
//           'Progres stabil. Yuk, coba selesaikan 1 tugas lagi minggu depan! ✨';
//       trendBgColor = const Color.fromARGB(255, 176, 105, 217).withOpacity(0.15);
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Colors.white, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: const Color.fromARGB(255, 248, 248, 248).withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Row(
//                   children: [
//                     const Text('📅', style: TextStyle(fontSize: 18)),
//                     const SizedBox(width: 8),
//                     Flexible(
//                       child: const Text(
//                         'Weekly Recap',
//                         style: TextStyle(
//                           color: Color.fromARGB(255, 0, 0, 0),
//                           fontSize: 16,
//                           fontWeight: FontWeight.w900,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                         maxLines: 1,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(
//                     0.1,
//                   ), // (Opsional) Ubah warna agar kontras
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   'Minggu Ini',
//                   style: TextStyle(
//                     color: Color.fromARGB(255, 0, 0, 0),
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '$completedThisWeek',
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontSize: 36,
//                         fontWeight: FontWeight.w900,
//                         height: 1.0,
//                       ),
//                     ),
//                     const Text(
//                       'Tugas Selesai',
//                       style: TextStyle(color: Colors.black45, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       '${focusHoursThisWeek.toStringAsFixed(1)}j',
//                       style: const TextStyle(
//                         color: Colors.black,
//                         fontSize: 36,
//                         fontWeight: FontWeight.w900,
//                         height: 1.0,
//                       ),
//                     ),
//                     const Text(
//                       'Jam Fokus',
//                       style: TextStyle(color: Colors.black45, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//             decoration: BoxDecoration(
//               color: trendBgColor,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Text(
//               trendText,
//               style: const TextStyle(
//                 color: Colors.black54,
//                 fontSize: 12,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/Rekomendasi.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressScreen extends StatefulWidget {
  final List<Card> cardsList;
  final Rekomendasi? quizProfile;

  const ProgressScreen({super.key, required this.cardsList, this.quizProfile});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // 🎨 PALETTE
  static const _bg = Color(0xFFF5F5FF);
  static const _primary = Color(0xFF6C5CE7);
  static const _primarySoft = Color(0xFFEDE9FE);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFEEF0F5);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final cards = widget.cardsList;

    // ─── DATA ───
    final totalCards = cards.length;
    final completedCards = cards
        .where((c) => c.computedColumn.toString() == 'reflection')
        .length;
    final completionRate =
        totalCards > 0 ? (completedCards / totalCards) * 100 : 0.0;

    final planningCount =
        cards.where((c) => c.computedColumn.toString() == 'planning').length;
    final monitoringCount = cards
        .where((c) => c.computedColumn.toString() == 'monitoring')
        .length;
    final controllingCount = cards
        .where((c) => c.computedColumn.toString() == 'controlling')
        .length;
    final reflectionCount = cards
        .where((c) => c.computedColumn.toString() == 'reflection')
        .length;

    // Deteksi tugas macet
    final stalledCards = cards.where((c) {
      final col = c.computedColumn.toString();
      if (col == 'reflection' || c.createdAt == null) return false;
      return DateTime.now().difference(c.createdAt!).inDays > 7;
    }).toList();

    // MSLQ scores
    final scores = widget.quizProfile?.normalizedScores ?? {};
    const categories = [
      'organization',
      'time_management',
      'metacognitive_self_regulation',
      'help_seeking',
      'elaboration',
      'rehearsal',
    ];
    final values = categories.map((c) {
      final val = scores[c];
      return val is num ? val!.toDouble() : 0.0;
    }).toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 20),

                  // ★ HERO
                  _buildHero(completionRate, completedCards, totalCards),
                  const SizedBox(height: 16),

                  // ★ STAT PILLS
                  _buildStatPills(
                    total: totalCards,
                    completed: completedCards,
                    stalled: stalledCards.length,
                    rate: completionRate,
                  ),
                  const SizedBox(height: 20),

                  // ★ STALLED WARNING (soft style)
                  if (stalledCards.isNotEmpty) ...[
                    _buildStalledCard(stalledCards.length),
                    const SizedBox(height: 16),
                  ],

                  // ★ WEEKLY + MISI
                  if (isTablet)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildWeeklyRecap(cards)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDynamicTrainingMission()),
                        ],
                      ),
                    )
                  else ...[
                    _buildWeeklyRecap(cards),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 20),

                  // ★ BENTO CHARTS
                  _buildSectionTitle('Insight Belajarmu 📊'),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _buildFokusCard(
                            reflection: reflectionCount,
                            controlling: controllingCount,
                            monitoring: monitoringCount,
                            planning: planningCount,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: _buildRadarCard(values)),
                      ],
                    ),
                  ),

                  if (!isTablet) ...[
                    const SizedBox(height: 16),
                    _buildDynamicTrainingMission(),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════
  // 🧩 WIDGETS
  // ═════════════════════════════════════════════

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Your Progress',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _ink,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Terus tumbuh setiap hari 🌱',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.notifications_none_rounded,
              color: _ink, size: 20),
        ),
      ],
    );
  }

  Widget _buildHero(double rate, int completed, int total) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6C5CE7), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // decorative circle
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Learn Together. Level Up Together 🚀',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Completion Rate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${rate.toInt()}%',
                          style: const TextStyle(
                            fontSize: 44,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '$completed dari $total tugas selesai ✨',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // icon badge
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.5),
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (rate / 100).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPills({
    required int total,
    required int completed,
    required int stalled,
    required double rate,
  }) {
    final items = [
      _StatPill(
          icon: Icons.grid_view_rounded,
          label: 'Tugas',
          value: '$total',
          color: _primary,
          bg: _primarySoft),
      _StatPill(
          icon: Icons.check_circle_rounded,
          label: 'Selesai',
          value: '$completed',
          color: _green,
          bg: const Color(0xFFECFDF5)),
      _StatPill(
          icon: Icons.warning_amber_rounded,
          label: 'Macet',
          value: '$stalled',
          color: _amber,
          bg: const Color(0xFFFFFBEB)),
      _StatPill(
          icon: Icons.insights_rounded,
          label: 'Progress',
          value: '${rate.toInt()}%',
          color: _blue,
          bg: const Color(0xFFEFF6FF)),
    ];

    return Row(
      children: items
          .map((p) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: p.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(p.icon, size: 16, color: p.color),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        Text(
                          p.label,
                          style: const TextStyle(
                              fontSize: 10, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildStalledCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.snooze_rounded, color: _amber, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count tugas butuh perhatian',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Sudah menganggur > 7 hari. Yuk cicil perlahan 💪',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w900,
        color: _ink,
        letterSpacing: -0.3,
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  // ─── FOKUS DONUT ───
  Widget _buildFokusCard({
    required int reflection,
    required int controlling,
    required int monitoring,
    required int planning,
  }) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🎯', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(
                'Fokus Kamu',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 32,
                sections: [
                  PieChartSectionData(
                      color: _green,
                      value: reflection.toDouble(),
                      radius: 14,
                      showTitle: false),
                  PieChartSectionData(
                      color: _blue,
                      value: controlling.toDouble(),
                      radius: 14,
                      showTitle: false),
                  PieChartSectionData(
                      color: _amber,
                      value: monitoring.toDouble(),
                      radius: 14,
                      showTitle: false),
                  PieChartSectionData(
                      color: _red,
                      value: planning.toDouble(),
                      radius: 14,
                      showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildLegend('Selesai', _green, reflection),
          _buildLegend('Cek', _blue, controlling),
          _buildLegend('Proses', _amber, monitoring),
          _buildLegend('Rencana', _red, planning),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  color: _muted,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _ink),
          ),
        ],
      ),
    );
  }

  // ─── RADAR ───
  Widget _buildRadarCard(List<double> values) {
    return _card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text('🧠', style: TextStyle(fontSize: 14)),
              SizedBox(width: 6),
              Text(
                'Profil Kemampuan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: _primary.withOpacity(0.18),
                    borderColor: _primary,
                    borderWidth: 2,
                    entryRadius: 2,
                    dataEntries: values
                        .map((v) => RadarEntry(value: v))
                        .toList(),
                  ),
                  RadarDataSet(
                    fillColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    entryRadius: 0,
                    dataEntries: List.generate(
                        6, (_) => const RadarEntry(value: 100)),
                  ),
                ],
                radarShape: RadarShape.polygon,
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData:
                    BorderSide(color: Colors.grey.withOpacity(0.15)),
                titlePositionPercentageOffset: 0.15,
                getTitle: (index, angle) {
                  const labels = [
                    'Org 🏗️',
                    'Waktu ⚔️',
                    'Meta 🪞',
                    'Bantu 🤝',
                    'Elab 🧠',
                    'Latih 📚',
                  ];
                  return RadarChartTitle(
                      text: labels[index], angle: 0);
                },
                titleTextStyle: const TextStyle(
                  fontSize: 8,
                  color: _muted,
                  fontWeight: FontWeight.bold,
                ),
                tickCount: 2,
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent),
                tickBorderData:
                    BorderSide(color: Colors.grey.withOpacity(0.08)),
                gridBorderData:
                    BorderSide(color: Colors.grey.withOpacity(0.08)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MISI LATIHAN ───
  Map<String, dynamic> _getStrategyInfo(String? key) {
    switch (key?.toString()) {
      case 'organization':
        return {'name': 'Organization', 'emoji': '🏗️'};
      case 'time_management':
        return {'name': 'Time Management', 'emoji': '⚔️'};
      case 'metacognitive_self_regulation':
        return {'name': 'Metacognitive', 'emoji': '🪞'};
      case 'help_seeking':
        return {'name': 'Help Seeking', 'emoji': '🤝'};
      case 'elaboration':
        return {'name': 'Elaboration', 'emoji': '🧠'};
      case 'rehearsal':
        return {'name': 'Rehearsal', 'emoji': '📚'};
      default:
        return {'name': 'Misterius', 'emoji': '❓'};
    }
  }

  Widget _buildDynamicTrainingMission() {
    if (widget.quizProfile == null || !widget.quizProfile!.hasQuiz) {
      return _card(
        child: const Center(
          child: Text(
            'Belum ada profil kuis 📝',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    final isAllRounder = widget.quizProfile!.userProfile
            ?.toString()
            .contains('all-rounder') ??
        false;
    final strongestInfo =
        _getStrategyInfo(widget.quizProfile!.dominantStrategy);
    final unlocked = widget.quizProfile!.unlockedFeatures;

    if (unlocked.isEmpty) {
      return _card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌟', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text(
              isAllRounder
                  ? 'Kamu The All-Rounder! Semua strategimu seimbang 🌟'
                  : 'Kemampuanmu sudah seimbang!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF047857),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.track_changes_rounded,
                  color: _primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Misi Latihan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.5,
              ),
              children: [
                if (isAllRounder)
                  const TextSpan(
                    text:
                        'Kamu hebat di semua bidang! 🌟\nMasih bisa poles strategi ini:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _green,
                    ),
                  )
                else ...[
                  const TextSpan(text: 'Kamu hebat dalam '),
                  TextSpan(
                    text:
                        '${strongestInfo['name']} ${strongestInfo['emoji']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _green,
                    ),
                  ),
                  const TextSpan(text: '.\nPerlu ditingkatkan:'),
                ]
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: unlocked.map((key) {
              final info = _getStrategyInfo(key);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  '${info['name']} ${info['emoji']}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            'Yuk fokus latih itu bulan ini 💪',
            style: TextStyle(
              fontSize: 11,
              color: _muted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── WEEKLY RECAP ───
  Widget _buildWeeklyRecap(List<Card> cards) {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek =
        startOfWeek.subtract(const Duration(days: 7));

    int completedThisWeek = 0;
    int completedLastWeek = 0;
    double focusHours = 0;

    for (var card in cards) {
      final compDateStr = card.reflectionCompletedAt;
      if (compDateStr == null || compDateStr.isEmpty) continue;
      final compDate = DateTime.tryParse(compDateStr);
      if (compDate == null) continue;

      if (compDate.isAfter(startOfWeek) ||
          compDate.isAtSameMomentAs(startOfWeek)) {
        completedThisWeek++;
        final startStr = card.startTime?.toString();
        if (startStr != null) {
          final st = DateTime.tryParse(startStr);
          if (st != null) {
            focusHours += compDate.difference(st).inMinutes / 60.0;
          }
        }
      } else if (compDate.isAfter(startOfLastWeek) ||
          compDate.isAtSameMomentAs(startOfLastWeek)) {
        completedLastWeek++;
      }
    }

    final trend = completedThisWeek - completedLastWeek;
    late String trendText;
    late Color trendBg;
    late Color trendColor;

    if (trend > 0) {
      trendText = 'Mantap! Naik $trend dari minggu lalu 🔥';
      trendBg = const Color(0xFFECFDF5);
      trendColor = const Color(0xFF047857);
    } else if (trend < 0) {
      trendText = 'Minggu berat? Istirahat itu penting 💙';
      trendBg = const Color(0xFFFFFBEB);
      trendColor = const Color(0xFFB45309);
    } else {
      trendText = 'Stabil! Yuk tambah 1 tugas lagi ✨';
      trendBg = _primarySoft;
      trendColor = const Color(0xFF4338CA);
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Text('📅', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 6),
                  Text(
                    'Weekly Recap',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Minggu Ini',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completedThisWeek',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Tugas Selesai',
                        style:
                            TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: _border,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${focusHours.toStringAsFixed(1)}j',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Jam Fokus',
                        style:
                            TextStyle(color: _muted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: trendBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trendText,
              style: TextStyle(
                color: trendColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper model
class _StatPill {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bg;
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
  });
}