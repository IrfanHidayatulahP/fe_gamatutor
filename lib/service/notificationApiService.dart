import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationApiService {
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  static Future<List<dynamic>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'] ?? [];
    }
    return [];
  }

  static Future<bool> handleAction(String token, String notifId, String action) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notifId/action'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'action': action}), // 'accept' atau 'decline'
    );
    return response.statusCode == 200;
  }
}