import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../core/models/user_model.dart';
import '../data/friendship_model.dart';

class FriendshipRepository {
  final ApiClient _apiClient;

  FriendshipRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? sl<ApiClient>();

  // Send friend request
  Future<FriendshipModel?> sendFriendRequest(String friendId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/friendships',
        data: {'friendId': friendId},
      );

      if (response.statusCode == 201 && response.data != null) {
        return FriendshipModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get user's friends
  Future<FriendshipListResponse> getFriends({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/friendships/user/$userId/friends',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipListResponse.fromJson(response.data!);
      }
      return FriendshipListResponse(friendships: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Get pending requests
  Future<PendingRequestsResponse> getPendingRequests({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/friendships/user/$userId/pending',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return PendingRequestsResponse.fromJson(response.data!);
      }
      return PendingRequestsResponse(incomingRequests: [], outgoingRequests: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Accept friend request
  Future<FriendshipModel?> acceptFriendRequest(String fsId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/friendships/$fsId/accept',
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Reject friend request
  Future<FriendshipModel?> rejectFriendRequest(String fsId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/friendships/$fsId/reject',
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Block user
  Future<FriendshipModel?> blockFriend(String fsId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/friendships/$fsId/block',
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Unblock user
  Future<FriendshipModel?> unblockFriend(String fsId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/friendships/$fsId/unblock',
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Remove friendship
  Future<bool> removeFriendship(String fsId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/friendships/$fsId',
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Search users by email
  Future<List<UserModel>> searchUsers(String email) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/users/search',
        queryParameters: {'email': email},
      );

      if (response.statusCode == 200 && response.data != null) {
        final usersJson = response.data!['users'] as List? ?? [];
        return usersJson.map((e) => UserModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // Get friendship by ID
  Future<FriendshipModel?> getFriendshipById(String fsId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/friendships/$fsId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get team friends (friends who share card-list-collabs)
  Future<FriendshipListResponse> getTeamFriends({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/friendships/user/$userId/team-friends',
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        return FriendshipListResponse.fromJson(response.data!);
      }
      return FriendshipListResponse(friendships: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }
}