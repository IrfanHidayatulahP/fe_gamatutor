import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../data/chat_message_model.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? sl<ApiClient>();

  // Send message
  Future<ChatMessageModel?> sendMessage({
    required String friendId,
    required String message,
    String status = 'delivered',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/chat',
        data: {
          'friendId': friendId,
          'messageChat': message,
          'status': status,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return ChatMessageModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get messages with specific user
  Future<ChatListResponse> getMessagesWithUser({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/conversation/$userId',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChatListResponse.fromJson(response.data!);
      }
      return ChatListResponse(messages: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // List all conversations
  Future<ChatListResponse> getConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChatListResponse.fromJson(response.data!);
      }
      return ChatListResponse(messages: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Get message by ID
  Future<ChatMessageModel?> getMessageById(String chatId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/chat/$chatId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChatMessageModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update message
  Future<ChatMessageModel?> updateMessage({
    required String chatId,
    required String message,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{
        'messageChat': message,
      };
      if (status != null) data['status'] = status;

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/chat/$chatId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ChatMessageModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Delete message
  Future<bool> deleteMessage(String chatId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/chat/$chatId',
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}