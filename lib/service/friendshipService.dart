import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendshipService {
  // Sesuaikan dengan Base URL backend Anda (misal: http://localhost:3000/api atau IP emulator 10.0.2.2)
  static const String baseUrl = 'http://10.0.2.2:3000/api'; 

  // Mengirim Permintaan Pertemanan (Add Friend)
  static Future<bool> sendFriendRequest(String token, String friendId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/friendships'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'friendId': friendId}),
    );
    return response.statusCode == 201;
  }

  // Membatalkan Permintaan Pertemanan (Tombol "Batal")
  static Future<bool> cancelFriendRequest(String token, String friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/friendships/cancel/$friendId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }

  // Mengambil Daftar Teman Terhubung (Accepted)
  static Future<List<dynamic>> getUserFriends(String token, String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/friendships/user/$userId/friends'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['friendships'] ?? [];
    }
    return [];
  }

  // Menerima Permintaan Pertemanan (Accept dari Notifikasi)
  static Future<bool> acceptFriendRequest(String token, String fsId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/friendships/$fsId/accept'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    return response.statusCode == 200;
  }
}