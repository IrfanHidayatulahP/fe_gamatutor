class MslqQuestion {
  final String? id;
  final String category;
  final String questionText;
  final List<QuestionOption> options;

  MslqQuestion({
    required this.category,
    required this.questionText,
    required this.options, 
    required this.id,
  });

  factory MslqQuestion.fromJson(Map<String, dynamic> json) {
    final dynamic rawOptions = json['options'];
    final List<QuestionOption> parsedOptions = [];

    if (rawOptions is List) {
      // ─── Format standar: [{text: "...", score: 3}, ...] ───
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          parsedOptions.add(QuestionOption.fromJson(o));
        }
      }
    } else if (rawOptions is Map) {
      // ─── Format backend static fallback: {"1": "text", "2": "...", "3": "..."} ───
      // Kunci map adalah score, value adalah text
      rawOptions.forEach((key, value) {
        final score = int.tryParse(key.toString()) ?? 0;
        if (score > 0 && value is String) {
          parsedOptions.add(QuestionOption(text: value, score: score));
        }
      });
      // Sort by score (1, 2, 3) supaya urutan konsisten
      parsedOptions.sort((a, b) => a.score.compareTo(b.score));
    }

    return MslqQuestion(
      id: (json['static_q_id'] ?? json['id'])?.toString(),
      category: json['category'] ?? 'time_management',
      questionText: json['question_text'] ??
          json['questionText'] ??
          'Pertanyaan tidak tersedia',
      options: parsedOptions, 
    );
  }
}

class QuestionOption {
  final String text;
  final int score;

  QuestionOption({required this.text, required this.score});

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      text: json['text'] ?? '',
      score: (json['score'] as num?)?.toInt() ?? 1,
    );
  }
}