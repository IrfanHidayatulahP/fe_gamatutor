import '../model/card.dart';
import 'reference_ui/task.dart'; // Sesuaikan path

class CardUiAdapter {
  static String mapDifficulty(String? diff) {
    switch (diff?.toString()) {
      case 'easy': return 'mudah';
      case 'medium': return 'sedang';
      case 'hard': return 'sulit';
      case 'expert': return 'expert'; // UI referensi punya 3, kita buat custom
      default: return 'sedang';
    }
  }

  static String mapPriority(String? prio) {
    switch (prio?.toString()) {
      case 'low': return 'rendah';
      case 'medium': return 'sedang';
      case 'high':
      case 'critical': return 'tinggi';
      default: return 'sedang';
    }
  }

  static String mapColumn(String computedColumn) {
    switch (computedColumn) {
      case 'monitoring': return 'in_progress';
      case 'controlling': return 'review';
      case 'reflection': return 'done';
      default: return 'planning';
    }
  }

  /// Konversi Card -> Task (Khusus UI)
  static Task toTask(Card c) {
    return Task(
      id: c.cardId ?? '',
      course: c.courseName ?? '',
      title: c.title ?? '',
      description: c.description ?? '',
      strategy: c.learningId ?? '',
      learningGoal: '',
      priority: mapPriority(c.priority),
      status: mapColumn(c.computedColumn),
      strategyMethods: const [],
      trackGrades: false,
      subtasks: c.subtasks.map((s) => Subtask(
        int.tryParse(s.clId ?? '0') ?? 0,
        s.subTitle ?? '',
        s.endTimeList != null,
      )).toList(),
      links: const [],
      deadlineDate: c.deadline?.toIso8601String().split('T').first,
      deadlineTime: c.deadline != null
          ? '${c.deadline!.hour.toString().padLeft(2, '0')}:${c.deadline!.minute.toString().padLeft(2, '0')}'
          : null,
      difficulty: mapDifficulty(c.difficulty),
      createdAt: c.createdAt,
      startedAt: c.startTime,
      doneAt: c.endTime,
    );
  }
}