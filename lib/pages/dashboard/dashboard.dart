// import 'dart:convert';

// import 'package:avatar_builder/avatar_builder.dart';
// import 'package:flutter/material.dart' hide Card;
// import 'package:gamatutor_kanban/model/Rekomendasi.dart';
// import 'package:gamatutor_kanban/model/avatar_models.dart';
// import 'package:gamatutor_kanban/model/user.dart';
// import 'package:gamatutor_kanban/pages/card/board.dart';
// import 'package:gamatutor_kanban/pages/dashboard/account_screen.dart';
// import 'package:gamatutor_kanban/pages/dashboard/goals_screen.dart';
// import 'package:gamatutor_kanban/pages/dashboard/progress_screen.dart';
// import 'package:gamatutor_kanban/pages/kolaborasi/collaboration_screen.dart';
// import 'package:gamatutor_kanban/pages/notifikasi/notifikasi.dart';
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
// import 'package:gamatutor_kanban/service/avatarService.dart' as AvatarService;
// import 'package:gamatutor_kanban/service/cardService.dart';
// import 'package:gamatutor_kanban/model/card.dart';
// import 'package:gamatutor_kanban/service/rekomendasiService.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// import 'package:gamatutor_kanban/service/activityLogService.dart';

// import 'package:gamatutor_kanban/pages/card/newCard.dart'; 

// class Dashboard extends StatefulWidget {
//   final User? user;
//   const Dashboard({super.key, this.user});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   int _selectedIndex = 0;
//   User? _currentUser;
//   Rekomendasi? _quizProfile;
//   bool _isLoadingProfile = true;
//   bool _isLoading = true;

//   List<Card> _cardsList = [];
//   Avataaar? _currentAvatar;
  
//   // State untuk mengontrol menu pop-up FAB
//   bool _isFabExpanded = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentUser = widget.user;
//     if (_currentUser == null) {
//       _restoreUserFromStorage();
//     }
//     _loadAllData();
//     _loadAvatar();
//   }

//   Future<void> _loadAvatar() async {
//     try {
//       final configJson = await AvatarService.getUserAvatarConfig();
//       if (configJson != null) {
//         final config = AvatarConfig.fromJson(configJson);
//         setState(() {
//           _currentAvatar = config.toAvataaar();
//         });
//       } else {
//         setState(() {
//           _currentAvatar = Avataaar.random();
//         });
//       }
//     } catch (e) {
//       debugPrint('Gagal load avatar: $e');
//     }
//   }

//   Future<void> _loadAllData() async {
//     await Future.wait([_loadDashboardData(), _loadQuizProfile()]);
//   }

//   Future<void> _restoreUserFromStorage() async {
//     final userJsonStr = await SecureTokenStorage.getUserJson();
//     if (userJsonStr != null) {
//       final userData = jsonDecode(userJsonStr);
//       setState(() {
//         _currentUser = User.fromJson(userData);
//       });
//     }
//   }

//   Future<void> _loadQuizProfile() async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         setState(() => _isLoadingProfile = false);
//         return;
//       }
//       Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//       final String userId = decodedToken['userId'] ?? decodedToken['id'];
//       final profile = await rekomendasiService.getLatestRecommendation(userId);
//       if (mounted) {
//         setState(() {
//           _quizProfile = profile;
//           _isLoadingProfile = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Gagal load quiz profile: $e');
//       if (mounted) setState(() => _isLoadingProfile = false);
//     }
//   }

//   Future<void> _loadDashboardData() async {
//     setState(() => _isLoading = true);
//     final token = await SecureTokenStorage.getToken();
//     if (token != null) {
//       try {
//         final apiCards = await CardService().getCardsByUser(token);
//         if (apiCards.isNotEmpty && mounted) {
//           setState(() {
//             _cardsList = apiCards;
//             _isLoading = false;
//           });
//           return;
//         }
//       } catch (e) {
//         debugPrint('Koneksi ke database gagal: $e');
//       }
//     }
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }

//   int get _completedTaskCount {
//     return _cardsList.where((card) {
//       final col = (card.computedColumn).toLowerCase();
//       return col == 'reflection' || col == 'done' || col == 'completed';
//     }).length;
//   }

//   // Fungsi untuk membuka halaman AddCardView
//   void _navigateToAddCard() async {
//     final token = await SecureTokenStorage.getToken();
//     if (token == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Sesi login habis, silakan login ulang.')),
//         );
//       }
//       return;
//     }

//     if (!mounted) return;

//     // Navigasi ke AddCardView
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AddCardView(
//           token: token,
//           onCardCreated: (payload) async {
//             // 👇 LOGIKA PENYIMPANAN CARD KE BACKEND
//             // Sesuaikan pemanggilan method createCard dengan service Anda
//             // Contoh:
//             // await CardService().createCard(token: token, data: payload);
            
//             // Untuk sementara kita print dulu payload-nya
//             debugPrint("PAYLOAD DARI NEWCARD: $payload");
            
//             // Jika API Anda belum siap, kita bisa simpan ke list lokal sementara
//             // agar dashboard langsung terupdate (opsional)
//           },
//         ),
//       ),
//     );

//     // Jika berhasil menyimpan (mengembalikan true), refresh dashboard
//     if (result == true) {
//       _loadDashboardData(); // Refresh data card di dashboard
//     }
//   }

//   Widget _buildHomeView() {
//     return SingleChildScrollView(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildHeader(),
//           const SizedBox(height: 20),
//           _buildCollaborativeHeroCard(),
//           const SizedBox(height: 16),
//           _buildStatisticsRow(),
//           const SizedBox(height: 20),
//           _buildKanbanPreviewSection(),
//           const SizedBox(height: 24),
//           _buildTeamActivitySection(),
//           const SizedBox(height: 20),
//           _buildBottomPromoBanner(),
//           const SizedBox(height: 30),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Row(
//           children: [
//             Container(
//               width: 40,
//               height: 40,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: Colors.white,
//                 border: Border.all(color: const Color(0xFFE2E8F0)),
//               ),
//               child: IconButton(
//                 icon: const Icon(
//                   Icons.arrow_back_ios_new_rounded,
//                   color: Color(0xFF0F172A),
//                   size: 16,
//                 ),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Collaborative Kanban',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w800,
//                     color: Color(0xFF0F172A),
//                     letterSpacing: -0.5,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Row(
//                   children: const [
//                     Icon(Icons.people_alt_rounded, size: 12, color: Color(0xFF64748B)),
//                     SizedBox(width: 4),
//                     Text(
//                       'Ruang kerja belajar bersama tim',
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w500,
//                         color: Color(0xFF64748B),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//         Container(
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.white,
//             border: Border.all(color: const Color(0xFFE2E8F0)),
//           ),
//           child: IconButton(
//             icon: const Icon(
//               Icons.notifications_none_rounded,
//               color: Color(0xFF64748B),
//               size: 20,
//             ),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => NotificationScreen()),
//               );
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildCollaborativeHeroCard() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [
//             Color(0xFF6366F1),
//             Color(0xFF8B5CF6),
//             Color(0xFFA855F7),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: const Color(0xFF8B5CF6).withOpacity(0.35),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ],
//       ),
//       child: Stack(
//         children: [
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: const Text(
//                   'Learn Together. Level Up Together.',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               const Text(
//                 'Collaborative Kanban',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.w900,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               const SizedBox(
//                 width: 210,
//                 child: Text(
//                   'Buat, kelola, dan selesaikan tugas bersama tim dalam satu ruang belajar yang interaktif.',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 14),
//               const Text(
//                 'GAMATUTUR\nYour collaborative learning workspace.',
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontSize: 9,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 0.5,
//                 ),
//               ),
//             ],
//           ),
//           Positioned(
//             right: -10,
//             bottom: 0,
//             child: Icon(
//               Icons.groups_rounded,
//               size: 110,
//               color: Colors.white.withOpacity(0.15),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatisticsRow() {
//     return Row(
//       children: [
//         _statBox('10', 'Anggota Aktif', Icons.people_outline, const Color(0xFF8B5CF6)),
//         const SizedBox(width: 8),
//         _statBox('${_cardsList.isNotEmpty ? _completedTaskCount : 24}', 'Task Selesai', Icons.check_circle_outline, const Color(0xFF10B981)),
//         const SizedBox(width: 8),
//         _statBox('7', 'Streak Kolab', Icons.local_fire_department_outlined, const Color(0xFFF59E0B)),
//         const SizedBox(width: 8),
//         _statBox('92%', 'Progres Tim', Icons.trending_up_rounded, const Color(0xFF3B82F6)),
//       ],
//     );
//   }

//   Widget _statBox(String value, String label, IconData icon, Color color) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: const Color(0xFFE2E8F0)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.02),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             Icon(icon, color: color, size: 20),
//             const SizedBox(height: 6),
//             Text(
//               value,
//               style: const TextStyle(
//                 fontSize: 15,
//                 fontWeight: FontWeight.w900,
//                 color: Color(0xFF0F172A),
//               ),
//             ),
//             const SizedBox(height: 2),
//             Text(
//               label,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 9,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF64748B),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildKanbanPreviewSection() {
//     final planningCards = _cardsList.where((card) {
//       final col = card.computedColumn.toLowerCase();
//       return col == 'todo' || col == 'planning' || col == 'backlog';
//     }).toList();

//     final monitoringCards = _cardsList.where((card) {
//       final col = card.computedColumn.toLowerCase();
//       return col == 'in_progress' || col == 'monitoring' || col == 'doing';
//     }).toList();

//     final controllingCards = _cardsList.where((card) {
//       final col = card.computedColumn.toLowerCase();
//       return col == 'controlling' || col == 'review';
//     }).toList();

//     final reflectionCards = _cardsList.where((card) {
//       final col = card.computedColumn.toLowerCase();
//       return col == 'reflection' || col == 'done' || col == 'completed';
//     }).toList();

//     return SizedBox(
//       height: 280,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         physics: const BouncingScrollPhysics(),
//         children: [
//           _buildKanbanColumnContainer(
//             title: 'PLANNING',
//             color: const Color(0xFF8B5CF6),
//             cards: planningCards,
//           ),
//           const SizedBox(width: 12),
//           _buildKanbanColumnContainer(
//             title: 'MONITORING',
//             color: const Color(0xFF3B82F6),
//             cards: monitoringCards,
//           ),
//           const SizedBox(width: 12),
//           _buildKanbanColumnContainer(
//             title: 'CONTROLLING',
//             color: const Color(0xFFEC4899),
//             cards: controllingCards,
//           ),
//           const SizedBox(width: 12),
//           _buildKanbanColumnContainer(
//             title: 'REFLECTION',
//             color: const Color(0xFF10B981),
//             cards: reflectionCards,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildKanbanColumnContainer({
//     required String title,
//     required Color color,
//     required List<Card> cards,
//   }) {
//     return Container(
//       width: 160,
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF1F5F9),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   CircleAvatar(radius: 4, backgroundColor: color),
//                   const SizedBox(width: 6),
//                   Text(
//                     title,
//                     style: const TextStyle(
//                       fontSize: 10,
//                       fontWeight: FontWeight.w900,
//                       color: Color(0xFF0F172A),
//                     ),
//                   ),
//                 ],
//               ),
//               CircleAvatar(
//                 radius: 9,
//                 backgroundColor: const Color(0xFFE2E8F0),
//                 child: Text(
//                   '${cards.length}',
//                   style: const TextStyle(
//                     fontSize: 9,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.black54,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Expanded(
//             child: cards.isEmpty
//                 ? const Center(
//                     child: Text(
//                       'Belum ada task',
//                       style: TextStyle(
//                         fontSize: 10,
//                         color: Color(0xFF94A3B8),
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: cards.length > 3 ? 3 : cards.length,
//                     itemBuilder: (context, index) {
//                       final card = cards[index];
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: _kanbanCardItem(
//                           card.title ?? 'Tanpa Judul',
//                           card.subtasks.length.toString(),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _kanbanCardItem(String title, String commentsCount) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: const TextStyle(
//               fontSize: 10,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF0F172A),
//             ),
//           ),
//           const SizedBox(height: 6),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: const [
//                   CircleAvatar(radius: 6, backgroundColor: Color(0xFFCBD5E1)),
//                   SizedBox(width: 3),
//                   CircleAvatar(radius: 6, backgroundColor: Color(0xFF94A3B8)),
//                 ],
//               ),
//               Row(
//                 children: [
//                   const Icon(Icons.chat_bubble_outline_rounded, size: 9, color: Color(0xFF94A3B8)),
//                   const SizedBox(width: 2),
//                   Text(commentsCount, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
//                 ],
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTeamActivitySection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Aktivitas Tim',
//           style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
//         ),
//         const SizedBox(height: 2),
//         const Text(
//           'Lihat apa yang sedang dikerjakan tim Anda',
//           style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           height: 75,
//           child: ListView(
//             scrollDirection: Axis.horizontal,
//             children: [
//               _activityCard('Alex menambahkan task baru', '5 menit lalu', Icons.person),
//               const SizedBox(width: 10),
//               _activityCard('Mengubah status ke Progress', '15 menit lalu', Icons.update),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _activityCard(String text, String time, IconData icon) {
//     return Container(
//       width: 230,
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: const Color(0xFFE2E8F0)),
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 18,
//             backgroundColor: const Color(0xFFEEF2FF),
//             child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Text(
//                   text,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   time,
//                   style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBottomPromoBanner() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: const Color(0xFFC7D2FE)),
//       ),
//       child: Row(
//         children: [
//           const Text('🚀', style: TextStyle(fontSize: 28)),
//           const SizedBox(width: 12),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Belajar lebih efektif bersama tim!',
//                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
//                 ),
//                 SizedBox(height: 2),
//                 Text(
//                   'Kolaborasi, diskusi, dan dukungan tim akan membuat proses belajar lebih bermakna.',
//                   style: TextStyle(fontSize: 10, color: Color(0xFF4338CA), height: 1.3),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     Widget currentBody;
//     switch (_selectedIndex) {
//       case 0:
//         currentBody = _buildHomeView();
//         break;
//       case 1:
//         currentBody = KanbanBoardView();
//         break;
//       case 2:
//         currentBody = const GoalsScreen();
//         break;
//       case 3:
//         currentBody = ProgressScreen(
//           cardsList: _cardsList,
//           quizProfile: _quizProfile,
//         );
//         break;
//       case 4:
//         currentBody = AccountScreen(
//           currentUser: _currentUser,
//           quizProfile: _quizProfile,
//           userXp: 0,
//           currentAvatar: _currentAvatar,
//           onAvatarUpdated: _loadAvatar,
//         );
//         break;
//       default:
//         currentBody = _buildHomeView();
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF8FAFC),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             currentBody,
//             if (_isLoading)
//               Container(
//                 color: Colors.black.withOpacity(0.3),
//                 child: const Center(
//                   child: CircularProgressIndicator(color: Color(0xFF6366F1)),
//                 ),
//               ),
//           ],
//         ),
//       ),
      
//       // ==========================================
//       // FAB MENU
//       // ==========================================
//       floatingActionButton: Stack(
//         alignment: Alignment.bottomRight,
//         children: [
//           if (_isFabExpanded)
//             GestureDetector(
//               onTap: () => setState(() => _isFabExpanded = false),
//               child: Container(
//                 color: Colors.black.withOpacity(0.2),
//                 width: MediaQuery.of(context).size.width,
//                 height: MediaQuery.of(context).size.height,
//               ),
//             ),

//           if (_isFabExpanded)
//             Positioned(
//               bottom: 70,
//               right: 16,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: [
//                   Container(
//                     constraints: const BoxConstraints(maxWidth: 70),
//                     padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(35),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 12,
//                           offset: const Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // --- Menu 1: Add Card ---
//                         _buildFabMenuItem(
//                           icon: Icons.image_outlined, 
//                           label: 'Add Card',
//                           onTap: () {
//                             setState(() => _isFabExpanded = false);
//                             // 👇 ARAHKAN KE HALAMAN NEWCARD
//                             _navigateToAddCard(); 
//                           },
//                         ),
                        
//                         const SizedBox(height: 12),

//                         // --- Menu 2: Collaboration ---
//                         _buildFabMenuItem(
//                           icon: Icons.person_add_alt_1_outlined, 
//                           label: 'Collab',
//                           onTap: () {
//                             setState(() => _isFabExpanded = false);
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => const CollaborationScreen()),
//                             );
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//           FloatingActionButton(
//             backgroundColor: const Color(0xFF6366F1), 
//             elevation: 4,
//             shape: const CircleBorder(),
//             child: Icon(
//               _isFabExpanded ? Icons.close : Icons.add, 
//               color: Colors.white,
//               size: 28,
//             ),
//             onPressed: () {
//               setState(() {
//                 _isFabExpanded = !_isFabExpanded;
//               });
//             },
//           ),
//         ],
//       ),
      
//       bottomNavigationBar: _buildBottomNavigationBar(),
//     );
//   }

//   Widget _buildFabMenuItem({
//     required IconData icon,
//     required String label,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
//         child: Column(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF1F5F9), 
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 icon,
//                 color: const Color(0xFF475569), 
//                 size: 18,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 9,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF64748B),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNavigationBar() {
//     return Container(
//       decoration: const BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
//       ),
//       child: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });
//         },
//         type: BottomNavigationBarType.fixed,
//         backgroundColor: Colors.white,
//         selectedItemColor: const Color(0xFF2563EB),
//         unselectedItemColor: const Color(0xFF94A3B8),
//         selectedFontSize: 11,
//         unselectedFontSize: 11,
//         elevation: 0,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home_outlined),
//             activeIcon: Icon(Icons.home_rounded),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.view_kanban_outlined),
//             activeIcon: Icon(Icons.view_kanban_rounded),
//             label: 'Board',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.track_changes_outlined),
//             activeIcon: Icon(Icons.track_changes_rounded),
//             label: 'Goals',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.bar_chart_outlined),
//             activeIcon: Icon(Icons.bar_chart_rounded),
//             label: 'Progress',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_outline_rounded),
//             activeIcon: Icon(Icons.person_rounded),
//             label: 'Account',
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:convert';

import 'package:avatar_builder/avatar_builder.dart';
import 'package:flutter/material.dart' hide Card;
import 'package:gamatutor_kanban/model/Rekomendasi.dart';
import 'package:gamatutor_kanban/model/avatar_models.dart';
import 'package:gamatutor_kanban/model/user.dart';
import 'package:gamatutor_kanban/pages/card/board.dart';
import 'package:gamatutor_kanban/pages/dashboard/account_screen.dart';
import 'package:gamatutor_kanban/pages/dashboard/goals_screen.dart';
import 'package:gamatutor_kanban/pages/dashboard/progress_screen.dart';
import 'package:gamatutor_kanban/features/card_collab/ui/collaboration_screen.dart';
import 'package:gamatutor_kanban/pages/notifikasi/notifikasi.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/avatarService.dart' as AvatarService;
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/service/rekomendasiService.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:gamatutor_kanban/pages/card/newCard.dart'; 
import 'package:gamatutor_kanban/service/activityLogService.dart'; // ← SERVICE BARU

class Dashboard extends StatefulWidget {
  final User? user;
  const Dashboard({super.key, this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  User? _currentUser;
  Rekomendasi? _quizProfile;
  bool _isLoadingProfile = true;
  bool _isLoading = true;

  List<Card> _cardsList = [];
  Avataaar? _currentAvatar;
  
  // State untuk mengontrol menu pop-up FAB
  bool _isFabExpanded = false;

  // ─── STATE UNTUK ACTIVITY LOG ───
  List<dynamic> _activityLogs = [];
  bool _isLoadingActivity = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    if (_currentUser == null) {
      _restoreUserFromStorage();
    }
    _loadAllData();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final configJson = await AvatarService.getUserAvatarConfig();
      if (configJson != null) {
        final config = AvatarConfig.fromJson(configJson);
        setState(() {
          _currentAvatar = config.toAvataaar();
        });
      } else {
        setState(() {
          _currentAvatar = Avataaar.random();
        });
      }
    } catch (e) {
      debugPrint('Gagal load avatar: $e');
    }
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadDashboardData(), 
      _loadQuizProfile(),
      _loadActivityLogs(), // ← PANGGIL ACTIVITY LOG
    ]);
  }

  Future<void> _restoreUserFromStorage() async {
    final userJsonStr = await SecureTokenStorage.getUserJson();
    if (userJsonStr != null) {
      final userData = jsonDecode(userJsonStr);
      setState(() {
        _currentUser = User.fromJson(userData);
      });
    }
  }

  Future<void> _loadQuizProfile() async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        setState(() => _isLoadingProfile = false);
        return;
      }
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['userId'] ?? decodedToken['id'];
      final profile = await rekomendasiService.getLatestRecommendation(userId);
      if (mounted) {
        setState(() {
          _quizProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Gagal load quiz profile: $e');
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final token = await SecureTokenStorage.getToken();
    if (token != null) {
      try {
        final apiCards = await CardService().getCardsByUser(token);
        if (apiCards.isNotEmpty && mounted) {
          setState(() {
            _cardsList = apiCards;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        debugPrint('Koneksi ke database gagal: $e');
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ─── FUNGSI BARU: LOAD ACTIVITY LOG ───
  // Future<void> _loadActivityLogs() async {
  //   if (mounted) setState(() => _isLoadingActivity = true);

  //   // Coba ambil semua log dulu (kalau admin), fallback ke log milik sendiri
  //   List<dynamic> logs = await ActivityLogService.getAllActivities(limit: 20);
  //   if (logs.isEmpty) {
  //     logs = await ActivityLogService.getMyActivities(limit: 20);
  //   }

  //   if (mounted) {
  //     setState(() {
  //       _activityLogs = logs;
  //       _isLoadingActivity = false;
  //     });
  //   }
  // }
  Future<void> _loadActivityLogs() async {
  if (mounted) setState(() => _isLoadingActivity = true);

  // Langsung pakai getMyActivities (tidak kena 403)
  final logs = await ActivityLogService.getMyActivities(limit: 20);

  if (mounted) {
    setState(() {
      _activityLogs = logs;
      _isLoadingActivity = false;
    });
  }
}

  int get _completedTaskCount {
    return _cardsList.where((card) {
      final col = (card.computedColumn).toString();
      return col == 'reflection' || col == 'done' || col == 'completed';
    }).length;
  }

  // Fungsi untuk membuka halaman AddCardView
  void _navigateToAddCard() async {
    final token = await SecureTokenStorage.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi login habis, silakan login ulang.')),
        );
      }
      return;
    }

    if (!mounted) return;

    // Navigasi ke AddCardView
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCardView(
          token: token,
          onCardCreated: (payload) async {
            debugPrint("PAYLOAD DARI NEWCARD: $payload");
          },
        ),
      ),
    );

    // Jika berhasil menyimpan (mengembalikan true), refresh dashboard & activity
    if (result == true) {
      _loadDashboardData();
      _loadActivityLogs();
    }
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCollaborativeHeroCard(),
          const SizedBox(height: 16),
          _buildStatisticsRow(),
          const SizedBox(height: 20),
          _buildKanbanPreviewSection(),
          const SizedBox(height: 24),
          _buildTeamActivitySection(), // ← SUDAH DINAMIS
          const SizedBox(height: 20),
          _buildBottomPromoBanner(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0F172A),
                  size: 16,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collaborative Kanban',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: const [
                    Icon(Icons.people_alt_rounded, size: 12, color: Color(0xFF64748B)),
                    SizedBox(width: 4),
                    Text(
                      'Ruang kerja belajar bersama tim',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollaborativeHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Learn Together. Level Up Together.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Collaborative Kanban',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const SizedBox(
                width: 210,
                child: Text(
                  'Buat, kelola, dan selesaikan tugas bersama tim dalam satu ruang belajar yang interaktif.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'GAMATUTUR\nYour collaborative learning workspace.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Positioned(
            right: -10,
            bottom: 0,
            child: Icon(
              Icons.groups_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsRow() {
    return Row(
      children: [
        _statBox('10', 'Anggota Aktif', Icons.people_outline, const Color(0xFF8B5CF6)),
        const SizedBox(width: 8),
        _statBox('${_cardsList.isNotEmpty ? _completedTaskCount : 24}', 'Task Selesai', Icons.check_circle_outline, const Color(0xFF10B981)),
        const SizedBox(width: 8),
        _statBox('7', 'Streak Kolab', Icons.local_fire_department_outlined, const Color(0xFFF59E0B)),
        const SizedBox(width: 8),
        _statBox('92%', 'Progres Tim', Icons.trending_up_rounded, const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _statBox(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanPreviewSection() {
    final planningCards = _cardsList.where((card) {
      final col = card.computedColumn.toString();
      return col == 'todo' || col == 'planning' || col == 'backlog';
    }).toList();

    final monitoringCards = _cardsList.where((card) {
      final col = card.computedColumn.toString();
      return col == 'in_progress' || col == 'monitoring' || col == 'doing';
    }).toList();

    final controllingCards = _cardsList.where((card) {
      final col = card.computedColumn.toString();
      return col == 'controlling' || col == 'review';
    }).toList();

    final reflectionCards = _cardsList.where((card) {
      final col = card.computedColumn.toString();
      return col == 'reflection' || col == 'done' || col == 'completed';
    }).toList();

    return SizedBox(
      height: 280,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildKanbanColumnContainer(
            title: 'PLANNING',
            color: const Color(0xFF8B5CF6),
            cards: planningCards,
          ),
          const SizedBox(width: 12),
          _buildKanbanColumnContainer(
            title: 'MONITORING',
            color: const Color(0xFF3B82F6),
            cards: monitoringCards,
          ),
          const SizedBox(width: 12),
          _buildKanbanColumnContainer(
            title: 'CONTROLLING',
            color: const Color(0xFFEC4899),
            cards: controllingCards,
          ),
          const SizedBox(width: 12),
          _buildKanbanColumnContainer(
            title: 'REFLECTION',
            color: const Color(0xFF10B981),
            cards: reflectionCards,
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumnContainer({
    required String title,
    required Color color,
    required List<Card> cards,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: color),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 9,
                backgroundColor: const Color(0xFFE2E8F0),
                child: Text(
                  '${cards.length}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: cards.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada task',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: cards.length > 3 ? 3 : cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: _kanbanCardItem(
                          card.title ?? 'Tanpa Judul',
                          card.subtasks.length.toString(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kanbanCardItem(String title, String commentsCount) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFFCBD5E1)),
                  SizedBox(width: 3),
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFF94A3B8)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 9, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 2),
                  Text(commentsCount, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SECTION AKTIVITAS TIM (DINAMIS DARI BACKEND) ───
  Widget _buildTeamActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Aktivitas Tim',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              onPressed: _loadActivityLogs,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Lihat apa yang sedang dikerjakan tim Anda',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        _isLoadingActivity
            ? const SizedBox(
                height: 85,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _activityLogs.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada aktivitas.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 85,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _activityLogs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return _buildDynamicActivityCard(_activityLogs[index]);
                      },
                    ),
                  ),
      ],
    );
  }

  // ─── KARTU AKTIVITAS DINAMIS ───
  // Widget _buildDynamicActivityCard(dynamic log) {
  //   final String title = (log['title'] ?? 'Aktivitas').toString();
  //   final String desc = (log['description'] ?? '').toString();
  //   final String type = (log['activityType'] ?? '').toString().toLowerCase();
  //   final DateTime? createdAt = log['createdAt'] != null
  //       ? DateTime.tryParse(log['createdAt'].toString())
  //       : null;

  //   String userName = '';
  // if (log['user'] != null) {
  //   final user = log['user'];
  //   final firstName = user['firstName'] ?? '';
  //   final lastName = user['lastName'] ?? '';
  //   final username = user['username'] ?? '';
    
  //   // Gabungkan first & last name, kalau kosong pakai username
  //   if (firstName.isNotEmpty || lastName.isNotEmpty) {
  //     userName = '$firstName $lastName'.trim();
  //   } else if (username.isNotEmpty) {
  //     userName = username;
  //   }
  // }

  // // Format tampilan judul: "Aktivitas • Nama User"
  // final String displayTitle = userName.isNotEmpty 
  //     ? '$title • $userName' 
  //     : title;

  //   IconData icon;
  //   Color iconColor;
  //   Color iconBg;

  //   if (type.contains('create')) {
  //     icon = Icons.add_circle_outline;
  //     iconColor = const Color(0xFF10B981);
  //     iconBg = const Color(0xFFECFDF5);
  //   } else if (type.contains('start')) {
  //     icon = Icons.play_circle_outline;
  //     iconColor = const Color(0xFF3B82F6);
  //     iconBg = const Color(0xFFEFF6FF);
  //   } else if (type.contains('complete') || type.contains('done')) {
  //     icon = Icons.check_circle_outline;
  //     iconColor = const Color(0xFF8B5CF6);
  //     iconBg = const Color(0xFFF5F3FF);
  //   } else if (type.contains('reflection')) {
  //     icon = Icons.rate_review_outlined;
  //     iconColor = const Color(0xFFF59E0B);
  //     iconBg = const Color(0xFFFFFBEB);
  //   } else {
  //     icon = Icons.notifications_none;
  //     iconColor = const Color(0xFF6366F1);
  //     iconBg = const Color(0xFFEEF2FF);
  //   }

  //   return Container(
  //     width: 260,
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: const Color(0xFFE2E8F0)),
  //     ),
  //     child: Row(
  //       children: [
  //         CircleAvatar(
  //           radius: 18,
  //           backgroundColor: iconBg,
  //           child: Icon(icon, color: iconColor, size: 18),
  //         ),
  //         const SizedBox(width: 10),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Text(
  //                 displayTitle,
  //                 maxLines: 1,
  //                 overflow: TextOverflow.ellipsis,
  //                 style: const TextStyle(
  //                   fontSize: 11,
  //                   fontWeight: FontWeight.bold,
  //                   color: Color(0xFF0F172A),
  //                 ),
  //               ),
  //               if (desc.isNotEmpty) ...[
  //                 const SizedBox(height: 2),
  //                 Text(
  //                   desc,
  //                   maxLines: 1,
  //                   overflow: TextOverflow.ellipsis,
  //                   style: const TextStyle(
  //                     fontSize: 10,
  //                     color: Color(0xFF64748B),
  //                   ),
  //                 ),
  //               ],
  //               const SizedBox(height: 4),
  //               Text(
  //                 _formatRelativeTime(createdAt),
  //                 style: const TextStyle(
  //                   fontSize: 9,
  //                   color: Color(0xFF94A3B8),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

 Widget _buildDynamicActivityCard(dynamic log) {
  // Backend sudah mengirim format: "Menambahkan tugas baru • Budi"
  final String title = (log['title'] ?? 'Aktivitas').toString();
  final String desc = (log['description'] ?? '').toString();
  final String type = (log['activityType'] ?? '').toString().toString();
  
  final DateTime? createdAt = log['createdAt'] != null
      ? DateTime.tryParse(log['createdAt'].toString())
      : null;

  IconData icon;
  Color iconColor;
  Color iconBg;

  if (type.contains('create')) {
    icon = Icons.add_circle_outline;
    iconColor = const Color(0xFF10B981);
    iconBg = const Color(0xFFECFDF5);
  } else if (type.contains('start')) {
    icon = Icons.play_circle_outline;
    iconColor = const Color(0xFF3B82F6);
    iconBg = const Color(0xFFEFF6FF);
  } else if (type.contains('complete') || type.contains('done')) {
    icon = Icons.check_circle_outline;
    iconColor = const Color(0xFF8B5CF6);
    iconBg = const Color(0xFFF5F3FF);
  } else if (type.contains('reflection')) {
    icon = Icons.rate_review_outlined;
    iconColor = const Color(0xFFF59E0B);
    iconBg = const Color(0xFFFFFBEB);
  } else {
    icon = Icons.notifications_none;
    iconColor = const Color(0xFF6366F1);
    iconBg = const Color(0xFFEEF2FF);
  }

  return Container(
    width: 260,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: iconBg,
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title, // 👈 LANGSUNG PAKAI TITLE DARI BACKEND
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _formatRelativeTime(createdAt),
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Baru saja';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _buildBottomPromoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: [
          const Text('🚀', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belajar lebih efektif bersama tim!',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B)),
                ),
                SizedBox(height: 2),
                Text(
                  'Kolaborasi, diskusi, dan dukungan tim akan membuat proses belajar lebih bermakna.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF4338CA), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_selectedIndex) {
      case 0:
        currentBody = _buildHomeView();
        break;
      case 1:
        currentBody = KanbanBoardView();
        break;
      case 2:
        currentBody = const GoalsScreen();
        break;
      case 3:
        currentBody = ProgressScreen(
          cardsList: _cardsList,
          quizProfile: _quizProfile,
        );
        break;
      case 4:
        currentBody = AccountScreen(
          currentUser: _currentUser,
          quizProfile: _quizProfile,
          userXp: 0,
          currentAvatar: _currentAvatar,
          onAvatarUpdated: _loadAvatar,
        );
        break;
      default:
        currentBody = _buildHomeView();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            currentBody,
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                ),
              ),
          ],
        ),
      ),
      
      // ==========================================
      // FAB MENU
      // ==========================================
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (_isFabExpanded)
            GestureDetector(
              onTap: () => setState(() => _isFabExpanded = false),
              child: Container(
                color: Colors.black.withOpacity(0.2),
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),

          if (_isFabExpanded)
            Positioned(
              bottom: 70,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 70),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // --- Menu 1: Add Card ---
                        _buildFabMenuItem(
                          icon: Icons.image_outlined, 
                          label: 'Add Card',
                          onTap: () {
                            setState(() => _isFabExpanded = false);
                            _navigateToAddCard(); 
                          },
                        ),
                        
                        const SizedBox(height: 12),

                        // --- Menu 2: Collaboration ---
                        _buildFabMenuItem(
                          icon: Icons.person_add_alt_1_outlined, 
                          label: 'Collab',
                          onTap: () {
                            setState(() => _isFabExpanded = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CollaborationScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          FloatingActionButton(
            backgroundColor: const Color(0xFF6366F1), 
            elevation: 4,
            shape: const CircleBorder(),
            child: Icon(
              _isFabExpanded ? Icons.close : Icons.add, 
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isFabExpanded = !_isFabExpanded;
              });
            },
          ),
        ],
      ),
      
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9), 
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF475569), 
                size: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2563EB),
        unselectedItemColor: const Color(0xFF94A3B8),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_kanban_outlined),
            activeIcon: Icon(Icons.view_kanban_rounded),
            label: 'Board',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes_rounded),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}