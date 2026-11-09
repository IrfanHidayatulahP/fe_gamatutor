// Model Micro-Goals (Cek Pemahaman). Bentuk JSON mengikuti backend: /api/micro-goals (snake_case).

/// Urutan dan label tingkat kesulitan. Kode (Inggris) disimpan di database,
/// label (Indonesia) hanya untuk tampilan. Ubah label di sini bila ingin mengganti istilah.
const List<String> kDifficultyOrder = ['mudah', 'sedang', 'sulit'];
const Map<String, String> kDifficultyLabels = {
  'mudah': 'Mudah',
  'sedang': 'Sedang',
  'sulit': 'Sulit',
};

String difficultyLabel(String? code) => kDifficultyLabels[code] ?? '-';

/// Konteks tugas yang dikirim saat sesi dibuat (tugas belum tersimpan di database).
class MicroGoalContext {
  final String courseName;
  final String taskTitle;
  final String taskDescription;
  final String learningGoal;

  const MicroGoalContext({
    required this.courseName,
    required this.taskTitle,
    this.taskDescription = '',
    this.learningGoal = '',
  });
}

class MicroGoalInsight {
  final String text;
  final String reason;
  final String recommendedDifficulty; // easy | medium | hard
  final String source; // llm | fallback
  final String? conceptCoverage; // rendah | sedang | tinggi
  final String? conceptAccuracy; // rendah | sedang | tinggi | unknown
  final List<String> keyElements;
  final List<String> knowledgeGaps;

  const MicroGoalInsight({
    required this.text,
    required this.reason,
    required this.recommendedDifficulty,
    required this.source,
    this.conceptCoverage,
    this.conceptAccuracy,
    this.keyElements = const [],
    this.knowledgeGaps = const [],
  });

  bool get isLlm => source == 'llm';

  factory MicroGoalInsight.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : <String>[];
    return MicroGoalInsight(
      text: (json['text'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      recommendedDifficulty: (json['recommended_difficulty'] ?? 'sedang').toString(),
      source: (json['source'] ?? 'fallback').toString(),
      conceptCoverage: json['concept_coverage']?.toString(),
      conceptAccuracy: json['concept_accuracy']?.toString(),
      keyElements: strings(json['key_elements']),
      knowledgeGaps: strings(json['knowledge_gaps']),
    );
  }
}

class MicroGoalSession {
  final String sessionId;
  final String status; // started | analyzed | completed
  final int attemptNo;
  final String courseName;
  final String taskTitle;
  final int initialConfidence;
  final String? articulationText;
  final int? wordCount;
  final MicroGoalInsight? insight;
  final int? revisedConfidence;
  final int? confidenceDelta;
  final String? taskId;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const MicroGoalSession({
    required this.sessionId,
    required this.status,
    required this.attemptNo,
    required this.courseName,
    required this.taskTitle,
    required this.initialConfidence,
    this.articulationText,
    this.wordCount,
    this.insight,
    this.revisedConfidence,
    this.confidenceDelta,
    this.taskId,
    this.createdAt,
    this.completedAt,
  });

  bool get isCompleted => status == 'completed';
  bool get isAnalyzed => status == 'analyzed';

  /// Langkah (1-4) tempat sesi ini dilanjutkan.
  int get resumeStep {
    if (status == 'analyzed') return 3;
    if (status == 'started') return 2;
    return 4;
  }

  factory MicroGoalSession.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) => v == null ? null : (v as num).toInt();
    final dynamic rawInsight = json['insight'];
    return MicroGoalSession(
      sessionId: (json['id'] ?? '').toString(),
      status: (json['status'] ?? 'started').toString(),
      attemptNo: asInt(json['attempt_no']) ?? 1,
      courseName: (json['course'] ?? '').toString(),
      taskTitle: (json['task_title'] ?? '').toString(),
      initialConfidence: asInt(json['initial_confidence']) ?? 0,
      articulationText: json['articulation_text']?.toString(),
      wordCount: asInt(json['word_count']),
      insight: rawInsight is Map<String, dynamic> ? MicroGoalInsight.fromJson(rawInsight) : null,
      revisedConfidence: asInt(json['revised_confidence']),
      confidenceDelta: asInt(json['confidence_delta']),
      taskId: json['task_id']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
      completedAt: DateTime.tryParse((json['completed_at'] ?? '').toString()),
    );
  }
}
