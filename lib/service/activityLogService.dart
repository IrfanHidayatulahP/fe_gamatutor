import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gamatutor_kanban/service/SecureTokenStorage.dart';
import 'package:gamatutor_kanban/service/app_config.dart';

class ActivityLogService {
  /// Ambil activity log milik user yang login
  static Future<List<dynamic>> getMyActivities({int limit = 50}) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return [];

      final userId = _getUserIdFromToken(token);
      if (userId == null) return [];

      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/activity-logs/user/$userId?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['activityLogs'] ?? [];
      } else {
        debugPrint('❌ getMyActivities: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ getMyActivities error: $e');
      return [];
    }
  }

  /// Ambil semua activity log (untuk admin / team feed)
  static Future<List<dynamic>> getAllActivities({int limit = 50}) async {
    try {
      final token = await SecureTokenStorage.getToken();
      if (token == null) return [];

      final baseUrl = await ApiConstants.getBaseUrl('');
      final response = await http.get(
        Uri.parse('$baseUrl/activity-logs?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['activityLogs'] ?? [];
      }
      debugPrint('❌ getAllActivities: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('❌ getAllActivities error: $e');
      return [];
    }
  }

  static String? _getUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      return decoded['userId'] ?? decoded['id'] ?? decoded['sub'];
    } catch (e) {
      debugPrint('❌ decode JWT error: $e');
      return null;
    }
  }
}