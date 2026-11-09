// lib/services/user_quiz_service.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/model/Rekomendasi.dart';
import 'package:gamatutor_kanban/model/quiz.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/service/app_config.dart';
import 'package:gamatutor_kanban/service/secureTokenStorage.dart';

class rekomendasiService {
  // Mengambil unlocked features berdasarkan userId
  static Future<List<String>> getUnlockedFeatures(
    String userId,
    String token,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http
          .get(
            Uri.parse('$baseUrl/user-quiz-results/latest/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Koneksi timeout ke server.'),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quizResult = data['quizResult'];
        if (quizResult == null) return [];

        final List<dynamic> unlockedJson =
            quizResult['unlocked_features'] ??
            quizResult['unlockedFeatures'] ??
            [];

        return unlockedJson.map((e) => e.toString()).toList();
      }

      return [];
    } catch (e) {
      print("Error fetching unlocked features: $e");
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // getMslqQuestions — ROBUST PARSER
  // Handles berbagai format response:
  //   - {questions: [...]}
  //   - {data: [...]}
  //   - {items: [...]}
  //   - [...] (array langsung)
  // ═══════════════════════════════════════════════════════════════
  static Future<List<MslqQuestion>> getMslqQuestions() async {
    final token = await SecureTokenStorage.getToken();
    if (token == null) throw Exception('Sesi berakhir, login ulang.');
    final baseUrl = await ApiConstants.getBaseUrl('');

    final response = await http
        .get(
          Uri.parse('$baseUrl/llmRekomen/questions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 15));

    // ─── DEBUG LOGGING ───
    debugPrint('🔍 [QUIZ] Status: ${response.statusCode}');
    debugPrint('🔍 [QUIZ] Body length: ${response.body.length} chars');
    final preview = response.body.length > 1000
        ? '${response.body.substring(0, 1000)}...'
        : response.body;
    debugPrint('🔍 [QUIZ] Body preview: $preview');
    // ─────────────────────

    if (response.statusCode == 401) {
      throw Exception('Token expired, silakan login ulang.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat pertanyaan kuis (status ${response.statusCode})',
      );
    }

    final dynamic data = jsonDecode(response.body);

    // ─── EKSTRAK LIST SOAL DARI BERBAGAI FORMAT ───
    List<dynamic> rawList = [];

    if (data is List) {
      // Format: response langsung array [...]
      debugPrint('🔍 [QUIZ] Format: List langsung (${data.length} item)');
      rawList = data;
    } else if (data is Map) {
      debugPrint('🔍 [QUIZ] Format: Map dengan keys = ${data.keys.toList()}');

      // Coba berbagai kemungkinan key
      final candidates = [
        data['questions'],
        data['data'],
        data['items'],
        data['result'],
        data['list'],
      ];

      for (final candidate in candidates) {
        if (candidate is List) {
          rawList = candidate;
          debugPrint(
            '🔍 [QUIZ] Ketemu list di salah satu key (${rawList.length} item)',
          );
          break;
        }
      }

      if (rawList.isEmpty) {
        throw Exception(
          'Response Map tapi tidak ada array soal. Keys: ${data.keys.toList()}',
        );
      }
    } else {
      throw Exception('Format response tidak dikenali: ${data.runtimeType}');
    }

    if (rawList.isEmpty) {
      throw Exception('Backend mengembalikan 0 soal.');
    }

    // ─── PARSE TIAP SOAL ───
    final List<MslqQuestion> questions = [];
    for (int i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      if (item is! Map<String, dynamic>) {
        debugPrint('⚠️ [QUIZ] Item[$i] bukan Map, tipe: ${item.runtimeType}');
        continue;
      }
      try {
        final q = MslqQuestion.fromJson(item);
        questions.add(q);
      } catch (e) {
        debugPrint('⚠️ [QUIZ] Gagal parse item[$i]: $e');
        debugPrint('⚠️ [QUIZ] Item[$i] = $item');
      }
    }

    debugPrint(
      '🔍 [QUIZ] Berhasil parse ${questions.length}/${rawList.length} soal',
    );

    if (questions.isEmpty) {
      throw Exception(
        'Backend kirim ${rawList.length} item tapi semua gagal diparse. Cek format di log.',
      );
    }

    return questions;
  }

  static Future<Rekomendasi?> getLatestRecommendation(String userId) async {
    try {
      final token = await SecureTokenStorage.getToken();
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/user-quiz-results/latest/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['quizResult'] == null) {
          return null;
        }
        return Rekomendasi.fromJson(data['quizResult']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching latest recommendation: $e");
      return null;
    }
  }

  static Future<Rekomendasi> submitQuiz(
    Map<String, int> answersMap, // ← Map<String, int>, bukan List<Map>
  ) async {
    final token = await SecureTokenStorage.getToken();
    if (token == null) throw Exception('Sesi berakhir, login ulang.');
    final baseUrl = await ApiConstants.getBaseUrl('');

    // ─── KIRIM SEBAGAI OBJECT ───
    final bodyData = jsonEncode({
      'answersPayload': answersMap, // ← ini sudah Object/Map
    });
    print("DEBUG SUBMIT QUIZ PAYLOAD: $bodyData");

    final response = await http
        .post(
          Uri.parse('$baseUrl/user-quiz-results/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: bodyData,
        )
        .timeout(const Duration(seconds: 30));

    print("DEBUG RESPONSE STATUS: ${response.statusCode}");
    print("DEBUG RESPONSE BODY: ${response.body}");

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final quizResultJson = data['quizResult'] ?? data;
      return Rekomendasi.fromJson(quizResultJson);
    } else {
      throw Exception('Gagal mengirim hasil kuis: ${response.body}');
    }
  }

  static Future<String> generateLlmFeedback({
    required String dominantStrategy,
    required String userProfile,
    required Map<String, dynamic> answersPayload,
  }) async {
    try {
      final token = await SecureTokenStorage.getToken();
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.post(
        Uri.parse('$baseUrl/llmRekomen/generate-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'dominantStrategy': dominantStrategy,
          'userProfile': userProfile,
          'answersPayload': answersPayload,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['feedback'] ??
            'Gunakan strategi belajarmu untuk mengorganisir tugas harian di Kanban board.';
      } else {
        return 'Gunakan strategi $dominantStrategy kamu untuk membagi tugas-tugas besar di Kanban board.';
      }
    } catch (e) {
      return 'Gunakan strategi $dominantStrategy kamu untuk membagi tugas-tugas besar di Kanban board.';
    }
  }
}
