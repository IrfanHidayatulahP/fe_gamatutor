import 'package:flutter/material.dart';

import 'micro_goal_session.dart' show kDifficultyLabels;

// ---------------------------------------------------------------- konstanta (kode sama dengan backend)

class Strategy {
  final String key, label, description, tagline;
  final IconData icon;
  final Color color, tint;
  final List<String> methods;
  const Strategy(this.key, this.label, this.description, this.tagline, this.icon, this.color, this.tint, this.methods);
}

/// Empat strategi belajar, masing-masing dengan sub-strategi.
const List<Strategy> kStrategies = [
  Strategy('simak', 'Menyimak', 'Belajar lewat membaca atau menonton materi', 'baca / tonton',
      Icons.menu_book_outlined, Color(0xFF3B82F6), Color(0xFFE6EEFC), ['Baca', 'Video', 'Kuliah/rekaman']),
  Strategy('praktik', 'Praktik', 'Belajar lewat mengerjakan langsung', 'kerjakan langsung',
      Icons.code, Color(0xFF10B981), Color(0xFFDDF3EA), ['Coding', 'Proyek', 'Menulis/merangkum']),
  Strategy('diskusi', 'Diskusi', 'Belajar lewat berdiskusi dan menjelaskan', 'jelaskan & tanya',
      Icons.groups_outlined, Color(0xFFF59E0B), Color(0xFFFFEFD9), ['Kelompok', 'Mengajar teman', 'Tanya dosen/asisten']),
  Strategy('uji', 'Uji Diri', 'Belajar lewat menguji pemahaman sendiri', 'kuis & latihan',
      Icons.assignment_turned_in_outlined, Color(0xFF8B5CF6), Color(0xFFEDE6FA),
      ['Latihan soal', 'Kuis', 'Flashcard', 'Simulasi ujian']),
];

Strategy? strategyOf(String? key) {
  for (final s in kStrategies) {
    if (s.key == key) return s;
  }
  return null;
}

const List<String> kGoalChips = ['Memahami konsep', 'Persiapan UTS', 'Latihan mandiri'];

class Option {
  final String key, label;
  final Color color;
  const Option(this.key, this.label, this.color);
}

const List<Option> kPriorities = [
  Option('rendah', 'Rendah', Color(0xFF9CA3AF)),
  Option('sedang', 'Sedang', Color(0xFFF59E0B)),
  Option('tinggi', 'Tinggi', Color(0xFFF43F5E)),
];

String priorityLabel(String? k) => kPriorities.firstWhere((p) => p.key == k, orElse: () => kPriorities[1]).label;
Color priorityColor(String? k) => kPriorities.firstWhere((p) => p.key == k, orElse: () => kPriorities[1]).color;

const Map<String, Color> kDifficultyColors = {
  'mudah': Color(0xFF059669),
  'sedang': Color(0xFFB45309),
  'sulit': Color(0xFFE11D48),
};
const Map<String, IconData> kDifficultyIcons = {
  'mudah': Icons.directions_walk,
  'sedang': Icons.explore_outlined,
  'sulit': Icons.bolt,
};

class BoardColumn {
  final String key, name, description;
  final Color color, tint;
  const BoardColumn(this.key, this.name, this.description, this.color, this.tint);
}

/// Kolom papan mengikuti siklus regulasi diri: Planning, Monitoring, Controlling, Reflection.
const List<BoardColumn> kColumns = [
  BoardColumn('planning', 'Planning', 'Direncanakan, siap dikerjakan', Color(0xFF3B82F6), Color(0xFFE6EEFC)),
  BoardColumn('in_progress', 'Monitoring', 'Sedang dikerjakan dan dipantau', Color(0xFFF59E0B), Color(0xFFFFEFD9)),
  BoardColumn('review', 'Controlling', 'Dicek dan dikendalikan', Color(0xFF8B5CF6), Color(0xFFEDE6FA)),
  BoardColumn('done', 'Reflection', 'Selesai, saatnya refleksi', Color(0xFF10B981), Color(0xFFDDF3EA)),
];

BoardColumn columnOf(String key) => kColumns.firstWhere((c) => c.key == key, orElse: () => kColumns[0]);

const Map<String, String> kNextStatus = {'planning': 'in_progress', 'in_progress': 'review', 'review': 'done'};
const Map<String, String> kPrimaryLabel = {
  'planning': 'Mulai kerjakan',
  'in_progress': 'Kirim ke Review',
  'review': 'Tandai selesai',
};

const Map<String, String> kFeltLabels = {'lebih_ringan': 'Lebih ringan', 'pas': 'Pas', 'lebih_berat': 'Lebih berat'};

/// Umpan balik refleksi: membandingkan pilihan kesulitan dengan yang dirasakan. Nada informatif.
String feltMessage(String? chosen, String? felt) {
  if (felt == null) return '';
  if (chosen == null) return 'Terima kasih sudah merefleksikannya. Ini membantumu menakar tugas berikutnya.';
  final label = kDifficultyLabels[chosen] ?? chosen;
  if (felt == 'pas') return 'Penilaianmu ($label) sudah sesuai dengan yang kamu rasakan.';
  if (felt == 'lebih_berat') {
    return chosen == 'sulit'
        ? 'Kamu sudah memilih Sulit, dan tugas ini memang menantang. Penilaianmu tepat.'
        : 'Tugas ini terasa lebih berat dari pilihanmu ($label). Itu wajar. Untuk tugas serupa, coba pilih satu tingkat lebih tinggi.';
  }
  return chosen == 'mudah'
      ? 'Kamu sudah memilih Mudah, dan tugas ini memang ringan. Penilaianmu tepat.'
      : 'Tugas ini terasa lebih ringan dari pilihanmu ($label). Untuk tugas serupa, coba pilih satu tingkat lebih rendah.';
}

/// Nama 40 hadiah koleksi (gambar assets/rw/01..40.png).
const List<String> kRewardNames = [
  'Orb Pengetahuan', 'Buku Relik', 'Gulungan Quest', 'Botol Bintang', 'Tunas Pertumbuhan', 'Lentera Ilmu',
  'Lencana Petualang', 'Peta Baru', 'Sayap Penjelajah', 'Tas Penjelajah', 'Kristal Memori', 'Pasir Waktu',
  'Bintang Navigasi', 'Daun Kebijaksanaan', 'Mahkota Kecil', 'Cincin Pengetahuan', 'Pecahan Kristal', 'Bunga Cahaya',
  'Kunci Misteri', 'Kompas Arah', 'Botol Pengalaman', 'Ranting Kehidupan', 'Tanduk Pencapaian', 'Lentera Bulan',
  'Topi Petualang', 'Bulu Tertulis', 'Mahkota Daun', 'Gantungan Bintang', 'Artefak Elemental', 'Kerang Penjelajah',
  'Gramofon Memori', 'Kotak Asa', 'Teropong Cahaya', 'Jam Saku', 'Prisma Ide', 'Balok Pengetahuan',
  'Bendera Pencapaian', 'Sumber Inspirasi', 'Amulet Perlindungan', 'Pohon Mimpi',
];

String rewardAsset(int id) => 'assets/rw/${id.toString().padLeft(2, '0')}.png';
String rewardName(int id) => (id >= 1 && id <= kRewardNames.length) ? kRewardNames[id - 1] : 'Lencana Petualang';

// ---------------------------------------------------------------- model data

class Subtask {
  final int id;
  final String title;
  final bool isDone;
  const Subtask(this.id, this.title, this.isDone);

  factory Subtask.fromJson(Map<String, dynamic> j) =>
      Subtask((j['id'] as num).toInt(), (j['title'] ?? '').toString(), j['is_done'] == true);
}

class TaskLink {
  final int id;
  final String title, url;
  const TaskLink(this.id, this.title, this.url);

  factory TaskLink.fromJson(Map<String, dynamic> j) =>
      TaskLink((j['id'] as num).toInt(), (j['title'] ?? '').toString(), (j['url'] ?? '').toString());
}

class TaskMicroGoal {
  final String sessionId;
  final int initialConfidence, revisedConfidence, confidenceDelta;
  final String? aiRecommendedDifficulty;
  final bool? followedRecommendation;
  const TaskMicroGoal({
    required this.sessionId,
    required this.initialConfidence,
    required this.revisedConfidence,
    required this.confidenceDelta,
    this.aiRecommendedDifficulty,
    this.followedRecommendation,
  });

  factory TaskMicroGoal.fromJson(Map<String, dynamic> j) => TaskMicroGoal(
        sessionId: (j['session_id'] ?? '').toString(),
        initialConfidence: (j['initial_confidence'] as num).toInt(),
        revisedConfidence: (j['revised_confidence'] as num).toInt(),
        confidenceDelta: (j['confidence_delta'] as num).toInt(),
        aiRecommendedDifficulty: j['ai_recommended_difficulty']?.toString(),
        followedRecommendation: j['followed_recommendation'] as bool?,
      );
}

class Task {
  final String id, course, title, description, strategy, learningGoal, priority, status;
  final List<String> strategyMethods;
  final String? deadlineDate, deadlineTime, difficulty, feltDifficulty;
  final bool trackGrades;
  final List<Subtask> subtasks;
  final List<TaskLink> links;
  final TaskMicroGoal? microGoal;
  final DateTime? createdAt, startedAt, doneAt;
  final int? durationMinutes, rewardId;

  const Task({
    required this.id,
    required this.course,
    required this.title,
    required this.description,
    required this.strategy,
    required this.learningGoal,
    required this.priority,
    required this.status,
    required this.strategyMethods,
    required this.trackGrades,
    required this.subtasks,
    required this.links,
    this.deadlineDate,
    this.deadlineTime,
    this.difficulty,
    this.feltDifficulty,
    this.microGoal,
    this.createdAt,
    this.startedAt,
    this.doneAt,
    this.durationMinutes,
    this.rewardId,
  });

  int get doneSubtasks => subtasks.where((s) => s.isDone).length;

  /// Tenggat sebagai waktu lokal; tanpa jam dianggap berakhir pukul 23.59.
  DateTime? get dueAt {
    final d = DateTime.tryParse(deadlineDate ?? '');
    if (d == null) return null;
    final t = (deadlineTime ?? '23:59').split(':');
    return DateTime(d.year, d.month, d.day, int.tryParse(t[0]) ?? 23, int.tryParse(t[1]) ?? 59);
  }

  factory Task.fromJson(Map<String, dynamic> j) {
    List<T> list<T>(dynamic v, T Function(Map<String, dynamic>) f) =>
        v is List ? v.map((e) => f(e as Map<String, dynamic>)).toList() : <T>[];
    final mg = j['micro_goal'];
    return Task(
      id: (j['id'] ?? '').toString(),
      course: (j['course'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      strategy: (j['strategy'] ?? '').toString(),
      learningGoal: (j['learning_goal'] ?? '').toString(),
      priority: (j['priority'] ?? 'sedang').toString(),
      status: (j['status'] ?? 'planning').toString(),
      strategyMethods: j['strategy_methods'] is List
          ? (j['strategy_methods'] as List).map((e) => e.toString()).toList()
          : <String>[],
      trackGrades: j['track_grades'] == true,
      subtasks: list(j['subtasks'], Subtask.fromJson),
      links: list(j['links'], TaskLink.fromJson),
      deadlineDate: j['deadline_date']?.toString(),
      deadlineTime: j['deadline_time']?.toString(),
      difficulty: j['difficulty']?.toString(),
      feltDifficulty: j['felt_difficulty']?.toString(),
      microGoal: mg is Map<String, dynamic> ? TaskMicroGoal.fromJson(mg) : null,
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString())?.toLocal(),
      startedAt: DateTime.tryParse((j['started_at'] ?? '').toString())?.toLocal(),
      doneAt: DateTime.tryParse((j['done_at'] ?? '').toString())?.toLocal(),
      durationMinutes: (j['duration_minutes'] as num?)?.toInt(),
      rewardId: (j['reward_id'] as num?)?.toInt(),
    );
  }
}

// ---------------------------------------------------------------- format

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
String clock(String? hhmm) => (hhmm ?? '').replaceAll(':', '.');

String fmtDuration(int? m) {
  if (m == null) return '';
  if (m < 1) return '< 1 menit';
  final h = m ~/ 60, r = m % 60;
  return h > 0 ? '$h j${r > 0 ? ' $r m' : ''}' : '$r m';
}

/// Tenggat relatif untuk kartu: "Hari ini, 23.59", "Besok", "Terlambat", atau tanggal singkat.
class DueInfo {
  final String text;
  final Color color;

  /// 'late' | 'today' | 'soon' | 'none' | 'far' (dipakai untuk warna teks kartu papan).
  final String cls;
  const DueInfo(this.text, this.color, [this.cls = 'far']);
}

DueInfo dueInfo(Task t) {
  const grey = Color(0xFF94A3B8);
  final due = t.dueAt;
  if (due == null) return const DueInfo('Tidak ada', grey, 'none');
  final tail = t.deadlineTime != null ? ', ${clock(t.deadlineTime)}' : '';
  if (t.status == 'done') return DueInfo('${shortDate(due)}$tail', grey, 'none');
  final now = DateTime.now();
  if (due.isBefore(now)) return const DueInfo('Terlambat', Color(0xFFE11D48), 'late');
  final days = DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days == 0) return DueInfo('Hari ini$tail', const Color(0xFFD97706), 'today');
  if (days == 1) return DueInfo('Besok$tail', const Color(0xFFB45309), 'soon');
  return DueInfo('${shortDate(due)}$tail', const Color(0xFF475569));
}
