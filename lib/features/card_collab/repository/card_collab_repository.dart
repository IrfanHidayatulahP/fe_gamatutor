import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../data/card_collab_model.dart';

class CardCollabRepository {
  final ApiClient _apiClient;

  CardCollabRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? sl<ApiClient>();

  // Add collaborator
  Future<CardCollaborationModel?> addCollaborator({
    required String cardId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/card-list-collabs/card/$cardId',
        data: {'userId': userId, 'role': role},
      );

      if (response.statusCode == 201 && response.data != null) {
        return CardCollaborationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get collaborators for card
  Future<CardCollabListResponse> getCardCollaborators(String cardId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/card-list-collabs/card/$cardId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return CardCollabListResponse.fromJson(response.data!);
      }
      return CardCollabListResponse(collaborations: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Get user's collaborations
  Future<CardCollabListResponse> getUserCollaborations({
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final path = userId != null ? '/card-list-collabs/user/$userId' : '/card-list-collabs/user/me';
      final response = await _apiClient.get<Map<String, dynamic>>(
        path,
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return CardCollabListResponse.fromJson(response.data!);
      }
      return CardCollabListResponse(collaborations: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Get collaboration by ID
  Future<CardCollaborationModel?> getCollaborationById(String collabId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/card-list-collabs/$collabId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return CardCollaborationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update collaborator role
  Future<CardCollaborationModel?> updateCollaboratorRole({
    required String collabId,
    required String role,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/card-list-collabs/$collabId/role',
        data: {'role': role},
      );

      if (response.statusCode == 200 && response.data != null) {
        return CardCollaborationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Remove collaborator
  Future<bool> removeCollaborator(String collabId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/card-list-collabs/$collabId',
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }
}