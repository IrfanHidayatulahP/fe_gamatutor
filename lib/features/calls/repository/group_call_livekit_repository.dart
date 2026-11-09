import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../data/livekit_group_call_model.dart';

class GroupCallLiveKitRepository {
  final ApiClient _apiClient;

  GroupCallLiveKitRepository({required this._apiClient});

  /// Join a group voice collaboration via LiveKit
  /// POST /api/group-calls/join
  /// Body: { taskId }
  /// Returns: { groupCallId, token, roomName, livekitUrl }
  Future<GroupCallModel> joinGroupCall(String taskId) async {
    try {
      final response = await _apiClient.post(
        '/group-calls/join',
        data: {'taskId': taskId},
      );

      return GroupCallModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group call details by ID
  /// GET /api/group-calls/:groupCallId
  Future<GroupCallModel> getGroupCallById(String groupCallId) async {
    try {
      final response = await _apiClient.get('/group-calls/$groupCallId');
      return GroupCallModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Leave a group call
  /// POST /api/group-calls/:groupCallId/leave
  /// Returns: { message, groupCallId }
  Future<void> leaveGroupCall(String groupCallId) async {
    try {
      await _apiClient.post('/group-calls/$groupCallId/leave');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// End a group call (host only)
  /// POST /api/group-calls/:groupCallId/end
  /// Returns: { message, groupCallId }
  Future<void> endGroupCall(String groupCallId) async {
    try {
      await _apiClient.post('/group-calls/$groupCallId/end');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get group call history
  /// GET /api/group-calls
  Future<List<GroupCallModel>> getGroupCallHistory() async {
    try {
      final response = await _apiClient.get('/group-calls');
      final List<dynamic> data = response.data;
      return data.map((json) => GroupCallModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final message = e.response?.data['message'] ?? 'Unknown error';
      return Exception('API Error: $message');
    }
    return Exception('Network Error: ${e.message}');
  }
}