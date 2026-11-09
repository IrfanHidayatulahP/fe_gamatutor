// import 'dart:convert';

// import 'package:flutter/material.dart' hide Card;
// import 'package:flutter/services.dart';
// import 'package:gamatutor_kanban/model/card.dart';
// import 'package:gamatutor_kanban/model/cardlist.dart';
// import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
// import 'package:gamatutor_kanban/service/cardService.dart';
// import 'package:gamatutor_kanban/service/rekomendasiService.dart';
// import 'package:http/http.dart' as http;
// import 'package:jwt_decoder/jwt_decoder.dart';

// class EditTaskPage extends StatefulWidget {
//   final Card card;
//   final Function(Card) onSaveUpdatedCard;

//   const EditTaskPage({
//     super.key,
//     required this.card,
//     required this.onSaveUpdatedCard,
//   });

//   @override
//   State<EditTaskPage> createState() => _EditTaskPageState();
// }

// class _EditTaskPageState extends State<EditTaskPage> {
//   final _formKey = GlobalKey<FormState>();
//   final CardService _cardService = CardService();

//   // ─── Controllers ───
//   late final TextEditingController _matkulController =
//       TextEditingController(text: widget.card.courseName ?? '');
//   late final TextEditingController _titleController =
//       TextEditingController(text: widget.card.title ?? '');
//   late final TextEditingController _descController =
//       TextEditingController(text: widget.card.description ?? '');
//   final TextEditingController _searchFriendController = TextEditingController();
//   final TextEditingController _dateController = TextEditingController();
//   final TextEditingController _timeController = TextEditingController();

//   // ─── State ───
//   late String _selectedPriority;
//   late String _selectedDifficulty;
//   DateTime? _selectedDeadline;
//   TimeOfDay? _selectedTime;

//   final List<TextEditingController> _subTaskControllers = [];
//   final List<TextEditingController> _urlControllers = [];

//   List<dynamic> _strategies = [];
//   List<String> _unlockedFeatures = [];
//   String? _selectedStrategyId;
//   bool _isLoadingStrategies = true;

//   late List<CardList> _originalSubtasks;

//   final List<dynamic> _friendsList = [];
//   final List<String> _selectedCollaborators = [];
//   bool _isLoadingFriends = false;

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
//     _selectedPriority = widget.card.priority ?? 'medium';
//     _selectedDifficulty = widget.card.difficulty ?? 'medium';
//     _selectedDeadline = widget.card.deadline ?? DateTime.now();
//     _selectedStrategyId = widget.card.learningId;
//     _originalSubtasks = List.from(widget.card.subtasks);

//     _loadFriendsData();

//     if (widget.card.deadline != null) {
//       _dateController.text =
//           "${widget.card.deadline!.day.toString().padLeft(2, '0')}/${widget.card.deadline!.month.toString().padLeft(2, '0')}/${widget.card.deadline!.year}";
//       _timeController.text =
//           "${widget.card.deadline!.hour.toString().padLeft(2, '0')}:${widget.card.deadline!.minute.toString().padLeft(2, '0')}";
//       _selectedTime = TimeOfDay(
//         hour: widget.card.deadline!.hour,
//         minute: widget.card.deadline!.minute,
//       );
//     }

//     if (widget.card.subtasks.isNotEmpty) {
//       for (var sub in widget.card.subtasks) {
//         _subTaskControllers.add(
//           TextEditingController(text: sub.subTitle ?? ''),
//         );
//       }
//     } else {
//       _subTaskControllers.add(TextEditingController());
//     }

//     if (widget.card.urlList.isNotEmpty) {
//       for (var url in widget.card.urlList) {
//         _urlControllers.add(TextEditingController(text: url));
//       }
//     } else {
//       _urlControllers.add(TextEditingController());
//     }

//     if (widget.card.collabList.isNotEmpty) {
//       _selectedCollaborators.addAll(
//         widget.card.collabList
//             .map((c) => c.userId ?? '')
//             .where((id) => id.isNotEmpty)
//             .toList(),
//       );
//     }

//     _matkulController.addListener(() => setState(() {}));
//     _titleController.addListener(() => setState(() {}));
//     _descController.addListener(() => setState(() {}));

//     _loadStrategyData();
//   }

//   @override
//   void dispose() {
//     _matkulController.dispose();
//     _titleController.dispose();
//     _descController.dispose();
//     _searchFriendController.dispose();
//     _dateController.dispose();
//     _timeController.dispose();
//     for (var c in _subTaskControllers) {
//       c.dispose();
//     }
//     for (var c in _urlControllers) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   void _addSubTaskField() =>
//       setState(() => _subTaskControllers.add(TextEditingController()));
//   void _addURLField() =>
//       setState(() => _urlControllers.add(TextEditingController()));

//   Future<void> _loadStrategyData() async {
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         if (mounted) setState(() => _isLoadingStrategies = false);
//         return;
//       }

//       Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
//       final String userId = decodedToken['userId'] ?? decodedToken['id'];

//       final results = await Future.wait([
//         CardService.getAllStrategies(),
//         rekomendasiService.getUnlockedFeatures(userId, token),
//       ]);

//       if (mounted) {
//         setState(() {
//           _strategies = results[0];
//           _unlockedFeatures = results[1] as List<String>;
//           _isLoadingStrategies = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading strategy data: $e');
//       if (mounted) setState(() => _isLoadingStrategies = false);
//     }
//   }

//   Future<void> _loadFriendsData() async {
//     if (mounted) setState(() => _isLoadingFriends = true);
//     try {
//       final token = await SecureTokenStorage.getToken();
//       if (token == null) {
//         if (mounted) setState(() => _isLoadingFriends = false);
//         return;
//       }

//       final response = await http.get(
//         Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (mounted) {
//           setState(() {
//             _friendsList.clear();
//             if (data is List) {
//               _friendsList.addAll(data);
//             } else if (data is Map) {
//               final listData =
//                   data['friends'] ?? data['data'] ?? data['friendships'] ?? [];
//               if (listData is List) {
//                 _friendsList.addAll(listData);
//               }
//             }
//             _isLoadingFriends = false;
//           });
//         }
//       } else {
//         if (mounted) setState(() => _isLoadingFriends = false);
//       }
//     } catch (e) {
//       debugPrint('Error loading friends: $e');
//       if (mounted) setState(() => _isLoadingFriends = false);
//     }
//   }

//   void _showAddCollaboratorDialog() {
//     final TextEditingController searchController = TextEditingController();
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           title: const Text(
//             'Cari & Tambah Teman',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           content: TextField(
//             controller: searchController,
//             decoration: const InputDecoration(
//               hintText: 'Masukkan username...',
//               prefixIcon: Icon(Icons.search),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Batal', style: TextStyle(color: Colors.grey)),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _primary,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onPressed: () async {
//                 final query = searchController.text.trim();
//                 if (query.isNotEmpty) {
//                   Navigator.pop(context);
//                   try {
//                     final token = await SecureTokenStorage.getToken();
//                     if (token != null && widget.card.cardId != null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Berhasil menambahkan kolaborator!'),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                       _loadFriendsData();
//                     }
//                   } catch (e) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Gagal: $e'),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 }
//               },
//               child: const Text(
//                 'Tambah',
//                 style: TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime now = DateTime.now();
//     final DateTime today = DateTime(now.year, now.month, now.day);
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate:
//           _selectedDeadline != null && _selectedDeadline!.isAfter(today)
//               ? _selectedDeadline!
//               : today,
//       firstDate: today,
//       lastDate: DateTime(2101),
//     );
//     if (picked != null) {
//       setState(() {
//         _selectedDeadline = picked;
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
//     if (picked != null) {
//       setState(() {
//         _selectedTime = picked;
//         _timeController.text =
//             "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
//       });
//     }
//   }

//   String _getMonthName(int month) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'Mei',
//       'Jun',
//       'Jul',
//       'Agu',
//       'Sep',
//       'Okt',
//       'Nov',
//       'Des',
//     ];
//     return months[month - 1];
//   }

//   // ─── Hitung langkah selesai ───
//   int get _completedSteps {
//     int c = 0;
//     if (_matkulController.text.trim().isNotEmpty) c++;
//     if (_titleController.text.trim().isNotEmpty) c++;
//     if (_selectedStrategyId != null) c++;
//     if (_descController.text.trim().isNotEmpty) c++;
//     if (_selectedDeadline != null) c++;
//     if (_selectedDifficulty != null) c++;
//     return c;
//   }

//   // ─── Preview text accordion ───
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
//         if (_selectedDeadline == null) return null;
//         return '${_dateController.text} · ${_timeController.text}';
//       case 5:
//         return _selectedDifficulty.toUpperCase();
//       case 6:
//         final total = _subTaskControllers
//             .where((c) => c.text.trim().isNotEmpty)
//             .length;
//         final links =
//             _urlControllers.where((c) => c.text.trim().isNotEmpty).length;
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
//     final bool isMainInfoLocked = widget.card.startTime != null;
//     final bool isCardFinished = widget.card.reflectionCompletedAt != null ||
//         widget.card.endTime != null;

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
//           'Edit Tugas',
//           style: TextStyle(
//               color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
//         ),
//         actions: [
//           TextButton(
//             onPressed: (isCardFinished || _isSaving) ? null : _submitForm,
//             child: _isSaving
//                 ? const SizedBox(
//                     width: 18,
//                     height: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : Text(
//                     'Simpan',
//                     style: TextStyle(
//                       color: isCardFinished
//                           ? _muted
//                           : const Color(0xFF3B82F6),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                     ),
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
//               // Banner dengan warning kalau sudah mulai
//               _buildQuestBanner(isMainInfoLocked: isMainInfoLocked),
//               const SizedBox(height: 16),

//               // 1. Mata kuliah
//               _buildAccordionCard(
//                 index: 0,
//                 icon: Icons.menu_book_rounded,
//                 iconBg: const Color(0xFFE0EAFF),
//                 iconColor: const Color(0xFF3B82F6),
//                 title: 'Mata kuliah',
//                 isRequired: true,
//                 previewText: _previewOf(0),
//                 content: _buildTextField(
//                   controller: _matkulController,
//                   hint: 'Mata Kuliah',
//                   icon: Icons.book_rounded,
//                   enabled: !isMainInfoLocked,
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Wajib diisi' : null,
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // 2. Nama tugas
//               _buildAccordionCard(
//                 index: 1,
//                 icon: Icons.edit_rounded,
//                 iconBg: const Color(0xFFEDE9FE),
//                 iconColor: const Color(0xFF8B5CF6),
//                 title: 'Nama tugas',
//                 isRequired: true,
//                 previewText: _previewOf(1),
//                 content: _buildTextField(
//                   controller: _titleController,
//                   hint: 'Nama Tugas',
//                   icon: Icons.task_alt_rounded,
//                   enabled: !isMainInfoLocked,
//                   validator: (val) =>
//                       val == null || val.isEmpty ? 'Wajib diisi' : null,
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // 3. Strategi belajar
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
//                           final String label =
//                               strategy['learningStrategy'] ?? 'Strategi';
//                           final String keyCode =
//                               (strategy['keyCode'] ?? '').toString();
//                           final String learningId = strategy['learningId'];
//                           final bool isUnlocked =
//                               _unlockedFeatures.contains(keyCode);
//                           final bool isSelected =
//                               _selectedStrategyId == learningId;

//                           String emoji = '🔹';
//                           if (keyCode.contains('time')) emoji = '⏱️';
//                           if (keyCode.contains('help')) emoji = '🤝';
//                           if (keyCode.contains('organization')) emoji = '🏗️';
//                           if (keyCode.contains('elaboration')) emoji = '🕸️';
//                           if (keyCode.contains('rehearsal')) emoji = '🧠';

//                           return ChoiceChip(
//                             label: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text('$emoji $label',
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: isSelected
//                                           ? FontWeight.bold
//                                           : FontWeight.w500,
//                                       color: !isUnlocked
//                                           ? _muted
//                                           : (isSelected ? _primary : _ink),
//                                     )),
//                                 if (!isUnlocked) ...[
//                                   const SizedBox(width: 4),
//                                   const Icon(Icons.lock,
//                                       size: 12, color: Colors.grey),
//                                 ],
//                               ],
//                             ),
//                             selected: isSelected,
//                             selectedColor: _primarySoft,
//                             backgroundColor: isUnlocked
//                                 ? Colors.white
//                                 : const Color(0xFFF1F5F9),
//                             side: BorderSide(
//                                 color:
//                                     isSelected ? _primary : _border),
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10)),
//                             onSelected:
//                                 (isMainInfoLocked || !isUnlocked)
//                                     ? null
//                                     : (selected) {
//                                         setState(() {
//                                           _selectedStrategyId =
//                                               selected ? learningId : null;
//                                         });
//                                       },
//                           );
//                         }).toList(),
//                       ),
//               ),
//               const SizedBox(height: 10),

//               // 4. Tujuan belajar
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
//                     _buildTextField(
//                       controller: _descController,
//                       hint: 'Tulis tujuanmu...',
//                       icon: Icons.notes_rounded,
//                       maxLines: 3,
//                       enabled: !isMainInfoLocked,
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
//                           onSelected: isMainInfoLocked
//                               ? null
//                               : (selected) {
//                                   setState(() {
//                                     _descController.text =
//                                         selected ? goal : '';
//                                   });
//                                 },
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // 5. Deadline & prioritas
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
//                           child: _buildTextField(
//                             controller: _dateController,
//                             hint: 'Tanggal',
//                             icon: Icons.calendar_today_rounded,
//                             readOnly: true,
//                             onTap: () => _selectDate(context),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           flex: 2,
//                           child: _buildTextField(
//                             controller: _timeController,
//                             hint: '23:59',
//                             icon: Icons.access_time_rounded,
//                             readOnly: true,
//                             onTap: () => _selectTime(context),
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
//                         _buildPriorityButton(
//                             'Rendah', 'low', const Color(0xFF10B981),
//                             isMainInfoLocked),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton(
//                             'Sedang', 'medium', const Color(0xFFF59E0B),
//                             isMainInfoLocked),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton(
//                             'Tinggi', 'high', const Color(0xFFEF4444),
//                             isMainInfoLocked),
//                         const SizedBox(width: 6),
//                         _buildPriorityButton(
//                             'Kritis', 'critical', const Color(0xFF8B5CF6),
//                             isMainInfoLocked),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // 6. Tingkat kesulitan
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
//                         onTap: isMainInfoLocked
//                             ? null
//                             : () {
//                                 HapticFeedback.selectionClick();
//                                 setState(() =>
//                                     _selectedDifficulty = val);
//                               },
//                         child: AnimatedContainer(
//                           duration: const Duration(milliseconds: 180),
//                           padding: const EdgeInsets.symmetric(vertical: 10),
//                           margin: const EdgeInsets.symmetric(horizontal: 3),
//                           decoration: BoxDecoration(
//                             color: isSel
//                                 ? col.withOpacity(0.12)
//                                 : (isMainInfoLocked
//                                     ? const Color(0xFFF1F5F9)
//                                     : Colors.white),
//                             border: Border.all(
//                                 color: isSel ? col : _border,
//                                 width: isSel ? 1.6 : 1),
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           child: Center(
//                               child: Text(val.toUpperCase(),
//                                   style: TextStyle(
//                                       fontSize: 10,
//                                       fontWeight: FontWeight.w900,
//                                       color: isSel
//                                           ? col
//                                           : (isMainInfoLocked
//                                               ? Colors.grey
//                                               : _muted)))),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               // 7. Opsi tambahan
//               _buildAccordionCard(
//                 index: 6,
//                 icon: Icons.add_circle_outline_rounded,
//                 iconBg: const Color(0xFFE0F2FE),
//                 iconColor: const Color(0xFF0EA5E9),
//                 title: 'Opsi tambahan',
//                 isRequired: false,
//                 previewText: _previewOf(6) ??
//                     'Subtask · Link · Kolaborasi',
//                 content: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     // Subtasks
//                     const Text('SUBTASKS',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     ..._subTaskControllers.asMap().entries.map((entry) {
//                       final int index = entry.key;
//                       final bool isSubtaskLocked =
//                           index < _originalSubtasks.length &&
//                               _originalSubtasks[index].startTimeList != null;

//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _buildTextField(
//                                 controller: entry.value,
//                                 hint: 'Subtask ${index + 1}',
//                                 icon: isSubtaskLocked
//                                     ? Icons.check_circle
//                                     : Icons.radio_button_unchecked_rounded,
//                                 enabled: !isSubtaskLocked,
//                               ),
//                             ),
//                             if (!isSubtaskLocked)
//                               IconButton(
//                                 icon: const Icon(
//                                     Icons.remove_circle_outline,
//                                     color: Colors.redAccent,
//                                     size: 20),
//                                 onPressed: () => setState(() =>
//                                     _subTaskControllers.removeAt(index)),
//                               ),
//                           ],
//                         ),
//                       );
//                     }),
//                     if (!isCardFinished)
//                       TextButton.icon(
//                         onPressed: _addSubTaskField,
//                         icon: const Icon(Icons.add_circle_outline,
//                             size: 16, color: _primary),
//                         label: const Text('Tambah Subtask',
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 color: _primary,
//                                 fontWeight: FontWeight.bold)),
//                       ),
//                     const Divider(height: 24, color: _border),

//                     // Links
//                     const Text('LINKS',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),
//                     ..._urlControllers.asMap().entries.map((entry) {
//                       final int index = entry.key;
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 6.0),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: _buildTextField(
//                                 controller: entry.value,
//                                 hint: 'https://...',
//                                 icon: Icons.link_rounded,
//                                 enabled: !isCardFinished,
//                               ),
//                             ),
//                             if (!isCardFinished)
//                               IconButton(
//                                 icon: const Icon(
//                                     Icons.remove_circle_outline,
//                                     color: Colors.redAccent,
//                                     size: 20),
//                                 onPressed: () => setState(
//                                     () => _urlControllers.removeAt(index)),
//                               ),
//                           ],
//                         ),
//                       );
//                     }),
//                     if (!isCardFinished)
//                       TextButton.icon(
//                         onPressed: _addURLField,
//                         icon: const Icon(Icons.add_circle_outline,
//                             size: 16, color: _primary),
//                         label: const Text('Tambah Link',
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 color: _primary,
//                                 fontWeight: FontWeight.bold)),
//                       ),
//                     const Divider(height: 24, color: _border),

//                     // Kolaborasi teman
//                     const Text('TAMBAHKAN TEMAN',
//                         style: TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.w900,
//                             color: _muted,
//                             letterSpacing: 0.6)),
//                     const SizedBox(height: 8),

//                     if (widget.card.collabList.isNotEmpty) ...[
//                       SizedBox(
//                         height: 68,
//                         child: ListView.builder(
//                           scrollDirection: Axis.horizontal,
//                           itemCount: widget.card.collabList.length,
//                           itemBuilder: (context, index) {
//                             final collab =
//                                 widget.card.collabList[index];
//                             String name = 'Teman';
//                             try {
//                               final String collabUserId = (collab is Map
//                                       ? (collab['userId'] ??
//                                           collab['user_id'])
//                                       : (collab.userId))
//                                   .toString();

//                               final matchedFriend =
//                                   _friendsList.firstWhere(
//                                 (f) =>
//                                     (f['userId'] ??
//                                         f['id'] ??
//                                         f['friendId']) ==
//                                     collabUserId,
//                                 orElse: () => null,
//                               );

//                               if (matchedFriend != null) {
//                                 name = (matchedFriend['username'] ??
//                                         matchedFriend['name'] ??
//                                         matchedFriend['firstName'] ??
//                                         'Teman')
//                                     .toString();
//                               } else if (collab is Map) {
//                                 final cMap =
//                                     collab as Map<String, dynamic>;
//                                 name = (cMap['username'] ??
//                                         cMap['name'] ??
//                                         cMap['userId'] ??
//                                         'Teman')
//                                     .toString();
//                               } else {
//                                 final dynamic dyn = collab;
//                                 name = (dyn.username ??
//                                         dyn.name ??
//                                         dyn.userId ??
//                                         'Teman')
//                                     .toString();
//                               }
//                             } catch (_) {
//                               name = 'Teman';
//                             }

//                             return Container(
//                               margin: const EdgeInsets.only(right: 12),
//                               child: Column(
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 20,
//                                     backgroundColor: _primary,
//                                     child: Text(
//                                       name.isNotEmpty
//                                           ? name[0].toUpperCase()
//                                           : 'U',
//                                       style: const TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 13,
//                                           fontWeight: FontWeight.bold),
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   SizedBox(
//                                     width: 50,
//                                     child: Text(
//                                       name.split(' ').first,
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

//                     TextButton.icon(
//                       onPressed: _showAddCollaboratorDialog,
//                       icon: const Icon(Icons.person_add_rounded,
//                           size: 16, color: _primary),
//                       label: const Text('Tambah Teman',
//                           style: TextStyle(
//                               fontSize: 12,
//                               color: _primary,
//                               fontWeight: FontWeight.bold)),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),

//               // Tombol simpan
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         isCardFinished ? Colors.grey : _primary,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16)),
//                     elevation: 0,
//                     shadowColor: _primary.withOpacity(0.4),
//                   ),
//                   onPressed: (isCardFinished || _isSaving)
//                       ? null
//                       : _submitForm,
//                   child: _isSaving
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                               color: Colors.white, strokeWidth: 2),
//                         )
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               isCardFinished
//                                   ? Icons.lock_rounded
//                                   : Icons.check_rounded,
//                               color: Colors.white,
//                               size: 18,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               isCardFinished
//                                   ? 'Tugas Telah Selesai'
//                                   : 'Simpan Perubahan',
//                               style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15),
//                             ),
//                           ],
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // BANNER GAMIFIED
//   // ============================================================
//   Widget _buildQuestBanner({required bool isMainInfoLocked}) {
//     final displayTitle = _titleController.text.trim().isEmpty
//         ? 'Tugas tanpa nama'
//         : _titleController.text.trim();
//     final displayCourse = _matkulController.text.trim().isEmpty
//         ? 'Mata kuliah'
//         : _matkulController.text.trim();

//     final steps = _completedSteps;
//     const total = 6;

//     final dueChip = _selectedDeadline != null
//         ? (_timeController.text.isEmpty
//             ? _dateController.text
//             : '${_dateController.text}, ${_timeController.text}')
//         : 'Tenggat';
//     final diffChip = _selectedDifficulty.isNotEmpty
//         ? _selectedDifficulty.substring(0, 1).toUpperCase() +
//             _selectedDifficulty.substring(1)
//         : 'Kesulitan';
//     final prioChip = _selectedPriority.isNotEmpty
//         ? 'P ${_selectedPriority.substring(0, 1).toUpperCase() + _selectedPriority.substring(1)}'
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
//           // Lock warning kalau sudah mulai
//           if (isMainInfoLocked)
//             Container(
//               margin: const EdgeInsets.only(bottom: 12),
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFFFFBEB),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: const Color(0xFFFDE68A)),
//               ),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text('🔒', style: TextStyle(fontSize: 16)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Tugas sudah dimulai. Info utama dikunci.',
//                       style: TextStyle(
//                         fontSize: 11.5,
//                         color: Colors.amber.shade900,
//                         height: 1.4,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           // Header judul + permata
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

//           SizedBox(
//             height: 130,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Positioned(
//                   top: 24,
//                   left: 30,
//                   right: 30,
//                   child: CustomPaint(
//                     size: const Size(double.infinity, 2),
//                     painter: _DashedLinePainter(
//                         color: _primary.withOpacity(0.35)),
//                   ),
//                 ),
//                 Positioned(
//                   top: 8,
//                   left: 0,
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
//               size: 16,
//               color: done ? Colors.white : _primary.withOpacity(0.5)),
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

//   // ─── Helper fields ───
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     int maxLines = 1,
//     bool readOnly = false,
//     bool enabled = true,
//     VoidCallback? onTap,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       readOnly: readOnly,
//       enabled: enabled,
//       onTap: onTap,
//       validator: validator,
//       style: TextStyle(
//         color: enabled ? _ink : _muted,
//         fontSize: 13,
//       ),
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
//         prefixIcon: Icon(
//           icon,
//           size: 18,
//           color: enabled ? _primary : _muted,
//         ),
//         filled: true,
//         fillColor:
//             enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
//         border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none),
//         enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: _border)),
//         disabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide.none),
//         focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: _primary, width: 1.5)),
//         contentPadding:
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//       ),
//     );
//   }

//   Widget _buildQuickDateChip(String label, int daysToAdd) {
//     bool isSelected = false;
//     if (_selectedDeadline != null) {
//       final target = DateTime.now().add(Duration(days: daysToAdd));
//       isSelected = _selectedDeadline!.year == target.year &&
//           _selectedDeadline!.month == target.month &&
//           _selectedDeadline!.day == target.day;
//     }

//     return GestureDetector(
//       onTap: () {
//         setState(() {
//           _selectedDeadline = DateTime.now().add(Duration(days: daysToAdd));
//           _dateController.text =
//               "${_selectedDeadline!.day.toString().padLeft(2, '0')}/${_selectedDeadline!.month.toString().padLeft(2, '0')}/${_selectedDeadline!.year}";
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

//   Widget _buildPriorityButton(
//     String label,
//     String value,
//     Color color,
//     bool isMainInfoLocked,
//   ) {
//     final bool isSelected = _selectedPriority == value;
//     return Expanded(
//       child: GestureDetector(
//         onTap: isMainInfoLocked
//             ? null
//             : () {
//                 HapticFeedback.selectionClick();
//                 setState(() => _selectedPriority = value);
//               },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 150),
//           padding: const EdgeInsets.symmetric(vertical: 10),
//           decoration: BoxDecoration(
//             color: isMainInfoLocked
//                 ? const Color(0xFFF1F5F9)
//                 : (isSelected ? color.withOpacity(0.12) : Colors.white),
//             border: Border.all(
//                 color: isMainInfoLocked
//                     ? Colors.transparent
//                     : (isSelected ? color : _border),
//                 width: isSelected ? 1.5 : 1),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Center(
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 10.5,
//                 fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
//                 color: isMainInfoLocked
//                     ? Colors.grey
//                     : (isSelected ? color : _muted),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ============================================================
//   // SUBMIT — LOGIKA SAMA PERSIS
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

//     if (_selectedDeadline != null) {
//       _selectedDeadline = DateTime(
//         _selectedDeadline!.year,
//         _selectedDeadline!.month,
//         _selectedDeadline!.day,
//         _selectedTime?.hour ?? 23,
//         _selectedTime?.minute ?? 59,
//       );
//     }

//     setState(() => _isSaving = true);

//     try {
//       List<String> urlList = _urlControllers
//           .map((c) => c.text.trim())
//           .where((u) => u.isNotEmpty)
//           .toList();
//       String combinedUrls = urlList.join(', ');

//       List subtasksPayload = [];
//       List<CardList> updatedSubtasksList = [];

//       for (int i = 0; i < _subTaskControllers.length; i++) {
//         String title = _subTaskControllers[i].text.trim();
//         if (title.isEmpty) continue;

//         if (i < _originalSubtasks.length) {
//           final existingSub = _originalSubtasks[i];
//           existingSub.subTitle = title;
//           subtasksPayload.add({
//             'clId': existingSub.clId,
//             'subTitle': title,
//             'startTimeList': existingSub.startTimeList?.toIso8601String(),
//             'endTimeList': existingSub.endTimeList?.toIso8601String(),
//           });
//           updatedSubtasksList.add(existingSub);
//         } else {
//           subtasksPayload.add({
//             'subTitle': title,
//             'startTimeList': null,
//             'endTimeList': null,
//           });
//           updatedSubtasksList.add(
//             CardList(cardId: widget.card.cardId, subTitle: title),
//           );
//         }
//       }

//       final String? finalStartTime = widget.card.startTime?.toIso8601String();

//       final updatedDataJson = {
//         'courseName': _matkulController.text.trim(),
//         'title': _titleController.text.trim(),
//         'description': _descController.text.trim(),
//         'learningId': _selectedStrategyId,
//         'priority': _selectedPriority,
//         'difficulty': _selectedDifficulty,
//         'deadline': _selectedDeadline?.toIso8601String(),
//         'startTime': finalStartTime,
//         'subtasks': subtasksPayload,
//         'url': combinedUrls,
//       };

//       final token = await SecureTokenStorage.getToken();
//       if (token != null && widget.card.cardId != null) {
//         bool cardSuccess = await _cardService.updateCard(
//           token,
//           widget.card.cardId!,
//           updatedDataJson,
//         );
//         if (!cardSuccess) {
//           if (!mounted) return;
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Gagal menyimpan perubahan!')),
//           );
//           return;
//         }
//       }

//       widget.card.subtasks = updatedSubtasksList;
//       widget.card.courseName = _matkulController.text.trim();
//       widget.card.title = _titleController.text.trim();
//       widget.card.description = _descController.text.trim();
//       widget.card.learningId = _selectedStrategyId;
//       widget.card.priority = _selectedPriority;
//       widget.card.difficulty = _selectedDifficulty;
//       widget.card.deadline = _selectedDeadline;
//       widget.card.url = combinedUrls;

//       widget.onSaveUpdatedCard(widget.card);
//       if (!mounted) return;
//       Navigator.pop(context);
//     } catch (e) {
//       debugPrint('Error submit update: $e');
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Terjadi kesalahan: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }
// }

// // ═══════════════════════════════════════════════════════════════
// // Custom painter: garis putus-putus
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

import 'dart:convert';

import 'package:flutter/material.dart' hide Card;
import 'package:flutter/services.dart';
import 'package:gamatutor_kanban/model/card.dart';
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/cardService.dart';
import 'package:gamatutor_kanban/service/rekomendasiService.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

// ─── IMPORT UI REFERENCE ───
import 'package:gamatutor_kanban/widget/quest_card.dart';
import 'package:gamatutor_kanban/utils/reference_ui/task.dart' as ref_task;

class EditTaskPage extends StatefulWidget {
  final Card card;
  final Function(Card) onSaveUpdatedCard;

  const EditTaskPage({
    super.key,
    required this.card,
    required this.onSaveUpdatedCard,
  });

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final CardService _cardService = CardService();

  // ─── Controllers ───
  late final TextEditingController _matkulController =
      TextEditingController(text: widget.card.courseName ?? '');
  late final TextEditingController _titleController =
      TextEditingController(text: widget.card.title ?? '');
  late final TextEditingController _descController =
      TextEditingController(text: widget.card.description ?? '');
  final TextEditingController _searchFriendController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // ─── State ───
  late String _selectedPriority;
  late String _selectedDifficulty;
  DateTime? _selectedDeadline;
  TimeOfDay? _selectedTime;

  final List<TextEditingController> _subTaskControllers = [];
  final List<TextEditingController> _urlControllers = [];

  List<dynamic> _strategies = [];
  List<String> _unlockedFeatures = [];
  String? _selectedStrategyId;
  String? _selectedStrategyName; // Untuk preview accordion
  bool _isLoadingStrategies = true;

  late List<CardList> _originalSubtasks;

  final List<dynamic> _friendsList = [];
  final List<String> _selectedCollaborators = [];
  bool _isLoadingFriends = false;

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
    _selectedPriority = widget.card.priority ?? 'medium';
    _selectedDifficulty = widget.card.difficulty ?? 'medium';
    _selectedDeadline = widget.card.deadline ?? DateTime.now();
    _selectedStrategyId = widget.card.learningId;
    _originalSubtasks = List.from(widget.card.subtasks);

    _loadFriendsData();

    if (widget.card.deadline != null) {
      _dateController.text =
          "${widget.card.deadline!.day.toString().padLeft(2, '0')}/${widget.card.deadline!.month.toString().padLeft(2, '0')}/${widget.card.deadline!.year}";
      _timeController.text =
          "${widget.card.deadline!.hour.toString().padLeft(2, '0')}:${widget.card.deadline!.minute.toString().padLeft(2, '0')}";
      _selectedTime = TimeOfDay(
        hour: widget.card.deadline!.hour,
        minute: widget.card.deadline!.minute,
      );
    }

    if (widget.card.subtasks.isNotEmpty) {
      for (var sub in widget.card.subtasks) {
        _subTaskControllers.add(
          TextEditingController(text: sub.subTitle ?? ''),
        );
      }
    } else {
      _subTaskControllers.add(TextEditingController());
    }

    if (widget.card.urlList.isNotEmpty) {
      for (var url in widget.card.urlList) {
        _urlControllers.add(TextEditingController(text: url));
      }
    } else {
      _urlControllers.add(TextEditingController());
    }

    if (widget.card.collabList.isNotEmpty) {
      _selectedCollaborators.addAll(
        widget.card.collabList
            .map((c) => c.userId ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
      );
    }

    // Listener agar QuestCard langsung ter-update saat form diketik
    _matkulController.addListener(() => setState(() {}));
    _titleController.addListener(() => setState(() {}));
    _descController.addListener(() => setState(() {}));

    _loadStrategyData();
  }

  @override
  void dispose() {
    _matkulController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _searchFriendController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    for (var c in _subTaskControllers) {
      c.dispose();
    }
    for (var c in _urlControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addSubTaskField() =>
      setState(() => _subTaskControllers.add(TextEditingController()));
  void _addURLField() =>
      setState(() => _urlControllers.add(TextEditingController()));

  Future<void> _loadStrategyData() async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingStrategies = false);
        return;
      }

      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final String userId = decodedToken['userId'] ?? decodedToken['id'];

      final results = await Future.wait([
        CardService.getAllStrategies(),
        rekomendasiService.getUnlockedFeatures(userId, token),
      ]);

      if (mounted) {
        setState(() {
          _strategies = results[0];
          _unlockedFeatures = results[1] as List<String>;
          _isLoadingStrategies = false;

          // Set nama strategi untuk preview
          if (_selectedStrategyId != null) {
            for (final s in _strategies) {
              if (s['learningId'] == _selectedStrategyId) {
                _selectedStrategyName = s['learningStrategy']?.toString();
                break;
              }
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading strategy data: $e');
      if (mounted) setState(() => _isLoadingStrategies = false);
    }
  }

  Future<void> _loadFriendsData() async {
    if (mounted) setState(() => _isLoadingFriends = true);
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingFriends = false);
        return;
      }

      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/api/friendships?status=accepted'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _friendsList.clear();
            if (data is List) {
              _friendsList.addAll(data);
            } else if (data is Map) {
              final listData =
                  data['friends'] ?? data['data'] ?? data['friendships'] ?? [];
              if (listData is List) {
                _friendsList.addAll(listData);
              }
            }
            _isLoadingFriends = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingFriends = false);
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
      if (mounted) setState(() => _isLoadingFriends = false);
    }
  }

  void _showAddCollaboratorDialog() {
    final TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cari & Tambah Teman',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Masukkan username...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final query = searchController.text.trim();
                if (query.isNotEmpty) {
                  Navigator.pop(context);
                  try {
                    final token = await SecureTokenStorage.getToken();
                    if (token != null && widget.card.cardId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Berhasil menambahkan kolaborator!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadFriendsData();
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gagal: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Tambah',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline != null && _selectedDeadline!.isAfter(today)
              ? _selectedDeadline!
              : today,
      firstDate: today,
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
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
    if (picked != null) {
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
        return _matkulController.text.trim().isEmpty
            ? null
            : _matkulController.text.trim();
      case 1:
        return _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim();
      case 2:
        return _selectedStrategyName;
      case 3:
        return _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim();
      case 4:
        if (_selectedDeadline == null) return null;
        return '${_dateController.text} · ${_timeController.text}';
      case 5:
        return _selectedDifficulty.toUpperCase();
      case 6:
        final total = _subTaskControllers
            .where((c) => c.text.trim().isNotEmpty)
            .length;
        final links =
            _urlControllers.where((c) => c.text.trim().isNotEmpty).length;
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
    final bool isMainInfoLocked = widget.card.startTime != null;
    final bool isCardFinished = widget.card.reflectionCompletedAt != null ||
        widget.card.endTime != null;

    // ─── STATE UNTUK QUEST CARD ───
    final List<bool> doneStates = [
      _matkulController.text.trim().isNotEmpty, // 0. Mata kuliah
      _titleController.text.trim().isNotEmpty,  // 1. Nama tugas
      _selectedStrategyId != null,              // 2. Strategi
      _descController.text.trim().isNotEmpty,   // 3. Tujuan
      _selectedDeadline != null,                // 4. Deadline
      _selectedDifficulty.isNotEmpty,           // 5. Tingkat kesulitan
    ];

    String? dueText;
    String? dueCls;
    if (_selectedDeadline != null) {
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
          'Edit Tugas',
          style: TextStyle(
              color: _ink, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: (isCardFinished || _isSaving) ? null : _submitForm,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Simpan',
                    style: TextStyle(
                      color: isCardFinished
                          ? _muted
                          : const Color(0xFF3B82F6),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
              // ─── BANNER QUEST CARD ───
              // Karena edit, kita bisa menampilkan QuestCard (karakter akan menyesuaikan)
              if (isMainInfoLocked) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Tugas sudah dimulai. Info utama dikunci.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade900,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              QuestCard(
                title: _titleController.text.trim(),
                course: _matkulController.text.trim(),
                done: doneStates,
                dueText: dueText,
                dueCls: dueCls,
                difficulty: _selectedDifficulty,
                prioLabel: _selectedPriority,
                rewardId: 1, // Default reward ID
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
                content: _buildTextField(
                  controller: _matkulController,
                  hint: 'Mata Kuliah',
                  icon: Icons.book_rounded,
                  enabled: !isMainInfoLocked,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Wajib diisi' : null,
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
                content: _buildTextField(
                  controller: _titleController,
                  hint: 'Nama Tugas',
                  icon: Icons.task_alt_rounded,
                  enabled: !isMainInfoLocked,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Wajib diisi' : null,
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
                          final String label =
                              strategy['learningStrategy'] ?? 'Strategi';
                          final String keyCode =
                              (strategy['keyCode'] ?? '').toString();
                          final String learningId = strategy['learningId'];
                          final bool isUnlocked =
                              _unlockedFeatures.contains(keyCode);
                          final bool isSelected =
                              _selectedStrategyId == learningId;

                          String emoji = '🔹';
                          if (keyCode.contains('time')) emoji = '⏱️';
                          if (keyCode.contains('help')) emoji = '🤝';
                          if (keyCode.contains('organization')) emoji = '🏗️';
                          if (keyCode.contains('elaboration')) emoji = '🕸️';
                          if (keyCode.contains('rehearsal')) emoji = '🧠';

                          return ChoiceChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('$emoji $label',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: !isUnlocked
                                          ? _muted
                                          : (isSelected ? _primary : _ink),
                                    )),
                                if (!isUnlocked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.lock,
                                      size: 12, color: Colors.grey),
                                ],
                              ],
                            ),
                            selected: isSelected,
                            selectedColor: _primarySoft,
                            backgroundColor: isUnlocked
                                ? Colors.white
                                : const Color(0xFFF1F5F9),
                            side: BorderSide(
                                color: isSelected ? _primary : _border),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            onSelected: (isMainInfoLocked || !isUnlocked)
                                ? null
                                : (selected) {
                                    setState(() {
                                      _selectedStrategyId =
                                          selected ? learningId : null;
                                      _selectedStrategyName =
                                          selected ? label : null;
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
                    _buildTextField(
                      controller: _descController,
                      hint: 'Tulis tujuanmu...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      enabled: !isMainInfoLocked,
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
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSel ? _primary : _ink)),
                          selected: isSel,
                          selectedColor: _primarySoft,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: isSel ? _primary : _border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          onSelected: isMainInfoLocked
                              ? null
                              : (selected) {
                                  setState(() {
                                    _descController.text =
                                        selected ? goal : '';
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
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _muted,
                            letterSpacing: 0.6)),
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
                          child: _buildTextField(
                            controller: _dateController,
                            hint: 'Tanggal',
                            icon: Icons.calendar_today_rounded,
                            readOnly: true,
                            enabled: !isMainInfoLocked,
                            onTap: () => _selectDate(context),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _timeController,
                            hint: '23:59',
                            icon: Icons.access_time_rounded,
                            readOnly: true,
                            enabled: !isMainInfoLocked,
                            onTap: () => _selectTime(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('PRIORITAS',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _muted,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityButton('Rendah', 'low',
                            const Color(0xFF10B981), isMainInfoLocked),
                        const SizedBox(width: 6),
                        _buildPriorityButton('Sedang', 'medium',
                            const Color(0xFFF59E0B), isMainInfoLocked),
                        const SizedBox(width: 6),
                        _buildPriorityButton('Tinggi', 'high',
                            const Color(0xFFEF4444), isMainInfoLocked),
                        const SizedBox(width: 6),
                        _buildPriorityButton('Kritis', 'critical',
                            const Color(0xFF8B5CF6), isMainInfoLocked),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ─── 6. TINGKAT KESULITAN ───
              _buildAccordionCard(
                index: 5,
                icon: Icons.bar_chart_rounded,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFF59E0B),
                title: 'Tingkat kesulitan',
                isRequired: false,
                previewText: _previewOf(5),
                content: Row(
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
                        onTap: isMainInfoLocked
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedDifficulty = val);
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isSel
                                ? col.withOpacity(0.12)
                                : (isMainInfoLocked
                                    ? const Color(0xFFF1F5F9)
                                    : Colors.white),
                            border: Border.all(
                                color: isSel ? col : _border,
                                width: isSel ? 1.6 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text(val.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isSel
                                          ? col
                                          : (isMainInfoLocked
                                              ? Colors.grey
                                              : _muted)))),
                        ),
                      ),
                    );
                  }).toList(),
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
                previewText: _previewOf(6) ?? 'Subtask · Link · Kolaborasi',
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtasks
                    const Text('SUBTASKS',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _muted,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    ..._subTaskControllers.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final bool isSubtaskLocked =
                          index < _originalSubtasks.length &&
                              _originalSubtasks[index].startTimeList != null;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: entry.value,
                                hint: 'Subtask ${index + 1}',
                                icon: isSubtaskLocked
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked_rounded,
                                enabled: !isSubtaskLocked,
                              ),
                            ),
                            if (!isSubtaskLocked)
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 20),
                                onPressed: () => setState(() =>
                                    _subTaskControllers.removeAt(index)),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (!isCardFinished)
                      TextButton.icon(
                        onPressed: _addSubTaskField,
                        icon: const Icon(Icons.add_circle_outline,
                            size: 16, color: _primary),
                        label: const Text('Tambah Subtask',
                            style: TextStyle(
                                fontSize: 12,
                                color: _primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    const Divider(height: 24, color: _border),

                    // Links
                    const Text('LINKS',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _muted,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),
                    ..._urlControllers.asMap().entries.map((entry) {
                      final int index = entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: entry.value,
                                hint: 'https://...',
                                icon: Icons.link_rounded,
                                enabled: !isCardFinished,
                              ),
                            ),
                            if (!isCardFinished)
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.redAccent,
                                    size: 20),
                                onPressed: () => setState(
                                    () => _urlControllers.removeAt(index)),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (!isCardFinished)
                      TextButton.icon(
                        onPressed: _addURLField,
                        icon: const Icon(Icons.add_circle_outline,
                            size: 16, color: _primary),
                        label: const Text('Tambah Link',
                            style: TextStyle(
                                fontSize: 12,
                                color: _primary,
                                fontWeight: FontWeight.bold)),
                      ),
                    const Divider(height: 24, color: _border),

                    // Kolaborasi teman
                    const Text('TAMBAHKAN TEMAN',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            color: _muted,
                            letterSpacing: 0.6)),
                    const SizedBox(height: 8),

                    if (widget.card.collabList.isNotEmpty) ...[
                      SizedBox(
                        height: 68,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.card.collabList.length,
                          itemBuilder: (context, index) {
                            final collab = widget.card.collabList[index];
                            String name = 'Teman';
                            try {
                              final String collabUserId = (collab is Map
                                      ? (collab['userId'] ??
                                          collab['user_id'])
                                      : (collab.userId))
                                  .toString();

                              final matchedFriend =
                                  _friendsList.firstWhere(
                                (f) =>
                                    (f['userId'] ??
                                        f['id'] ??
                                        f['friendId']) ==
                                    collabUserId,
                                orElse: () => null,
                              );

                              if (matchedFriend != null) {
                                name = (matchedFriend['username'] ??
                                        matchedFriend['name'] ??
                                        matchedFriend['firstName'] ??
                                        'Teman')
                                    .toString();
                              } else if (collab is Map) {
                                final cMap =
                                    collab as Map<String, dynamic>;
                                name = (cMap['username'] ??
                                        cMap['name'] ??
                                        cMap['userId'] ??
                                        'Teman')
                                    .toString();
                              } else {
                                final dynamic dyn = collab;
                                name = (dyn.username ??
                                        dyn.name ??
                                        dyn.userId ??
                                        'Teman')
                                    .toString();
                              }
                            } catch (_) {
                              name = 'Teman';
                            }

                            return Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: _primary,
                                    child: Text(
                                      name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      name.split(' ').first,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600),
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

                    TextButton.icon(
                      onPressed: _showAddCollaboratorDialog,
                      icon: const Icon(Icons.person_add_rounded,
                          size: 16, color: _primary),
                      label: const Text('Tambah Teman',
                          style: TextStyle(
                              fontSize: 12,
                              color: _primary,
                              fontWeight: FontWeight.bold)),
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
                    backgroundColor: isCardFinished ? Colors.grey : _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    shadowColor: _primary.withOpacity(0.4),
                  ),
                  onPressed:
                      (isCardFinished || _isSaving) ? null : _submitForm,
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isCardFinished
                                  ? Icons.lock_rounded
                                  : Icons.check_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCardFinished
                                  ? 'Tugas Telah Selesai'
                                  : 'Simpan Perubahan',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
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
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(
                  () => _expandedSection = isExpanded ? -1 : index),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 18, color: iconColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: _ink)),
                          if (isRequired)
                            const Text(' *',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold)),
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
                              fontSize: 12,
                              color: _muted,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: _muted),
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

  // ─── Helper fields ───
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      validator: validator,
      style: TextStyle(
        color: enabled ? _ink : _muted,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: enabled ? _primary : _muted,
        ),
        filled: true,
        fillColor:
            enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildQuickDateChip(String label, int daysToAdd) {
    bool isSelected = false;
    if (_selectedDeadline != null) {
      final target = DateTime.now().add(Duration(days: daysToAdd));
      isSelected = _selectedDeadline!.year == target.year &&
          _selectedDeadline!.month == target.month &&
          _selectedDeadline!.day == target.day;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDeadline = DateTime.now().add(Duration(days: daysToAdd));
          _dateController.text =
              "${_selectedDeadline!.day.toString().padLeft(2, '0')}/${_selectedDeadline!.month.toString().padLeft(2, '0')}/${_selectedDeadline!.year}";
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

  Widget _buildPriorityButton(
    String label,
    String value,
    Color color,
    bool isMainInfoLocked,
  ) {
    final bool isSelected = _selectedPriority == value;
    return Expanded(
      child: GestureDetector(
        onTap: isMainInfoLocked
            ? null
            : () {
                HapticFeedback.selectionClick();
                setState(() => _selectedPriority = value);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isMainInfoLocked
                ? const Color(0xFFF1F5F9)
                : (isSelected ? color.withOpacity(0.12) : Colors.white),
            border: Border.all(
                color: isMainInfoLocked
                    ? Colors.transparent
                    : (isSelected ? color : _border),
                width: isSelected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isMainInfoLocked
                    ? Colors.grey
                    : (isSelected ? color : _muted),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT — LOGIKA UPDATE TETAP SAMA
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

    if (_selectedDeadline != null) {
      _selectedDeadline = DateTime(
        _selectedDeadline!.year,
        _selectedDeadline!.month,
        _selectedDeadline!.day,
        _selectedTime?.hour ?? 23,
        _selectedTime?.minute ?? 59,
      );
    }

    setState(() => _isSaving = true);

    try {
      List<String> urlList = _urlControllers
          .map((c) => c.text.trim())
          .where((u) => u.isNotEmpty)
          .toList();
      String combinedUrls = urlList.join(', ');

      List subtasksPayload = [];
      List<CardList> updatedSubtasksList = [];

      for (int i = 0; i < _subTaskControllers.length; i++) {
        String title = _subTaskControllers[i].text.trim();
        if (title.isEmpty) continue;

        if (i < _originalSubtasks.length) {
          final existingSub = _originalSubtasks[i];
          existingSub.subTitle = title;
          subtasksPayload.add({
            'clId': existingSub.clId,
            'subTitle': title,
            'startTimeList': existingSub.startTimeList?.toIso8601String(),
            'endTimeList': existingSub.endTimeList?.toIso8601String(),
          });
          updatedSubtasksList.add(existingSub);
        } else {
          subtasksPayload.add({
            'subTitle': title,
            'startTimeList': null,
            'endTimeList': null,
          });
          updatedSubtasksList.add(
            CardList(cardId: widget.card.cardId, subTitle: title),
          );
        }
      }

      final String? finalStartTime = widget.card.startTime?.toIso8601String();

      final updatedDataJson = {
        'courseName': _matkulController.text.trim(),
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'learningId': _selectedStrategyId,
        'priority': _selectedPriority,
        'difficulty': _selectedDifficulty,
        'deadline': _selectedDeadline?.toIso8601String(),
        'startTime': finalStartTime,
        'subtasks': subtasksPayload,
        'url': combinedUrls,
      };

      final token = await SecureTokenStorage.getToken();
      if (token != null && widget.card.cardId != null) {
        bool cardSuccess = await _cardService.updateCard(
          token,
          widget.card.cardId!,
          updatedDataJson,
        );
        if (!cardSuccess) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan perubahan!')),
          );
          return;
        }
      }

      widget.card.subtasks = updatedSubtasksList;
      widget.card.courseName = _matkulController.text.trim();
      widget.card.title = _titleController.text.trim();
      widget.card.description = _descController.text.trim();
      widget.card.learningId = _selectedStrategyId;
      widget.card.priority = _selectedPriority;
      widget.card.difficulty = _selectedDifficulty;
      widget.card.deadline = _selectedDeadline;
      widget.card.url = combinedUrls;

      widget.onSaveUpdatedCard(widget.card);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error submit update: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}