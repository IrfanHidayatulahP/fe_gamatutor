// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
// import 'package:gamatutor_kanban/service/cardService.dart';
// import 'package:gamatutor_kanban/service/rekomendasiService.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// class AddCardView extends StatefulWidget {
//   final String token;
//   final Future<void> Function(Map<String, dynamic>)? onCardCreated;

//   const AddCardView({
//     super.key,
//     required this.token,
//     this.onCardCreated,
//   });

//   @override
//   State<AddCardView> createState() => _AddCardViewState();
// }

// class _AddCardViewState extends State<AddCardView> {
//   final _formKey = GlobalKey<FormState>();
//   final CardService _cardService = CardService();

//   // ─── Controllers ───
//   final TextEditingController _matkulController = TextEditingController();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descController = TextEditingController();
//   final TextEditingController _searchFriendController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _timeController = TextEditingController();

//   // ─── State ───
//   String? _selectedStrategyId;
//   String? _selectedPriority = 'medium';
//   String? _selectedDifficulty = 'medium';
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedTime;

//   final List<TextEditingController> _subTaskControllers = [];
//   final List<TextEditingController> _urlController = [];

//   List<dynamic> _acceptedFriends = [];
//   final List _selectedCollaborators = [];
//   bool _isLoadingFriends = false;

//   List<dynamic> _strategies = [];
//   List<String> _unlockedFeatures = [];
//   bool _isLoadingStrategies = true;

//   // 0..6
//   int _expandedSection = 0;
//   bool _isSaving = false;

//   // 🎨 Palette
//   static const _bg = Color(0xFFF8F9FE);
//   static const _ink = Color(0xFF0F172A);
//   static const _muted = Color(0xFF64748B);
//   static const _primary = Color(0xFF6366F1);
//   static const _primarySoft = Color(0xFFEEF2FF);
//   static const _border = Color(0xFFE6EAF2);

//   @override
//   void initState() {
//     super.initState();
//     _addSubTaskField();
//     _addURLField();
//     _loadStrategyData();
//     _fetchAcceptedFriends();
//     _matkulController.addListener(() => setState(() {}));
//     _titleController.addListener(() => setState(() {}));
//     _descController.addListener(() => setState(() {}));
//   }

//   @override
//   void dispose() {
//     _matkulController.dispose();
//     _titleController.dispose();
//     _descController.dispose();
//     _searchFriendController.dispose();
//     _dateController.dispose();
//     _timeController.dispose();
//     for (final c in _subTaskControllers) {
//       c.dispose();
//     }
//     for (final c in _urlController) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _fetchAcceptedFriends() async {
//     setState(() => _isLoadingFriends = true);
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//         final currentUserId = decodedToken['userId'] ?? decodedToken['id'];

//         final List rawFriendships = data['friendships'] ?? [];
//         final List parsedFriends = [];
//         for (var item in rawFriendships) {
//           final requester = item['requester'] ?? {};
//           final friend = item['friend'] ?? {};

//           final targetUser = (requester['userId'] == currentUserId ||
//                   requester['user_id'] == currentUserId)
//               ? friend
//               : requester;

//           if (targetUser != null && targetUser.isNotEmpty) {
//             parsedFriends.add({
//               'userId': targetUser['userId'] ?? targetUser['user_id'],
//               'username': targetUser['username'] ?? 'User',
//               'name':
//                   '${targetUser['firstName'] ?? targetUser['first_name'] ?? ''} ${targetUser['lastName'] ?? targetUser['last_name'] ?? ''}'
//                       .trim(),
//             });
//           }
//         }

//         setState(() {
//           _acceptedFriends = parsedFriends;
//           _isLoadingFriends = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ fetch friends: $e');
//       setState(() => _isLoadingFriends = false);
//     }
//   }

//   void _addSubTaskField() {
//     setState(() => _subTaskControllers.add(TextEditingController()));
//   }

//   void _addURLField() {
//     setState(() => _urlController.add(TextEditingController()));
//   }

//   Future<void> _loadStrategyData() async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         setState(() => _isLoadingStrategies = false);
//         return;
//       }

//       Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//       final String userId = decodedToken['userId'] ?? decodedToken['id'];

//       List<dynamic> strategies = [];
//       try {
//         strategies = await CardService.getAllStrategies();
//       } catch (e) {
//         debugPrint('❌ load strategies: $e');
//       }

//       List<String> unlockedFeatures = [];
//       try {
//         final features =
//             await rekomendasiService.getUnlockedFeatures(userId, token);
//         unlockedFeatures = features.map((e) => e.toString()).toList();
//       } catch (e) {
//         debugPrint('❌ load unlocked features: $e');
//       }

//       setState(() {
//         _strategies = strategies;
//         _unlockedFeatures = unlockedFeatures;
//         _isLoadingStrategies = false;
//       });
//     } catch (e) {
//       debugPrint('❌ loadStrategyData: $e');
//       setState(() {
//         _strategies = [];
//         _unlockedFeatures = [];
//         _isLoadingStrategies = false;
//       });
//     }
//   }

//   // ─── Date & Time Pickers ───
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime now = DateTime.now();
//     final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate != null && _selectedDate!.isAfter(tomorrow)
//           ? _selectedDate!
//           : tomorrow,
//       firstDate: tomorrow,
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _dateController.text =
//             "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime ?? const TimeOfDay(hour: 23, minute: 59),
//     );
//     if (picked != null && picked != _selectedTime) {
//       setState(() {
//         _selectedTime = picked;
//         _timeController.text =
//             "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
//       });
//     }
//   }

//   // ─── Hitung langkah selesai (0..6) ───
//   int get _completedSteps {
//     int c = 0;
//     if (_matkulController.text.trim().isNotEmpty) c++;
//     if (_titleController.text.trim().isNotEmpty) c++;
//     if (_selectedStrategyId != null) c++;
//     if (_descController.text.trim().isNotEmpty) c++;
//     if (_selectedDate != null) c++;
//     if (_selectedDifficulty != null) c++;
//     return c;
//   }

//   // ─── Preview teks untuk accordion ───
//   String? _previewOf(int index) {
//     switch (index) {
//       case 0:
//         return _matkulController.text.trim().isEmpty
//             ? null
//             : _matkulController.text.trim();
//       case 1:
//         return _titleController.text.trim().isEmpty
//             ? null
//             : _titleController.text.trim();
//       case 2:
//         if (_selectedStrategyId == null) return null;
//         for (final s in _strategies) {
//           if (s['learningId'] == _selectedStrategyId) {
//             return s['learningStrategy']?.toString();
//           }
//         }
//         return 'Dipilih';
//       case 3:
//         return _descController.text.trim().isEmpty
//             ? null
//             : _descController.text.trim();
//       case 4:
//         if (_selectedDate == null) return null;
//         final tgl = _dateController.text;
//         final jam =
//             _timeController.text.isEmpty ? '23:59' : _timeController.text;
//         return '$tgl · $jam';
//       case 5:
//         return _selectedDifficulty?.toUpperCase();
//       case 6:
//         final total = _subTaskControllers
//             .where((c) => c.text.trim().isNotEmpty)
//             .length;
//         final links =
//             _urlController.where((c) => c.text.trim().isNotEmpty).length;
//         final collabs = _selectedCollaborators.length;
//         if (total == 0 && links == 0 && collabs == 0) return null;
//         final parts = <String>[];
//         if (total > 0) parts.add('$total subtask');
//         if (links > 0) parts.add('$links link');
//         if (collabs > 0) parts.add('$collabs teman');
//         return parts.join(' · ');
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredFriends = _acceptedFriends.where((friend) {
//       final name = (friend['name'] ?? '').toLowerCase();
//       final username = (friend['username'] ?? '').toLowerCase();
//       final q = _searchFriendController.text.toLowerCase();
//       return name.contains(q) || username.contains(q);
//     }).toList();

//     return Scaffold(
//       backgroundColor: _bg,
//       appBar: AppBar(
//         backgroundColor: _bg,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Tugas Baru',
//           style: TextStyle(
//               color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
//         ),
//         actions: [
//           TextButton(
//             onPressed: _isSaving ? null : _submitForm,
//             child: _isSaving
//                 ? const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Text(
//                     'Simpan',
//                     style: TextStyle(
//                         color: Color(0xFF3B82F6),
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15),
//                   ),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ─── BANNER GAMIFIED ───
//               _buildQuestBanner(),
//               const SizedBox(height: 16),

//               // ─── 1. MATA KULIAH ───
//               _buildAccordionCard(
//                 index: 0,
//                 icon: Icons.menu_book_rounded,
//                 iconBg: const Color(0xFFE0EAFF),
//                 iconColor: const Color(0xFF3B82F6),
//                 title: 'Mata kuliah',
//                 isRequired: true,
//                 previewText: _previewOf(0),
//                 content: TextField(
//                   controller: _matkulController,
//                   decoration: _inputDeco('Ketik atau pilih mata kuliah...'),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 2. NAMA TUGAS ───
//               _buildAccordionCard(
//                 index: 1,
//                 icon: Icons.edit_rounded,
//                 iconBg: const Color(0xFFEDE9FE),
//                 iconColor: const Color(0xFF8B5CF6),
//                 title: 'Nama tugas',
//                 isRequired: true,
//                 previewText: _previewOf(1),
//                 content: TextField(
//                   controller: _titleController,
//                   decoration: _inputDeco('Tulis nama tugas...'),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 3. STRATEGI BELAJAR ───
//               _buildAccordionCard(
//                 index: 2,
//                 icon: Icons.school_rounded,
//                 iconBg: const Color(0xFFFCE7F3),
//                 iconColor: const Color(0xFFEC4899),
//                 title: 'Strategi belajar',
//                 isRequired: true,
//                 previewText: _previewOf(2),
//                 content: _isLoadingStrategies
//                     ? const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         child: Center(child: CircularProgressIndicator()),
//                       )
//                     : Wrap(
//                         spacing: 8.0,
//                         runSpacing: 8.0,
//                         children: _strategies.map((strategy) {
//                           final String label = strategy['learningStrategy'];
//                           final String learningId = strategy['learningId'];
//                           final bool isSelected =
//                               _selectedStrategyId == learningId;
//                           return ChoiceChip(
//                             label: Text(label,
//                                 style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: isSelected
//                                         ? FontWeight.bold
//                                         : FontWeight.w500,
//                                     color: isSelected
//                                         ? _primary
//                                         : _ink)),
//                             selected: isSelected,
//                             selectedColor: _primarySoft,
//                             backgroundColor: Colors.white,
//                             side: BorderSide(
//                                 color: isSelected
//                                     ? _primary
//                                     : _border),
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10)),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _selectedStrategyId =
//                                     selected ? learningId : null;
//                               });
//                             },
//                           );
//                         }).toList(),
//                       ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 4. TUJUAN BELAJAR ───
//               _buildAccordionCard(
//                 index: 3,
//                 icon: Icons.track_changes_rounded,
//                 iconBg: const Color(0xFFFEF3C7),
//                 iconColor: const Color(0xFFF59E0B),
//                 title: 'Tujuan belajar',
//                 isRequired: false,
//                 previewText: _previewOf(3),
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TextField(
//                       controller: _descController,
//                       maxLines: 2,
//                       decoration: _inputDeco('Tulis tujuanmu...'),
//                     ),
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: [
//                         'Memahami konsep',
//                         'Persiapan UTS',
//                         'Latihan mandiri',
//                       ].map((goal) {
//                         final isSel = _descController.text.trim() == goal;
//                         return ChoiceChip(
//                           label: Text(goal,
//                               style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: isSel
//                                       ? FontWeight.bold
//                                       : FontWeight.w500,
//                                   color: isSel ? _primary : _ink)),
//                           selected: isSel,
//                           selectedColor: _primarySoft,
//                           backgroundColor: Colors.white,
//                           side: BorderSide(
//                               color: isSel ? _primary : _border),
//                           shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20)),
//                           onSelected: (selected) {
//                             setState(() {
//                               _descController.text =
//                                   selected ? goal : '';
//                             });
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 5. DEADLINE & PRIORITAS ───
//               _buildAccordionCard(
//                 index: 4,
//                 icon: Icons.calendar_today_rounded,
//                 iconBg: const Color(0xFFDCFCE7),
//                 iconColor: const Color(0xFF10B981),
//                 title: 'Deadline & prioritas',
//                 isRequired: false,
//                 previewText: _previewOf(4),
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('DEADLINE',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       children: [
//                         _buildQuickDateChip('Hari ini', 0),
//                         _buildQuickDateChip('Besok', 1),
//                         _buildQuickDateChip('Akhir pekan', 5),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: TextField(
//                             controller: _dateController,
//                             readOnly: true,
//                             onTap: () => _selectDate(context),
//                             decoration: _inputDeco('Tanggal').copyWith(
//                               prefixIcon: const Icon(
//                                   Icons.calendar_month_outlined,
//                                   size: 18,
//                                   color: _muted),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           flex: 2,
//                           child: TextField(
//                             controller: _timeController,
//                             readOnly: true,
//                             onTap: () => _selectTime(context),
//                             decoration: _inputDeco('Jam').copyWith(
//                               prefixIcon: const Icon(
//                                   Icons.access_time_rounded,
//                                   size: 18,
//                                   color: _muted),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     const Text('PRIORITAS',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         _buildPriorityButton('Rendah', 'low',
//                             const Color(0xFF10B981)),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton('Sedang', 'medium',
//                             const Color(0xFFF59E0B)),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton('Tinggi', 'high',
//                             const Color(0xFFEF4444)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 6. TINGKAT KESULITAN ───
//               _buildAccordionCard(
//                 index: 5,
//                 icon: Icons.bar_chart_rounded,
//                 iconBg: const Color(0xFFFEF3C7),
//                 iconColor: const Color(0xFFF59E0B),
//                 title: 'Tingkat kesulitan',
//                 isRequired: false,
//                 previewText: _previewOf(5),
//                 content: Row(
//                   children: ['easy', 'medium', 'hard', 'expert'].map((val) {
//                     final isSel = _selectedDifficulty == val;
//                     final Color col = val == 'easy'
//                         ? const Color(0xFF10B981)
//                         : val == 'medium'
//                             ? const Color(0xFFF59E0B)
//                             : val == 'hard'
//                                 ? const Color(0xFFEF4444)
//                                 : const Color(0xFF8B5CF6);
//                     return Expanded(
//                       child: GestureDetector(
//                         onTap: () =>
//                             setState(() => _selectedDifficulty = val),
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 180),
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           margin: const EdgeInsets.symmetric(horizontal: 3),
//                           decoration: BoxDecoration(
//                             color: isSel
//                                 ? col.withOpacity(0.12)
//                                 : Colors.white,
//                             border: Border.all(
//                                 color:
//                                     isSel ? col : _border,
//                                 width: isSel ? 1.6 : 1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Center(
//                               child: Text(val.toUpperCase(),
//                                   style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w900,
//                                       color: isSel ? col : _muted))),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 7. OPSI TAMBAHAN ───
//               _buildAccordionCard(
//                 index: 6,
//                 icon: Icons.add_circle_outline_rounded,
//                 iconBg: const Color(0xFFE0F2FE),
//                 iconColor: const Color(0xFF0EA5E9),
//                 title: 'Opsi tambahan',
//                 isRequired: false,
//                 previewText: _previewOf(6) ?? 'Subtask · Link · Tracking nilai',
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('SUBTASKS',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     ..._subTaskControllers.asMap().entries.map((entry) {
//                       final int index = entry.key;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: entry.value,
//                                 decoration: _inputDeco('Subtask ${index + 1}'),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(
//                                   Icons.remove_circle_outline,
//                                   color: Colors.redAccent,
//                                   size: 20),
//                               onPressed: () => setState(() =>
//                                   _subTaskControllers.removeAt(index)),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                     TextButton.icon(
//                       onPressed: _addSubTaskField,
//                       icon: const Icon(Icons.add_circle_outline,
//                           size: 16, color: _primary),
//                       label: const Text('Tambah Subtask',
//                           style: TextStyle(
//                               fontSize: 12,
//                               color: _primary,
//                               fontWeight: FontWeight.bold)),
//                     ),
//                     const Divider(height: 24, color: _border),

//                     const Text('LINKS',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     ..._urlController.asMap().entries.map((entry) {
//                       final int index = entry.key;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: entry.value,
//                                 decoration: _inputDeco('https://...'),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(
//                                   Icons.remove_circle_outline,
//                                   color: Colors.redAccent,
//                                   size: 20),
//                               onPressed: () => setState(
//                                   () => _urlController.removeAt(index)),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                     TextButton.icon(
//                       onPressed: _addURLField,
//                       icon: const Icon(Icons.add_circle_outline,
//                           size: 16, color: _primary),
//                       label: const Text('Tambah Link',
//                           style: TextStyle(
//                               fontSize: 12,
//                               color: _primary,
//                               fontWeight: FontWeight.bold)),
//                     ),
//                     const Divider(height: 24, color: _border),

//                     const Text('TAMBAHKAN TEMAN',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),

//                     if (_selectedCollaborators.isNotEmpty) ...[
//                       SizedBox(
//                         height: 68,
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: _selectedCollaborators.length,
//                           itemBuilder: (context, index) {
//                             final collab = _selectedCollaborators[index];
//                             return Container(
//                               margin: const EdgeInsets.only(right: 12),
//                               child: Column(
//                                 children: [
//                                   Stack(
//                                     children: [
//                                       CircleAvatar(
//                                         radius: 20,
//                                         backgroundColor: _primary,
//                                         child: Text(
//                                           collab['name']
//                                                   .toString()
//                                                   .isNotEmpty
//                                               ? collab['name']
//                                                   .toString()[0]
//                                                   .toUpperCase()
//                                               : 'U',
//                                           style: const TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 13,
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         right: 0,
//                                         top: 0,
//                                         child: GestureDetector(
//                                           onTap: () => setState(() =>
//                                               _selectedCollaborators
//                                                   .removeAt(index)),
//                                           child: Container(
//                                             padding:
//                                                 const EdgeInsets.all(2),
//                                             decoration: const BoxDecoration(
//                                                 color: Colors.red,
//                                                 shape: BoxShape.circle),
//                                             child: const Icon(Icons.close,
//                                                 size: 10,
//                                                 color: Colors.white),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SizedBox(
//                                     width: 50,
//                                     child: Text(
//                                       collab['name']
//                                           .toString()
//                                           .split(' ')
//                                           .first,
//                                       textAlign: TextAlign.center,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: const TextStyle(
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.w600),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                     ],

//                     TextField(
//                       controller: _searchFriendController,
//                       onChanged: (_) => setState(() {}),
//                       decoration: _inputDeco('Cari teman..').copyWith(
//                         prefixIcon: const Icon(Icons.search,
//                             size: 18, color: _muted),
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     _isLoadingFriends
//                         ? const Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Center(
//                                 child: CircularProgressIndicator()),
//                           )
//                         : filteredFriends.isEmpty
//                             ? const Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child: Text('Tidak ada teman ditemukan',
//                                     style: TextStyle(
//                                         fontSize: 11, color: _muted)),
//                               )
//                             : ListView.builder(
//                                 shrinkWrap: true,
//                                 physics:
//                                     const NeverScrollableScrollPhysics(),
//                                 itemCount: filteredFriends.length,
//                                 itemBuilder: (context, index) {
//                                   final friend = filteredFriends[index];
//                                   final friendId = friend['userId'];
//                                   final friendName =
//                                       friend['name'].isNotEmpty
//                                           ? friend['name']
//                                           : friend['username'];
//                                   final isSelected =
//                                       _selectedCollaborators.any(
//                                           (c) => c['userId'] == friendId);

//                                   return Container(
//                                     margin:
//                                         const EdgeInsets.only(bottom: 6),
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFF8FAFC),
//                                       borderRadius:
//                                           BorderRadius.circular(12),
//                                       border: Border.all(color: _border),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 18,
//                                           backgroundColor: _primary,
//                                           child: Text(
//                                             friendName.isNotEmpty
//                                                 ? friendName[0]
//                                                     .toUpperCase()
//                                                 : 'U',
//                                             style: const TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 12,
//                                                 fontWeight:
//                                                     FontWeight.bold),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Expanded(
//                                           child: Text(friendName,
//                                               style: const TextStyle(
//                                                   fontWeight:
//                                                       FontWeight.w700,
//                                                   fontSize: 13,
//                                                   color: _ink)),
//                                         ),
//                                         SizedBox(
//                                           height: 30,
//                                           child: ElevatedButton(
//                                             onPressed: () {
//                                               setState(() {
//                                                 if (isSelected) {
//                                                   _selectedCollaborators
//                                                       .removeWhere((c) =>
//                                                           c['userId'] ==
//                                                           friendId);
//                                                 } else {
//                                                   _selectedCollaborators
//                                                       .add(friend);
//                                                 }
//                                               });
//                                             },
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: isSelected
//                                                   ? Colors.grey.shade200
//                                                   : _primary,
//                                               foregroundColor: isSelected
//                                                   ? Colors.black87
//                                                   : Colors.white,
//                                               elevation: 0,
//                                               shape:
//                                                   RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius
//                                                               .circular(8)),
//                                             ),
//                                             child: Text(
//                                                 isSelected
//                                                     ? 'Batal'
//                                                     : 'Tambah',
//                                                 style: const TextStyle(
//                                                     fontSize: 11,
//                                                     fontWeight:
//                                                         FontWeight.bold)),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // ─── TOMBOL SIMPAN ───
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _primary,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     elevation: 0,
//                     shadowColor: _primary.withOpacity(0.4),
//                   ),
//                   onPressed: _isSaving ? null : _submitForm,
//                   child: _isSaving
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                               color: Colors.white, strokeWidth: 2),
//                         )
//                       : const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.check_rounded,
//                                 color: Colors.white, size: 18),
//                             SizedBox(width: 8),
//                             Text(
//                               'Simpan tugas · 💎 +10',
//                               style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BANNER GAMIFIED (Karakter + Roadmap + Chip info)
//   // ============================================================
//   Widget _buildQuestBanner() {
//     final displayTitle = _titleController.text.trim().isEmpty
//         ? 'Misi tanpa nama'
//         : _titleController.text.trim();
//     final displayCourse = _matkulController.text.trim().isEmpty
//         ? 'Pilih wilayah (mata kuliah)'
//         : 'Wilayah: ${_matkulController.text.trim()}';

//     final steps = _completedSteps;
//     const total = 6;

//     // Chip info dinamis
//     final dueChip = _selectedDate != null
//         ? (_timeController.text.isEmpty
//             ? _dateController.text
//             : '${_dateController.text}, ${_timeController.text}')
//         : 'Tenggat';
//     final diffChip = _selectedDifficulty != null
//         ? _selectedDifficulty!.substring(0, 1).toUpperCase() +
//             _selectedDifficulty!.substring(1)
//         : 'Kesulitan';
//     final prioChip = _selectedPriority != null
//         ? 'P ${_selectedPriority!.substring(0, 1).toUpperCase() + _selectedPriority!.substring(1)}'
//         : 'Prioritas';

//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [Color(0xFFE8EEF9), Color(0xFFEDE9FE)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header judul + badge permata
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(displayTitle,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w900,
//                             color: _ink)),
//                     const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         const Icon(Icons.public,
//                             size: 12, color: Color(0xFF3B82F6)),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(displayCourse,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: const TextStyle(
//                                   fontSize: 12,
//                                   color: _muted,
//                                   fontWeight: FontWeight.w600)),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                         color: Colors.black.withOpacity(0.04),
//                         blurRadius: 6),
//                   ],
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.diamond_outlined,
//                         size: 14, color: Color(0xFF6366F1)),
//                     SizedBox(width: 4),
//                     Text('+10',
//                         style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: 12,
//                             color: Color(0xFF6366F1))),
//                     SizedBox(width: 2),
//                     Text('PERMATA',
//                         style: TextStyle(
//                             fontSize: 8.5,
//                             fontWeight: FontWeight.bold,
//                             color: _muted)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           // Roadmap
//           SizedBox(
//             height: 130,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 // Garis putus-putus antar node
//                 Positioned(
//                   top: 24,
//                   left: 30,
//                   right: 30,
//                   child: CustomPaint(
//                     size: const Size(double.infinity, 2),
//                     painter: _DashedLinePainter(color: _primary.withOpacity(0.35)),
//                   ),
//                 ),
//                 // Karakter kecil di kiri
//                 Positioned(
//                   left: 0,
//                   top: 0,
//                   child: SizedBox(
//                     width: 44,
//                     height: 60,
//                     child: CustomPaint(painter: _MiniCharacterPainter()),
//                   ),
//                 ),
//                 // Node step
//                 Positioned(
//                   top: 8,
//                   left: 50,
//                   right: 0,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: List.generate(total, (i) {
//                       final done = i < steps;
//                       final IconData ic;
//                       switch (i) {
//                         case 0:
//                           ic = Icons.book_rounded;
//                           break;
//                         case 1:
//                           ic = Icons.edit_rounded;
//                           break;
//                         case 2:
//                           ic = Icons.school_rounded;
//                           break;
//                         case 3:
//                           ic = Icons.track_changes_rounded;
//                           break;
//                         case 4:
//                           ic = Icons.calendar_today_rounded;
//                           break;
//                         default:
//                           ic = Icons.bolt_rounded;
//                       }
//                       return _buildNode(icon: ic, done: done);
//                     }),
//                   ),
//                 ),
//                 // Chip info kiri bawah + MADUKAN MISI kanan bawah
//                 Positioned(
//                   left: 0,
//                   right: 0,
//                   bottom: 0,
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.end,
//                     children: [
//                       Expanded(
//                         child: Wrap(
//                           spacing: 6,
//                           runSpacing: 6,
//                           children: [
//                             _buildInfoChip(dueChip),
//                             _buildInfoChip(diffChip),
//                             _buildInfoChip(prioChip),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 8, vertical: 4),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.7),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             const Text('MADUKAN MISI',
//                                 style: TextStyle(
//                                     fontSize: 8,
//                                     fontWeight: FontWeight.w900,
//                                     color: Color(0xFF3B82F6),
//                                     letterSpacing: 0.4)),
//                             Text('$steps/$total pos',
//                                 style: const TextStyle(
//                                     fontSize: 10,
//                                     fontWeight: FontWeight.w900,
//                                     color: Color(0xFF1E40AF))),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNode({required IconData icon, required bool done}) {
//     return Column(
//       children: [
//         AnimatedContainer(
//           duration: const Duration(milliseconds: 250),
//           width: 34,
//           height: 34,
//           decoration: BoxDecoration(
//             color: done ? _primary : Colors.white,
//             shape: BoxShape.circle,
//             border: Border.all(
//                 color: done ? _primary : _primary.withOpacity(0.25),
//                 width: 1.5),
//             boxShadow: done
//                 ? [
//                     BoxShadow(
//                         color: _primary.withOpacity(0.3),
//                         blurRadius: 6,
//                         spreadRadius: 1),
//                   ]
//                 : null,
//           ),
//           child: Icon(icon,
//               size: 16, color: done ? Colors.white : _primary.withOpacity(0.5)),
//         ),
//         const SizedBox(height: 6),
//         Container(
//           width: 10,
//           height: 4,
//           decoration: BoxDecoration(
//             color: done ? _primary : Colors.white,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildInfoChip(String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
//       decoration: BoxDecoration(
//         color: Colors.white.withOpacity(0.75),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.white),
//       ),
//       child: Text(text,
//           style: const TextStyle(
//               fontSize: 9.5,
//               fontWeight: FontWeight.w800,
//               color: Color(0xFF1E40AF))),
//     );
//   }

//   // ============================================================
//   // ACCORDION CARD
//   // ============================================================
//   Widget _buildAccordionCard({
//     required int index,
//     required IconData icon,
//     required Color iconBg,
//     required Color iconColor,
//     required String title,
//     required bool isRequired,
//     String? previewText,
//     required Widget content,
//   }) {
//     final bool isExpanded = _expandedSection == index;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: isExpanded ? _primary.withOpacity(0.35) : _border,
//           width: isExpanded ? 1.4 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//               color: Colors.black.withOpacity(0.02),
//               blurRadius: 8,
//               offset: const Offset(0, 2)),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(18),
//         child: Column(
//           children: [
//             InkWell(
//               onTap: () => setState(
//                   () => _expandedSection = isExpanded ? -1 : index),
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 34,
//                       height: 34,
//                       decoration: BoxDecoration(
//                         color: iconBg,
//                         borderRadius: BorderRadius.circular(9),
//                       ),
//                       child: Icon(icon, size: 18, color: iconColor),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Row(
//                         children: [
//                           Text(title,
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.w800,
//                                   fontSize: 14,
//                                   color: _ink)),
//                           if (isRequired)
//                             const Text(' *',
//                                 style: TextStyle(
//                                     color: Colors.red,
//                                     fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                     if (previewText != null && !isExpanded) ...[
//                       Flexible(
//                         child: Text(
//                           previewText,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                               fontSize: 12,
//                               color: _muted,
//                               fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                     ],
//                     AnimatedRotation(
//                       turns: isExpanded ? 0.5 : 0,
//                       duration: const Duration(milliseconds: 200),
//                       child: const Icon(Icons.keyboard_arrow_down_rounded,
//                           color: _muted),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (isExpanded) ...[
//               const Divider(height: 1, color: _border),
//               Padding(padding: const EdgeInsets.all(14), child: content),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // Helper UI
//   // ============================================================
//   InputDecoration _inputDeco(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
//       filled: true,
//       fillColor: const Color(0xFFF8FAFC),
//       border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none),
//       enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: _border)),
//       focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: _primary, width: 1.5)),
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//     );
//   }

//   Widget _buildQuickDateChip(String label, int daysToAdd) {
//     bool isSelected = false;
//     if (_selectedDate != null) {
//       final target = DateTime.now().add(Duration(days: daysToAdd));
//       isSelected = _selectedDate!.year == target.year &&
//           _selectedDate!.month == target.month &&
//           _selectedDate!.day == target.day;
//     }

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedDate = DateTime.now().add(Duration(days: daysToAdd));
//           _dateController.text =
//               "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? _primarySoft : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: isSelected ? _primary : _border),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//             color: isSelected ? _primary : _muted,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPriorityButton(String label, String value, Color color) {
//     final bool isSelected = _selectedPriority == value;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _selectedPriority = value),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: isSelected ? color.withOpacity(0.12) : Colors.white,
//             border: Border.all(
//                 color: isSelected ? color : _border,
//                 width: isSelected ? 1.5 : 1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Center(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
//                 color: isSelected ? color : _muted,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SUBMIT
//   // ============================================================
//   Future<void> _submitForm() async {
//     if (_isSaving) return;

//     if (!_formKey.currentState!.validate()) return;

//     if (_selectedStrategyId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Pilih strategi belajar terlebih dahulu!')),
//       );
//       return;
//     }

//     setState(() => _isSaving = true);

//     try {
//       List<String> subtaksList = _subTaskControllers
//           .map((c) => c.text.trim())
//           .where((t) => t.isNotEmpty)
//           .toList();

//       List<String> urlList = _urlController
//           .map((c) => c.text.trim())
//           .where((u) => u.isNotEmpty)
//           .toList();
//       String combinedUrls = urlList.join(', ');

//       List<String> collaboratorIds =
//           _selectedCollaborators.map((c) => c['userId'].toString()).toList();

//       DateTime finalDeadline;
//       if (_selectedDate != null) {
//         finalDeadline = DateTime(
//           _selectedDate!.year,
//           _selectedDate!.month,
//           _selectedDate!.day,
//           _selectedTime?.hour ?? 23,
//           _selectedTime?.minute ?? 59,
//         );
//       } else {
//         final tomorrow = DateTime.now().add(const Duration(days: 1));
//         finalDeadline = DateTime(
//             tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
//       }

//       final payload = {
//         'courseName': _matkulController.text.trim(),
//         'title': _titleController.text.trim(),
//         'description': _descController.text.trim(),
//         'learningId': _selectedStrategyId,
//         'priority': _selectedPriority,
//         'difficulty': _selectedDifficulty,
//         'deadline': finalDeadline.toIso8601String(),
//         'subtasks': subtaksList,
//         'url': combinedUrls,
//         'collaborators': collaboratorIds,
//       };

//       debugPrint('🟣 [1] PAYLOAD: $payload');

//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         throw Exception('Token tidak tersedia. Silakan login ulang.');
//       }

//       final createdCard = await _cardService.createCard(token, payload);
//       debugPrint('🟣 [5] ✅ CARD TERSIMPAN: $createdCard');

//       if (widget.onCardCreated != null) {
//         try {
//           await widget.onCardCreated!(payload);
//         } catch (e) {
//           debugPrint('⚠️ callback onCardCreated error (abaikan): $e');
//         }
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Tugas berhasil disimpan! 🎉'),
//           backgroundColor: Color(0xFF10B981),
//         ),
//       );

//       Navigator.pop(context, true);
//     } catch (e, stack) {
//       debugPrint('🔴 [ERROR] _submitForm: $e');
//       debugPrint('🔴 [STACK] $stack');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal menyimpan: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }
// }

// // ═══════════════════════════════════════════════════════════════
// // CUSTOM PAINTERS: Garis putus-putus & karakter mini
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
//     canvas.drawCircle(Offset(size.width / 2, size.height * 0.3), 10, headPaint);

//     // Rambut
//     final hairPaint = Paint()..color = const Color(0xFF1E293B);
//     canvas.drawArc(
//       Rect.fromCircle(
//           center: Offset(size.width / 2, size.height * 0.3), radius: 10),
//       3.14,
//       3.14,
//       true,
//       hairPaint,
//     );

//     // Badan
//     final bodyPaint = Paint()..color = const Color(0xFF6366F1);
//     canvas.drawRRect(
//       RRect.fromRectAndRadius(
//         Rect.fromLTWH(size.width * 0.25, size.height * 0.5, size.width * 0.5,
//             size.height * 0.45),
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

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
// import 'package:gamatutor_kanban/service/cardService.dart';
// import 'package:gamatutor_kanban/service/rekomendasiService.dart';
// import 'package:jwt_decoder/jwt_decoder.dart';

// // ─── IMPORT UI REFERENCE ───
// import 'package:gamatutor_kanban/utils/reference_ui/theme.dart' as ref_theme;
// import 'package:gamatutor_kanban/widget/quest_card.dart';
// import 'package:gamatutor_kanban/widget/micro_goal_card.dart';
// import 'package:gamatutor_kanban/utils/reference_ui/micro_goal_session.dart';
// import 'package:gamatutor_kanban/utils/reference_ui/task.dart' as ref_task;

// class AddCardView extends StatefulWidget {
//   final String token;
//   final Future<void> Function(Map<String, dynamic>)? onCardCreated;

//   const AddCardView({
//     super.key,
//     required this.token,
//     this.onCardCreated,
//   });

//   @override
//   State<AddCardView> createState() => _AddCardViewState();
// }

// class _AddCardViewState extends State<AddCardView> {
//   final _formKey = GlobalKey<FormState>();
//   final CardService _cardService = CardService();

//   // ─── Controllers ───
//   final TextEditingController _matkulController = TextEditingController();
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descController = TextEditingController();
//   final TextEditingController _searchFriendController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _timeController = TextEditingController();

//   // ─── State ───
//   String? _selectedStrategyId;
//   String? _selectedPriority = 'medium';
//   String? _selectedDifficulty = 'medium';
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedTime;

//   final List<TextEditingController> _subTaskControllers = [];
//   final List<TextEditingController> _urlController = [];

//   List<dynamic> _acceptedFriends = [];
//   final List _selectedCollaborators = [];
//   bool _isLoadingFriends = false;

//   List<dynamic> _strategies = [];
//   List<String> _unlockedFeatures = [];
//   bool _isLoadingStrategies = true;

//   // State untuk MicroGoal (Cek Pemahaman)
//   // Ganti dengan session asli jika sudah terintegrasi backend
//   MicroGoalSession? _microGoalSession; 

//   // 0..6
//   int _expandedSection = 0;
//   bool _isSaving = false;

//   // 🎨 Palette
//   static const _bg = Color(0xFFF8F9FE);
//   static const _ink = Color(0xFF0F172A);
//   static const _muted = Color(0xFF64748B);
//   static const _primary = Color(0xFF6366F1);
//   static const _primarySoft = Color(0xFFEEF2FF);
//   static const _border = Color(0xFFE6EAF2);

//   @override
//   void initState() {
//     super.initState();
//     _addSubTaskField();
//     _addURLField();
//     _loadStrategyData();
//     _fetchAcceptedFriends();
//     _matkulController.addListener(() => setState(() {}));
//     _titleController.addListener(() => setState(() {}));
//     _descController.addListener(() => setState(() {}));
//   }

//   @override
//   void dispose() {
//     _matkulController.dispose();
//     _titleController.dispose();
//     _descController.dispose();
//     _searchFriendController.dispose();
//     _dateController.dispose();
//     _timeController.dispose();
//     for (final c in _subTaskControllers) {
//       c.dispose();
//     }
//     for (final c in _urlController) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   Future<void> _fetchAcceptedFriends() async {
//     setState(() => _isLoadingFriends = true);
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) return;

//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'),
//         headers: {'Authorization': 'Bearer $token'},
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//         final currentUserId = decodedToken['userId'] ?? decodedToken['id'];

//         final List rawFriendships = data['friendships'] ?? [];
//         final List parsedFriends = [];
//         for (var item in rawFriendships) {
//           final requester = item['requester'] ?? {};
//           final friend = item['friend'] ?? {};

//           final targetUser = (requester['userId'] == currentUserId ||
//                   requester['user_id'] == currentUserId)
//               ? friend
//               : requester;

//           if (targetUser != null && targetUser.isNotEmpty) {
//             parsedFriends.add({
//               'userId': targetUser['userId'] ?? targetUser['user_id'],
//               'username': targetUser['username'] ?? 'User',
//               'name':
//                   '${targetUser['firstName'] ?? targetUser['first_name'] ?? ''} ${targetUser['lastName'] ?? targetUser['last_name'] ?? ''}'
//                       .trim(),
//             });
//           }
//         }

//         setState(() {
//           _acceptedFriends = parsedFriends;
//           _isLoadingFriends = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('❌ fetch friends: $e');
//       setState(() => _isLoadingFriends = false);
//     }
//   }

//   void _addSubTaskField() {
//     setState(() => _subTaskControllers.add(TextEditingController()));
//   }

//   void _addURLField() {
//     setState(() => _urlController.add(TextEditingController()));
//   }

//   Future<void> _loadStrategyData() async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         setState(() => _isLoadingStrategies = false);
//         return;
//       }

//       Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//       final String userId = decodedToken['userId'] ?? decodedToken['id'];

//       List<dynamic> strategies = [];
//       try {
//         strategies = await CardService.getAllStrategies();
//       } catch (e) {
//         debugPrint('❌ load strategies: $e');
//       }

//       List<String> unlockedFeatures = [];
//       try {
//         final features = await rekomendasiService.getUnlockedFeatures(userId, token);
//         unlockedFeatures = features.map((e) => e.toString()).toList();
//       } catch (e) {
//         debugPrint('❌ load unlocked features: $e');
//       }

//       setState(() {
//         _strategies = strategies;
//         _unlockedFeatures = unlockedFeatures;
//         _isLoadingStrategies = false;
//       });
//     } catch (e) {
//       debugPrint('❌ loadStrategyData: $e');
//       setState(() {
//         _strategies = [];
//         _unlockedFeatures = [];
//         _isLoadingStrategies = false;
//       });
//     }
//   }

//   // ─── Date & Time Pickers ───
//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime now = DateTime.now();
//     final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate != null && _selectedDate!.isAfter(tomorrow)
//           ? _selectedDate!
//           : tomorrow,
//       firstDate: tomorrow,
//       lastDate: DateTime(2101),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _dateController.text =
//             "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
//       });
//     }
//   }

//   Future<void> _selectTime(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: _selectedTime ?? const TimeOfDay(hour: 23, minute: 59),
//     );
//     if (picked != null && picked != _selectedTime) {
//       setState(() {
//         _selectedTime = picked;
//         _timeController.text =
//             "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
//       });
//     }
//   }

//   // ─── Preview teks untuk accordion ───
//   String? _previewOf(int index) {
//     switch (index) {
//       case 0:
//         return _matkulController.text.trim().isEmpty ? null : _matkulController.text.trim();
//       case 1:
//         return _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
//       case 2:
//         if (_selectedStrategyId == null) return null;
//         for (final s in _strategies) {
//           if (s['learningId'] == _selectedStrategyId) {
//             return s['learningStrategy']?.toString();
//           }
//         }
//         return 'Dipilih';
//       case 3:
//         return _descController.text.trim().isEmpty ? null : _descController.text.trim();
//       case 4:
//         if (_selectedDate == null) return null;
//         final tgl = _dateController.text;
//         final jam = _timeController.text.isEmpty ? '23:59' : _timeController.text;
//         return '$tgl · $jam';
//       case 5:
//         return _selectedDifficulty?.toUpperCase();
//       case 6:
//         final total = _subTaskControllers.where((c) => c.text.trim().isNotEmpty).length;
//         final links = _urlController.where((c) => c.text.trim().isNotEmpty).length;
//         final collabs = _selectedCollaborators.length;
//         if (total == 0 && links == 0 && collabs == 0) return null;
//         final parts = <String>[];
//         if (total > 0) parts.add('$total subtask');
//         if (links > 0) parts.add('$links link');
//         if (collabs > 0) parts.add('$collabs teman');
//         return parts.join(' · ');
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredFriends = _acceptedFriends.where((friend) {
//       final name = (friend['name'] ?? '').toLowerCase();
//       final username = (friend['username'] ?? '').toLowerCase();
//       final q = _searchFriendController.text.toLowerCase();
//       return name.contains(q) || username.contains(q);
//     }).toList();

//     // Menyiapkan state array untuk QuestCard
//     final List<bool> doneStates = [
//       _matkulController.text.trim().isNotEmpty, // 0. Mata kuliah
//       _titleController.text.trim().isNotEmpty,  // 1. Nama tugas
//       _selectedStrategyId != null,              // 2. Strategi
//       _descController.text.trim().isNotEmpty,   // 3. Tujuan
//       _selectedDate != null,                    // 4. Deadline
//       _selectedDifficulty != null,              // 5. Tingkat kesulitan
//     ];

//     String? dueText;
//     String? dueCls;
//     if (_selectedDate != null) {
//       dueText = _timeController.text.isEmpty
//           ? _dateController.text
//           : '${_dateController.text}, ${_timeController.text}';
//       dueCls = 'soon';
//     }

//     return Scaffold(
//       backgroundColor: _bg,
//       appBar: AppBar(
//         backgroundColor: _bg,
//         elevation: 0,
//         scrolledUnderElevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Tugas Baru',
//           style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
//         ),
//         actions: [
//           TextButton(
//             onPressed: _isSaving ? null : _submitForm,
//             child: _isSaving
//                 ? const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Text(
//                     'Simpan',
//                     style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15),
//                   ),
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ─── BANNER QUEST CARD (REFERENSI UI) ───
//               QuestCard(
//                 title: _titleController.text.trim(),
//                 course: _matkulController.text.trim(),
//                 done: doneStates,
//                 dueText: dueText,
//                 dueCls: dueCls,
//                 difficulty: _selectedDifficulty,
//                 prioLabel: _selectedPriority,
//                 rewardId: 1, // Default reward
//                 compact: false,
//                 onNode: (index) {
//                   // Ketika node di peta diklik, buka accordion yang sesuai
//                   setState(() {
//                     _expandedSection = index;
//                   });
//                 },
//               ),
//               const SizedBox(height: 16),

//               // ─── 1. MATA KULIAH ───
//               _buildAccordionCard(
//                 index: 0,
//                 icon: Icons.menu_book_rounded,
//                 iconBg: const Color(0xFFE0EAFF),
//                 iconColor: const Color(0xFF3B82F6),
//                 title: 'Mata kuliah',
//                 isRequired: true,
//                 previewText: _previewOf(0),
//                 content: TextField(
//                   controller: _matkulController,
//                   decoration: _inputDeco('Ketik atau pilih mata kuliah...'),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 2. NAMA TUGAS ───
//               _buildAccordionCard(
//                 index: 1,
//                 icon: Icons.edit_rounded,
//                 iconBg: const Color(0xFFEDE9FE),
//                 iconColor: const Color(0xFF8B5CF6),
//                 title: 'Nama tugas',
//                 isRequired: true,
//                 previewText: _previewOf(1),
//                 content: TextField(
//                   controller: _titleController,
//                   decoration: _inputDeco('Tulis nama tugas...'),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 3. STRATEGI BELAJAR ───
//               _buildAccordionCard(
//                 index: 2,
//                 icon: Icons.school_rounded,
//                 iconBg: const Color(0xFFFCE7F3),
//                 iconColor: const Color(0xFFEC4899),
//                 title: 'Strategi belajar',
//                 isRequired: true,
//                 previewText: _previewOf(2),
//                 content: _isLoadingStrategies
//                     ? const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         child: Center(child: CircularProgressIndicator()),
//                       )
//                     : Wrap(
//                         spacing: 8.0,
//                         runSpacing: 8.0,
//                         children: _strategies.map((strategy) {
//                           final String label = strategy['learningStrategy'];
//                           final String learningId = strategy['learningId'];
//                           final bool isSelected = _selectedStrategyId == learningId;
//                           return ChoiceChip(
//                             label: Text(label,
//                                 style: TextStyle(
//                                     fontSize: 12,
//                                     fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//                                     color: isSelected ? _primary : _ink)),
//                             selected: isSelected,
//                             selectedColor: _primarySoft,
//                             backgroundColor: Colors.white,
//                             side: BorderSide(color: isSelected ? _primary : _border),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             onSelected: (selected) {
//                               setState(() {
//                                 _selectedStrategyId = selected ? learningId : null;
//                               });
//                             },
//                           );
//                         }).toList(),
//                       ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 4. TUJUAN BELAJAR ───
//               _buildAccordionCard(
//                 index: 3,
//                 icon: Icons.track_changes_rounded,
//                 iconBg: const Color(0xFFFEF3C7),
//                 iconColor: const Color(0xFFF59E0B),
//                 title: 'Tujuan belajar',
//                 isRequired: false,
//                 previewText: _previewOf(3),
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TextField(
//                       controller: _descController,
//                       maxLines: 2,
//                       decoration: _inputDeco('Tulis tujuanmu...'),
//                     ),
//                     const SizedBox(height: 10),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: ref_task.kGoalChips.map((goal) {
//                         final isSel = _descController.text.trim() == goal;
//                         return ChoiceChip(
//                           label: Text(goal,
//                               style: TextStyle(
//                                   fontSize: 12,
//                                   fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
//                                   color: isSel ? _primary : _ink)),
//                           selected: isSel,
//                           selectedColor: _primarySoft,
//                           backgroundColor: Colors.white,
//                           side: BorderSide(color: isSel ? _primary : _border),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                           onSelected: (selected) {
//                             setState(() {
//                               _descController.text = selected ? goal : '';
//                             });
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 5. DEADLINE & PRIORITAS ───
//               _buildAccordionCard(
//                 index: 4,
//                 icon: Icons.calendar_today_rounded,
//                 iconBg: const Color(0xFFDCFCE7),
//                 iconColor: const Color(0xFF10B981),
//                 title: 'Deadline & prioritas',
//                 isRequired: false,
//                 previewText: _previewOf(4),
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('DEADLINE',
//                         style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 8,
//                       children: [
//                         _buildQuickDateChip('Hari ini', 0),
//                         _buildQuickDateChip('Besok', 1),
//                         _buildQuickDateChip('Akhir pekan', 5),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           flex: 3,
//                           child: TextField(
//                             controller: _dateController,
//                             readOnly: true,
//                             onTap: () => _selectDate(context),
//                             decoration: _inputDeco('Tanggal').copyWith(
//                               prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18, color: _muted),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           flex: 2,
//                           child: TextField(
//                             controller: _timeController,
//                             readOnly: true,
//                             onTap: () => _selectTime(context),
//                             decoration: _inputDeco('Jam').copyWith(
//                               prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: _muted),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 16),
//                     const Text('PRIORITAS',
//                         style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         _buildPriorityButton('Rendah', 'low', const Color(0xFF10B981)),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton('Sedang', 'medium', const Color(0xFFF59E0B)),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton('Tinggi', 'high', const Color(0xFFEF4444)),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 6. TINGKAT KESULITAN + MICRO GOAL CARD ───
//               _buildAccordionCard(
//                 index: 5,
//                 icon: Icons.bar_chart_rounded,
//                 iconBg: const Color(0xFFFEF3C7),
//                 iconColor: const Color(0xFFF59E0B),
//                 title: 'Tingkat kesulitan',
//                 isRequired: false,
//                 previewText: _previewOf(5),
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // INTEGRASI MICRO GOAL CARD (Cek Pemahaman)
//                     // MicroGoalCard(
//                     //   session: _microGoalSession,
//                     //   onStart: () {
//                     //     // TODO: Arahkan ke halaman kuis Cek Pemahaman
//                     //     // ref_theme.toast(context, 'Fitur Cek Pemahaman segera hadir!');
//                     //   },
//                     //   onResume: () {
//                     //     // TODO: Lanjutkan sesi Cek Pemahaman
//                     //   },
//                     //   onRedo: () {
//                     //     // TODO: Ulangi sesi Cek Pemahaman
//                     //   },
//                     // ),
//                     const SizedBox(height: 16),
//                     Row(
//                       children: ['easy', 'medium', 'hard', 'expert'].map((val) {
//                         final isSel = _selectedDifficulty == val;
//                         final Color col = val == 'easy'
//                             ? const Color(0xFF10B981)
//                             : val == 'medium'
//                                 ? const Color(0xFFF59E0B)
//                                 : val == 'hard'
//                                     ? const Color(0xFFEF4444)
//                                     : const Color(0xFF8B5CF6);
//                         return Expanded(
//                           child: GestureDetector(
//                             onTap: () => setState(() => _selectedDifficulty = val),
//                             child: AnimatedContainer(
//                               duration: const Duration(milliseconds: 180),
//                               padding: const EdgeInsets.symmetric(vertical: 10),
//                               margin: const EdgeInsets.symmetric(horizontal: 3),
//                               decoration: BoxDecoration(
//                                 color: isSel ? col.withOpacity(0.12) : Colors.white,
//                                 border: Border.all(color: isSel ? col : _border, width: isSel ? 1.6 : 1),
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   val.toUpperCase(),
//                                   style: TextStyle(
//                                       fontSize: 10, fontWeight: FontWeight.w900, color: isSel ? col : _muted),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // ─── 7. OPSI TAMBAHAN ───
//               _buildAccordionCard(
//                 index: 6,
//                 icon: Icons.add_circle_outline_rounded,
//                 iconBg: const Color(0xFFE0F2FE),
//                 iconColor: const Color(0xFF0EA5E9),
//                 title: 'Opsi tambahan',
//                 isRequired: false,
//                 previewText: _previewOf(6) ?? 'Subtask · Link · Tracking nilai',
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text('SUBTASKS',
//                         style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     ..._subTaskControllers.asMap().entries.map((entry) {
//                       final int index = entry.key;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: entry.value,
//                                 decoration: _inputDeco('Subtask ${index + 1}'),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
//                               onPressed: () => setState(() => _subTaskControllers.removeAt(index)),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                     TextButton.icon(
//                       onPressed: _addSubTaskField,
//                       icon: const Icon(Icons.add_circle_outline, size: 16, color: _primary),
//                       label: const Text('Tambah Subtask',
//                           style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.bold)),
//                     ),
//                     const Divider(height: 24, color: _border),

//                     const Text('LINKS',
//                         style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     ..._urlController.asMap().entries.map((entry) {
//                       final int index = entry.key;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: entry.value,
//                                 decoration: _inputDeco('https://...'),
//                               ),
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
//                               onPressed: () => setState(() => _urlController.removeAt(index)),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                     TextButton.icon(
//                       onPressed: _addURLField,
//                       icon: const Icon(Icons.add_circle_outline, size: 16, color: _primary),
//                       label: const Text('Tambah Link',
//                           style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.bold)),
//                     ),
//                     const Divider(height: 24, color: _border),

//                     const Text('TAMBAHKAN TEMAN',
//                         style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
//                     const SizedBox(height: 8),

//                     if (_selectedCollaborators.isNotEmpty) ...[
//                       SizedBox(
//                         height: 68,
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: _selectedCollaborators.length,
//                           itemBuilder: (context, index) {
//                             final collab = _selectedCollaborators[index];
//                             return Container(
//                               margin: const EdgeInsets.only(right: 12),
//                               child: Column(
//                                 children: [
//                                   Stack(
//                                     children: [
//                                       CircleAvatar(
//                                         radius: 20,
//                                         backgroundColor: _primary,
//                                         child: Text(
//                                           collab['name'].toString().isNotEmpty
//                                               ? collab['name'].toString()[0].toUpperCase()
//                                               : 'U',
//                                           style: const TextStyle(
//                                               color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
//                                         ),
//                                       ),
//                                       Positioned(
//                                         right: 0,
//                                         top: 0,
//                                         child: GestureDetector(
//                                           onTap: () => setState(() => _selectedCollaborators.removeAt(index)),
//                                           child: Container(
//                                             padding: const EdgeInsets.all(2),
//                                             decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
//                                             child: const Icon(Icons.close, size: 10, color: Colors.white),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SizedBox(
//                                     width: 50,
//                                     child: Text(
//                                       collab['name'].toString().split(' ').first,
//                                       textAlign: TextAlign.center,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                     ],

//                     TextField(
//                       controller: _searchFriendController,
//                       onChanged: (_) => setState(() {}),
//                       decoration: _inputDeco('Cari teman..').copyWith(
//                         prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
//                       ),
//                     ),
//                     const SizedBox(height: 8),

//                     _isLoadingFriends
//                         ? const Padding(
//                             padding: EdgeInsets.all(16),
//                             child: Center(child: CircularProgressIndicator()),
//                           )
//                         : filteredFriends.isEmpty
//                             ? const Padding(
//                                 padding: EdgeInsets.all(8.0),
//                                 child: Text('Tidak ada teman ditemukan',
//                                     style: TextStyle(fontSize: 11, color: _muted)),
//                               )
//                             : ListView.builder(
//                                 shrinkWrap: true,
//                                 physics: const NeverScrollableScrollPhysics(),
//                                 itemCount: filteredFriends.length,
//                                 itemBuilder: (context, index) {
//                                   final friend = filteredFriends[index];
//                                   final friendId = friend['userId'];
//                                   final friendName = friend['name'].isNotEmpty ? friend['name'] : friend['username'];
//                                   final isSelected = _selectedCollaborators.any((c) => c['userId'] == friendId);

//                                   return Container(
//                                     margin: const EdgeInsets.only(bottom: 6),
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                                     decoration: BoxDecoration(
//                                       color: const Color(0xFFF8FAFC),
//                                       borderRadius: BorderRadius.circular(12),
//                                       border: Border.all(color: _border),
//                                     ),
//                                     child: Row(
//                                       children: [
//                                         CircleAvatar(
//                                           radius: 18,
//                                           backgroundColor: _primary,
//                                           child: Text(
//                                             friendName.isNotEmpty ? friendName[0].toUpperCase() : 'U',
//                                             style: const TextStyle(
//                                                 color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
//                                           ),
//                                         ),
//                                         const SizedBox(width: 10),
//                                         Expanded(
//                                           child: Text(friendName,
//                                               style: const TextStyle(
//                                                   fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
//                                         ),
//                                         SizedBox(
//                                           height: 30,
//                                           child: ElevatedButton(
//                                             onPressed: () {
//                                               setState(() {
//                                                 if (isSelected) {
//                                                   _selectedCollaborators.removeWhere((c) => c['userId'] == friendId);
//                                                 } else {
//                                                   _selectedCollaborators.add(friend);
//                                                 }
//                                               });
//                                             },
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: isSelected ? Colors.grey.shade200 : _primary,
//                                               foregroundColor: isSelected ? Colors.black87 : Colors.white,
//                                               elevation: 0,
//                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                                             ),
//                                             child: Text(isSelected ? 'Batal' : 'Tambah',
//                                                 style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   );
//                                 },
//                               ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // ─── TOMBOL SIMPAN ───
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _primary,
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//                     elevation: 0,
//                     shadowColor: _primary.withOpacity(0.4),
//                   ),
//                   onPressed: _isSaving ? null : _submitForm,
//                   child: _isSaving
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
//                         )
//                       : const Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.check_rounded, color: Colors.white, size: 18),
//                             SizedBox(width: 8),
//                             Text(
//                               'Simpan tugas · 💎 +10',
//                               style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // ACCORDION CARD
//   // ============================================================
//   Widget _buildAccordionCard({
//     required int index,
//     required IconData icon,
//     required Color iconBg,
//     required Color iconColor,
//     required String title,
//     required bool isRequired,
//     String? previewText,
//     required Widget content,
//   }) {
//     final bool isExpanded = _expandedSection == index;

//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: isExpanded ? _primary.withOpacity(0.35) : _border,
//           width: isExpanded ? 1.4 : 1,
//         ),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
//         ],
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(18),
//         child: Column(
//           children: [
//             InkWell(
//               onTap: () => setState(() => _expandedSection = isExpanded ? -1 : index),
//               child: Padding(
//                 padding: const EdgeInsets.all(14),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 34,
//                       height: 34,
//                       decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
//                       child: Icon(icon, size: 18, color: iconColor),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Row(
//                         children: [
//                           Text(title,
//                               style: const TextStyle(
//                                   fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
//                           if (isRequired)
//                             const Text(' *',
//                                 style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                     if (previewText != null && !isExpanded) ...[
//                       Flexible(
//                         child: Text(
//                           previewText,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: const TextStyle(
//                               fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
//                         ),
//                       ),
//                       const SizedBox(width: 6),
//                     ],
//                     AnimatedRotation(
//                       turns: isExpanded ? 0.5 : 0,
//                       duration: const Duration(milliseconds: 200),
//                       child: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (isExpanded) ...[
//               const Divider(height: 1, color: _border),
//               Padding(padding: const EdgeInsets.all(14), child: content),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // Helper UI
//   // ============================================================
//   InputDecoration _inputDeco(String hint) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
//       filled: true,
//       fillColor: const Color(0xFFF8FAFC),
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//       enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
//       focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//     );
//   }

//   Widget _buildQuickDateChip(String label, int daysToAdd) {
//     bool isSelected = false;
//     if (_selectedDate != null) {
//       final target = DateTime.now().add(Duration(days: daysToAdd));
//       isSelected = _selectedDate!.year == target.year &&
//           _selectedDate!.month == target.month &&
//           _selectedDate!.day == target.day;
//     }

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedDate = DateTime.now().add(Duration(days: daysToAdd));
//           _dateController.text =
//               "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
//         });
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? _primarySoft : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(color: isSelected ? _primary : _border),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 11,
//             fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
//             color: isSelected ? _primary : _muted,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPriorityButton(String label, String value, Color color) {
//     final bool isSelected = _selectedPriority == value;
//     return Expanded(
//       child: GestureDetector(
//         onTap: () => setState(() => _selectedPriority = value),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: isSelected ? color.withOpacity(0.12) : Colors.white,
//             border: Border.all(color: isSelected ? color : _border, width: isSelected ? 1.5 : 1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Center(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
//                 color: isSelected ? color : _muted,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SUBMIT
//   // ============================================================
//   Future<void> _submitForm() async {
//     if (_isSaving) return;

//     if (!_formKey.currentState!.validate()) return;

//     if (_selectedStrategyId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Pilih strategi belajar terlebih dahulu!')),
//       );
//       return;
//     }

//     setState(() => _isSaving = true);

//     try {
//       List<String> subtaksList = _subTaskControllers
//           .map((c) => c.text.trim())
//           .where((t) => t.isNotEmpty)
//           .toList();

//       List<String> urlList = _urlController.map((c) => c.text.trim()).where((u) => u.isNotEmpty).toList();
//       String combinedUrls = urlList.join(', ');

//       List<String> collaboratorIds =
//           _selectedCollaborators.map((c) => c['userId'].toString()).toList();

//       DateTime finalDeadline;
//       if (_selectedDate != null) {
//         finalDeadline = DateTime(
//           _selectedDate!.year,
//           _selectedDate!.month,
//           _selectedDate!.day,
//           _selectedTime?.hour ?? 23,
//           _selectedTime?.minute ?? 59,
//         );
//       } else {
//         final tomorrow = DateTime.now().add(const Duration(days: 1));
//         finalDeadline = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
//       }

//       final payload = {
//         'courseName': _matkulController.text.trim(),
//         'title': _titleController.text.trim(),
//         'description': _descController.text.trim(),
//         'learningId': _selectedStrategyId,
//         'priority': _selectedPriority,
//         'difficulty': _selectedDifficulty,
//         'deadline': finalDeadline.toIso8601String(),
//         'subtasks': subtaksList,
//         'url': combinedUrls,
//         'collaborators': collaboratorIds,
//       };

//       debugPrint('🟣 [1] PAYLOAD: $payload');

//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         throw Exception('Token tidak tersedia. Silakan login ulang.');
//       }

//       final createdCard = await _cardService.createCard(token, payload);
//       debugPrint('🟣 [5] ✅ CARD TERSIMPAN: $createdCard');

//       if (widget.onCardCreated != null) {
//         try {
//           await widget.onCardCreated!(payload);
//         } catch (e) {
//           debugPrint('⚠️ callback onCardCreated error (abaikan): $e');
//         }
//       }

//       if (!mounted) return;

//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Tugas berhasil disimpan! 🎉'),
//           backgroundColor: Color(0xFF10B981),
//         ),
//       );

//       Navigator.pop(context, true);
//     } catch (e, stack) {
//       debugPrint('🔴 [ERROR] _submitForm: $e');
//       debugPrint('🔴 [STACK] $stack');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Gagal menyimpan: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/rekomendasiService.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:gamatutor_kanban/service/app_config.dart';

// ─── IMPORT UI REFERENCE ───
import 'package:gamatutor_kanban/utils/reference_ui/theme.dart' as ref_theme;
import 'package:gamatutor_kanban/widget/quest_card.dart';
import 'package:gamatutor_kanban/widget/micro_goal_card.dart';
import 'package:gamatutor_kanban/utils/reference_ui/micro_goal_session.dart';
import 'package:gamatutor_kanban/utils/reference_ui/task.dart' as ref_task;

class AddCardView extends StatefulWidget {
  final String token;
  final Future<void> Function(Map<String, dynamic>)? onCardCreated;

  const AddCardView({
    super.key,
    required this.token,
    this.onCardCreated,
  });

  @override
  State<AddCardView> createState() => _AddCardViewState();
}

class _AddCardViewState extends State<AddCardView> {
  final _formKey = GlobalKey<FormState>();
  final CardService _cardService = CardService();

  // ─── Controllers ───
  final TextEditingController _matkulController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _searchFriendController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // ─── State ───
  String? _selectedStrategyId;
  String? _selectedStrategyName; // Tambahan untuk preview nama strategi
  String? _selectedPriority = 'medium';
  String? _selectedDifficulty = 'medium';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<TextEditingController> _subTaskControllers = [];
  final List<TextEditingController> _urlController = [];

  List<dynamic> _acceptedFriends = [];
  final List _selectedCollaborators = [];
  bool _isLoadingFriends = false;

  List<dynamic> _strategies = [];
  List<String> _unlockedFeatures = [];
  bool _isLoadingStrategies = true;

  // State untuk MicroGoal (Cek Pemahaman)
  MicroGoalSession? _microGoalSession; 

  // 0..6
  int _expandedSection = 0;
  bool _isSaving = false;

  // 🎨 Palette
  static const _bg = Color(0xFFF8F9FE);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _primary = Color(0xFF6366F1);
  static const _primarySoft = Color(0xFFEEF2FF);
  static const _border = Color(0xFFE6EAF2);

  @override
  void initState() {
    super.initState();
    _addSubTaskField();
    _addURLField();
    _loadStrategyData();
    _fetchAcceptedFriends();
    
    // Listener agar QuestCard langsung ter-update saat form diketik
    _matkulController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _matkulController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _searchFriendController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    for (final c in _subTaskControllers) {
      c.dispose();
    }
    for (final c in _urlController) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchAcceptedFriends() async {
    setState(() => _isLoadingFriends = true);
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return;
  
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/friendships?status=accepted'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        final currentUserId = decodedToken['userId'] ?? decodedToken['id'];

        final List rawFriendships = data['friendships'] ?? [];
        final List parsedFriends = [];
        for (var item in rawFriendships) {
          final requester = item['requester'] ?? {};
          final friend = item['friend'] ?? {};

          final targetUser = (requester['userId'] == currentUserId ||
                  requester['user_id'] == currentUserId)
              ? friend
              : requester;

          if (targetUser != null && targetUser.isNotEmpty) {
            parsedFriends.add({
              'userId': targetUser['userId'] ?? targetUser['user_id'],
              'username': targetUser['username'] ?? 'User',
              'name':
                  '${targetUser['firstName'] ?? targetUser['first_name'] ?? ''} ${targetUser['lastName'] ?? targetUser['last_name'] ?? ''}'
                      .trim(),
            });
          }
        }

        setState(() {
          _acceptedFriends = parsedFriends;
          _isLoadingFriends = false;
        });
      }
    } catch (e) {
      debugPrint('❌ fetch friends: $e');
      setState(() => _isLoadingFriends = false);
    }
  }

  void _addSubTaskField() {
    setState(() => _subTaskControllers.add(TextEditingController()));
  }

  void _addURLField() {
    setState(() => _urlController.add(TextEditingController()));
  }

  Future<void> _loadStrategyData() async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        setState(() => _isLoadingStrategies = false);
        return;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['userId'] ?? decodedToken['id'];

      List<dynamic> strategies = [];
      try {
        strategies = await CardService.getAllStrategies();
      } catch (e) {
        debugPrint('❌ load strategies: $e');
      }

      List<String> unlockedFeatures = [];
      try {
        final features = await rekomendasiService.getUnlockedFeatures(userId, token);
        unlockedFeatures = features.map((e) => e.toString()).toList();
      } catch (e) {
        debugPrint('❌ load unlocked features: $e');
      }

      if (!mounted) return;
      setState(() {
        _strategies = strategies;
        _unlockedFeatures = unlockedFeatures;
        _isLoadingStrategies = false;
      });
    } catch (e) {
      debugPrint('❌ loadStrategyData: $e');
      if (!mounted) return;
      setState(() {
        _strategies = [];
        _unlockedFeatures = [];
        _isLoadingStrategies = false;
      });
    }
  }

  // ─── Date & Time Pickers ───
  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate != null && _selectedDate!.isAfter(tomorrow)
          ? _selectedDate!
          : tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _timeController.text =
            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  // ─── Preview teks untuk accordion ───
  String? _previewOf(int index) {
    switch (index) {
      case 0:
        return _matkulController.text.trim().isEmpty ? null : _matkulController.text.trim();
      case 1:
        return _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
      case 2:
        return _selectedStrategyName;
      case 3:
        return _descController.text.trim().isEmpty ? null : _descController.text.trim();
      case 4:
        if (_selectedDate == null) return null;
        final tgl = _dateController.text;
        final jam = _timeController.text.isEmpty ? '23:59' : _timeController.text;
        return '$tgl · $jam';
      case 5:
        return _selectedDifficulty?.toUpperCase();
      case 6:
        final total = _subTaskControllers.where((c) => c.text.trim().isNotEmpty).length;
        final links = _urlController.where((c) => c.text.trim().isNotEmpty).length;
        final collabs = _selectedCollaborators.length;
        if (total == 0 && links == 0 && collabs == 0) return null;
        final parts = <String>[];
        if (total > 0) parts.add('$total subtask');
        if (links > 0) parts.add('$links link');
        if (collabs > 0) parts.add('$collabs teman');
        return parts.join(' · ');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final filteredFriends = _acceptedFriends.where((friend) {
      final name = (friend['name'] ?? '').toLowerCase();
      final username = (friend['username'] ?? '').toLowerCase();
      final q = _searchFriendController.text.toUpperCase();
      return name.contains(q) || username.contains(q);
    }).toList();

    // ─── STATE UNTUK QUEST CARD ───
    // Array status 6 pos (true jika sudah diisi)
    // final List<bool> doneStates = [
    //   _matkulController.text.trim().isNotEmpty, // 0. Mata kuliah
    //   _titleController.text.trim().isNotEmpty,  // 1. Nama tugas
    //   _selectedStrategyId != null,              // 2. Strategi
    //   _descController.text.trim().isNotEmpty,   // 3. Tujuan
    //   _selectedDate != null,                    // 4. Deadline
    //   _selectedDifficulty != null,              // 5. Tingkat kesulitan
    // ];

    // // Format teks untuk tenggat waktu
    // String? dueText;
    // String? dueCls;
    // if (_selectedDate != null) {
    //   dueText = _timeController.text.isEmpty
    //       ? _dateController.text
    //       : '${_dateController.text}, ${_timeController.text}';
    //   dueCls = 'soon'; 
    // }

    final List<bool> doneStates = [
  _matkulController.text.trim().isNotEmpty, // 0. Mata kuliah
  _titleController.text.trim().isNotEmpty,  // 1. Nama tugas
  _selectedStrategyId != null,              // 2. Strategi
  _descController.text.trim().isNotEmpty,   // 3. Tujuan
  _selectedDate != null,                    // 4. Deadline
  _selectedDifficulty != null,              // 5. Tingkat kesulitan
];

String? dueText;
String? dueCls;
if (_selectedDate != null) {
  dueText = _timeController.text.isEmpty
      ? _dateController.text
      : '${_dateController.text}, ${_timeController.text}';
  dueCls = 'soon'; 
}

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tugas Baru',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _submitForm,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── QUEST CARD (Murni dari file referensi_ui kamu) ───
              // Karakter akan bergerak otomatis karena logic animasinya sudah ada di dalam widget ini
              QuestCard(
  title: _titleController.text.trim(),
  course: _matkulController.text.trim(),
  done: doneStates,
  dueText: dueText,
  dueCls: dueCls,
  difficulty: _selectedDifficulty,
  prioLabel: _selectedPriority,
  rewardId: 1,
  compact: false,
  onNode: (index) {
    setState(() {
      _expandedSection = index;
    });
  },
),
              const SizedBox(height: 16),

              // ─── 1. MATA KULIAH ───
              _buildAccordionCard(
                index: 0,
                icon: Icons.menu_book_rounded,
                iconBg: const Color(0xFFE0EAFF),
                iconColor: const Color(0xFF3B82F6),
                title: 'Mata kuliah',
                isRequired: true,
                previewText: _previewOf(0),
                content: TextField(
                  controller: _matkulController,
                  decoration: _inputDeco('Ketik atau pilih mata kuliah...'),
                ),
              ),
              const SizedBox(height: 10),

              // ─── 2. NAMA TUGAS ───
              _buildAccordionCard(
                index: 1,
                icon: Icons.edit_rounded,
                iconBg: const Color(0xFFEDE9FE),
                iconColor: const Color(0xFF8B5CF6),
                title: 'Nama tugas',
                isRequired: true,
                previewText: _previewOf(1),
                content: TextField(
                  controller: _titleController,
                  decoration: _inputDeco('Tulis nama tugas...'),
                ),
              ),
              const SizedBox(height: 10),

              // ─── 3. STRATEGI BELAJAR ───
              _buildAccordionCard(
                index: 2,
                icon: Icons.school_rounded,
                iconBg: const Color(0xFFFCE7F3),
                iconColor: const Color(0xFFEC4899),
                title: 'Strategi belajar',
                isRequired: true,
                previewText: _previewOf(2),
                content: _isLoadingStrategies
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _strategies.map((strategy) {
                          final String label = strategy['learningStrategy'];
                          final String learningId = strategy['learningId'];
                          final bool isSelected = _selectedStrategyId == learningId;
                          return ChoiceChip(
                            label: Text(label,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? _primary : _ink)),
                            selected: isSelected,
                            selectedColor: _primarySoft,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? _primary : _border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            onSelected: (selected) {
                              setState(() {
                                _selectedStrategyId = selected ? learningId : null;
                                _selectedStrategyName = selected ? label : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 10),

              // ─── 4. TUJUAN BELAJAR ───
              _buildAccordionCard(
                index: 3,
                icon: Icons.track_changes_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFF59E0B),
                title: 'Tujuan belajar',
                isRequired: false,
                previewText: _previewOf(3),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _descController,
                      maxLines: 2,
                      decoration: _inputDeco('Tulis tujuanmu...'),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ref_task.kGoalChips.map((goal) {
                        final isSel = _descController.text.trim() == goal;
                        return ChoiceChip(
                          label: Text(goal,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  color: isSel ? _primary : _ink)),
                          selected: isSel,
                          selectedColor: _primarySoft,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? _primary : _border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (selected) {
                            setState(() {
                              _descController.text = selected ? goal : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ─── 5. DEADLINE & PRIORITAS ───
              _buildAccordionCard(
                index: 4,
                icon: Icons.calendar_today_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF10B981),
                title: 'Deadline & prioritas',
                isRequired: false,
                previewText: _previewOf(4),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEADLINE',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildQuickDateChip('Hari ini', 0),
                        _buildQuickDateChip('Besok', 1),
                        _buildQuickDateChip('Akhir pekan', 5),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _dateController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: _inputDeco('Tanggal').copyWith(
                              prefixIcon: const Icon(Icons.calendar_month_outlined, size: 18, color: _muted),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _timeController,
                            readOnly: true,
                            onTap: () => _selectTime(context),
                            decoration: _inputDeco('Jam').copyWith(
                              prefixIcon: const Icon(Icons.access_time_rounded, size: 18, color: _muted),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('PRIORITAS',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityButton('Rendah', 'low', const Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        _buildPriorityButton('Sedang', 'medium', const Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        _buildPriorityButton('Tinggi', 'high', const Color(0xFFEF4444)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ─── 6. TINGKAT KESULITAN + MICRO GOAL CARD ───
              _buildAccordionCard(
                index: 5,
                icon: Icons.bar_chart_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFF59E0B),
                title: 'Tingkat kesulitan',
                isRequired: false,
                previewText: _previewOf(5),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INTEGRASI MICRO GOAL CARD (Cek Pemahaman)
                    // MicroGoalCard(
                    //   session: _microGoalSession,
                    //   onStart: () {
                    //     // TODO: Arahkan ke halaman kuis Cek Pemahaman
                    //   },
                    //   onResume: () {
                    //     // TODO: Lanjutkan sesi Cek Pemahaman
                    //   },
                    //   onRedo: () {
                    //     // TODO: Ulangi sesi Cek Pemahaman
                    //   },
                    // ),
                    const SizedBox(height: 16),
                    Row(
                      children: ['easy', 'medium', 'hard', 'expert'].map((val) {
                        final isSel = _selectedDifficulty == val;
                        final Color col = val == 'easy'
                            ? const Color(0xFF10B981)
                            : val == 'medium'
                                ? const Color(0xFFF59E0B)
                                : val == 'hard'
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF8B5CF6);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedDifficulty = val),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: isSel ? col.withOpacity(0.12) : Colors.white,
                                border: Border.all(color: isSel ? col : _border, width: isSel ? 1.6 : 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  val.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w900, color: isSel ? col : _muted),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ─── 7. OPSI TAMBAHAN ───
              _buildAccordionCard(
                index: 6,
                icon: Icons.add_circle_outline_rounded,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0EA5E9),
                title: 'Opsi tambahan',
                isRequired: false,
                previewText: _previewOf(6) ?? 'Subtask · Link · Tracking nilai',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SUBTASKS',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    ..._subTaskControllers.asMap().entries.map((entry) {
                      final int index = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: entry.value,
                                decoration: _inputDeco('Subtask ${index + 1}'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => setState(() => _subTaskControllers.removeAt(index)),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addSubTaskField,
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: _primary),
                      label: const Text('Tambah Subtask',
                          style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 24, color: _border),

                    const Text('LINKS',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    ..._urlController.asMap().entries.map((entry) {
                      final int index = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: entry.value,
                                decoration: _inputDeco('https://...'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => setState(() => _urlController.removeAt(index)),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _addURLField,
                      icon: const Icon(Icons.add_circle_outline, size: 16, color: _primary),
                      label: const Text('Tambah Link',
                          style: TextStyle(fontSize: 12, color: _primary, fontWeight: FontWeight.bold)),
                    ),
                    const Divider(height: 24, color: _border),

                    const Text('TAMBAHKAN TEMAN',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: _muted, letterSpacing: 0.6)),
                    const SizedBox(height: 8),

                    if (_selectedCollaborators.isNotEmpty) ...[
                      SizedBox(
                        height: 68,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedCollaborators.length,
                          itemBuilder: (context, index) {
                            final collab = _selectedCollaborators[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: _primary,
                                        child: Text(
                                          collab['name'].toString().isNotEmpty
                                              ? collab['name'].toString()[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                              color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: GestureDetector(
                                          onTap: () => setState(() => _selectedCollaborators.removeAt(index)),
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.close, size: 10, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      collab['name'].toString().split(' ').first,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    TextField(
                      controller: _searchFriendController,
                      onChanged: (_) => setState(() {}),
                      decoration: _inputDeco('Cari teman..').copyWith(
                        prefixIcon: const Icon(Icons.search, size: 18, color: _muted),
                      ),
                    ),
                    const SizedBox(height: 8),

                    _isLoadingFriends
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : filteredFriends.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text('Tidak ada teman ditemukan',
                                    style: TextStyle(fontSize: 11, color: _muted)),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredFriends.length,
                                itemBuilder: (context, index) {
                                  final friend = filteredFriends[index];
                                  final friendId = friend['userId'];
                                  final friendName = friend['name'].isNotEmpty ? friend['name'] : friend['username'];
                                  final isSelected = _selectedCollaborators.any((c) => c['userId'] == friendId);

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: _primary,
                                          child: Text(
                                            friendName.isNotEmpty ? friendName[0].toUpperCase() : 'U',
                                            style: const TextStyle(
                                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(friendName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 13, color: _ink)),
                                        ),
                                        SizedBox(
                                          height: 30,
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedCollaborators.removeWhere((c) => c['userId'] == friendId);
                                                } else {
                                                  _selectedCollaborators.add(friend);
                                                }
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: isSelected ? Colors.grey.shade200 : _primary,
                                              foregroundColor: isSelected ? Colors.black87 : Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            child: Text(isSelected ? 'Batal' : 'Tambah',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── TOMBOL SIMPAN ───
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    shadowColor: _primary.withOpacity(0.4),
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Simpan tugas · 💎 +10',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ACCORDION CARD
  // ============================================================
  Widget _buildAccordionCard({
    required int index,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required bool isRequired,
    String? previewText,
    required Widget content,
  }) {
    final bool isExpanded = _expandedSection == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded ? _primary.withOpacity(0.35) : _border,
          width: isExpanded ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expandedSection = isExpanded ? -1 : index),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
                          if (isRequired)
                            const Text(' *',
                                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (previewText != null && !isExpanded) ...[
                      Flexible(
                        child: Text(
                          previewText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: _muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: _muted),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: _border),
              Padding(padding: const EdgeInsets.all(14), child: content),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // Helper UI
  // ============================================================
  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  Widget _buildQuickDateChip(String label, int daysToAdd) {
    bool isSelected = false;
    if (_selectedDate != null) {
      final target = DateTime.now().add(Duration(days: daysToAdd));
      isSelected = _selectedDate!.year == target.year &&
          _selectedDate!.month == target.month &&
          _selectedDate!.day == target.day;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = DateTime.now().add(Duration(days: daysToAdd));
          _dateController.text =
              "${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}";
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primarySoft : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? _primary : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? _primary : _muted,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String label, String value, Color color) {
    final bool isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPriority = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : Colors.white,
            border: Border.all(color: isSelected ? color : _border, width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? color : _muted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT
  // ============================================================
  Future<void> _submitForm() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedStrategyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih strategi belajar terlebih dahulu!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      List<String> subtaksList = _subTaskControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      List<String> urlList = _urlController.map((c) => c.text.trim()).where((u) => u.isNotEmpty).toList();
      String combinedUrls = urlList.join(', ');

      List<String> collaboratorIds =
          _selectedCollaborators.map((c) => c['userId'].toString()).toList();

      DateTime finalDeadline;
      if (_selectedDate != null) {
        finalDeadline = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime?.hour ?? 23,
          _selectedTime?.minute ?? 59,
        );
      } else {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        finalDeadline = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59);
      }

      final payload = {
        'courseName': _matkulController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'learningId': _selectedStrategyId,
        'priority': _selectedPriority,
        'difficulty': _selectedDifficulty,
        'deadline': finalDeadline.toIso8601String(),
        'subtasks': subtaksList,
        'url': combinedUrls,
        'collaborators': collaboratorIds,
      };

      debugPrint('🟣 [1] PAYLOAD: $payload');

      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        throw Exception('Token tidak tersedia. Silakan login ulang.');
      }

      final createdCard = await _cardService.createCard(token, payload);
      debugPrint('🟣 [5] ✅ CARD TERSIMPAN: $createdCard');

      if (widget.onCardCreated != null) {
        try {
          await widget.onCardCreated!(payload);
        } catch (e) {
          debugPrint('⚠️ callback onCardCreated error (abaikan): $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil disimpan! 🎉'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stack) {
      debugPrint('🔴 [ERROR] _submitForm: $e');
      debugPrint('🔴 [STACK] $stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}