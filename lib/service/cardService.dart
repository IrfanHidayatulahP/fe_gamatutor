import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gamatutor_kanban/model/learningStrat.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/model/card.dart' as model;
import 'package:gamatutor_kanban/model/cardlist.dart';
import 'package:gamatutor_kanban/model/columnmovement.dart';
import 'package:gamatutor_kanban/service/app_config.dart';
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';

class CardService {
  // ============================================================
  // FETCH LEARNING ID BY NAME / KEYCODE
  // ============================================================
  static Future<String?> fetchLearningIdByName(String identifier) async {
    try {
      final strategies = await getAllStrategies();
      final target = identifier.toString().toUpperCase().replaceAll('-', '_').trim();

      for (final s in strategies) {
        final keyCode = (s['keyCode'] ?? '').toString().toUpperCase();
        final name = (s['learningStrategy'] ?? '')
            .toString()
            .toUpperCase()
            .replaceAll('-', '_');
        if (keyCode == target || name == target) {
          return s['learningId'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ fetchLearningIdByName: $e');
      return null;
    }
  }

  // ============================================================
  // GET ALL STRATEGIES
  // ============================================================
  static Future<List<dynamic>> getAllStrategies() async {
    try {
      final token = await SecureTokenStorage.getToken();
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/learning-strats'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      debugPrint('=== FETCH STRATEGIES ===');
      debugPrint('STATUS: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('learningStrats')) {
          return decodedBody['learningStrats'];
        } else if (decodedBody is List) {
          return decodedBody;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ getAllStrategies: $e');
      return [];
    }
  }

  // ============================================================
  // GET STRATEGY BY ID
  // ============================================================
  static Future<LearningStrat?> getStrategyById(
    String token,
    String learningId,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/learning-strats/$learningId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        final targetJson = decodedData['learningStrat'] ??
            decodedData['learning_strat'] ??
            decodedData['data'] ??
            decodedData;
        if (targetJson != null) {
          return LearningStrat.fromJson(targetJson);
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ getStrategyById: $e');
      return null;
    }
  }

  // ============================================================
  // GET CARDS BY USER
  // ============================================================
  Future<List<model.Card>> getCardsByUser(String token) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      debugPrint('🟦 GET /cards baseUrl=$baseUrl');

      final response = await http.get(
        Uri.parse('$baseUrl/cards'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🟦 GET /cards status=${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> body = jsonResponse['cards'] ?? [];
        debugPrint('🟦 Total cards dari backend: ${body.length}');
        return body.map((dynamic item) => model.Card.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ getCardsByUser: $e');
      return [];
    }
  }

  // ============================================================
  // GET CARD LIST BY CARD ID
  // ============================================================
  Future<List<CardList>> getCardList(String token, String cardId) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/cards/$cardId/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = decoded['cardList'] ?? decoded;
        if (list is List) {
          return list.map((e) => CardList.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ getCardList: $e');
      return [];
    }
  }

  // ============================================================
  // GET COLUMN MOVEMENTS
  // ============================================================
  Future<List<ColumnMovement>> getColumnMovements(
    String token,
    String cardId,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/column-movements/card/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => ColumnMovement.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ getColumnMovements: $e');
      return [];
    }
  }

  // ============================================================
  // CREATE CARD (POST /api/cards)
  // ============================================================
  Future<Map<String, dynamic>> createCard(
    String token,
    Map<String, dynamic> cardData,
  ) async {
    debugPrint('🟨 [A] createCard DIPANGGIL');
    try {
      debugPrint('🟨 [B] getBaseUrl...');
      final baseUrl = await ApiConstants.getBaseUrl('');
      debugPrint('🟨 [B] baseUrl = "$baseUrl"');

      final url = Uri.parse('$baseUrl/cards');
      debugPrint('🟨 [C] url = $url');

      debugPrint('🟨 [D] http.post ke backend...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(cardData),
      );

      debugPrint('🟨 [E] RESPONSE status = ${response.statusCode}');
      debugPrint('🟨 [E] RESPONSE body = ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data'] ?? jsonResponse['card'] ?? jsonResponse;
      } else {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e, stack) {
      debugPrint('🟥 [ERROR] createCard: $e');
      debugPrint('🟥 [STACK] $stack');
      rethrow;
    }
  }

  // ============================================================
  // CREATE CARD LIST
  // ============================================================
  Future<void> createCardList(
    String token,
    String cardId,
    Map<String, dynamic> subTaskData,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.post(
        Uri.parse('$baseUrl/cards/$cardId/list'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(subTaskData),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal membuat card list: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ createCardList: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPDATE CARD
  // ============================================================
  Future<bool> updateCard(
    String token,
    String cardId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.put(
        Uri.parse('$baseUrl/cards/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );
      debugPrint('🟦 PUT /cards/$cardId status=${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ updateCard: $e');
      return false;
    }
  }

  // ============================================================
  // UPDATE CARD LIST
  // ============================================================
  Future<void> updateCardList(
    String token,
    String cardId,
    String clId,
    Map<String, dynamic> subTaskData,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.put(
        Uri.parse('$baseUrl/cards/$cardId/list/$clId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(subTaskData),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal update card list: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ updateCardList: $e');
      rethrow;
    }
  }

  // ============================================================
  // DELETE CARD
  // ============================================================
  Future<bool> deleteCard(String token, String cardId) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.delete(
        Uri.parse('$baseUrl/cards/$cardId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('🗑️ DELETE /cards/$cardId status=${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('❌ deleteCard: $e');
      return false;
    }
  }

  // ============================================================
  // DELETE CARD LIST
  // ============================================================
  Future<void> deleteCardList(String token, String cardId, String clId) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.delete(
        Uri.parse('$baseUrl/cards/$cardId/list/$clId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal menghapus card list: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ deleteCardList: $e');
      rethrow;
    }
  }

  // ============================================================
  // ADD COLLABORATOR
  // ============================================================
  Future<void> addCollaborator(
    String token,
    String cardId,
    Map<String, dynamic> collabData,
  ) async {
    try {
      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.post(
        Uri.parse('$baseUrl/card-list-collab/card/$cardId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(collabData),
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Gagal menambahkan kolaborator: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ addCollaborator: $e');
      rethrow;
    }
  }
}