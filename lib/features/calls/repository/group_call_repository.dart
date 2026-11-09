import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../data/group_call_model.dart';

class GroupCallRepository {
  final ApiClient _apiClient;

  GroupCallRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? sl<ApiClient>();

  // Create group call
  Future<GroupCallModel?> createGroupCall({
    required String title,
    required String type,
    DateTime? scheduledAt,
    int maxParticipants = 10,
    bool isRecording = false,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/group-calls',
        data: {
          'title': title,
          'type': type,
          'scheduledAt': scheduledAt?.toIso8601String(),
          'maxParticipants': maxParticipants,
          'isRecording': isRecording,
          'settings': settings ?? {},
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final groupCallData = response.data!['groupCall'] as Map<String, dynamic>;
        return GroupCallModel.fromJson(groupCallData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Join group call
  Future<GroupCallModel?> joinGroupCall(String groupCallId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/group-calls/$groupCallId/join',
      );

      if (response.statusCode == 200 && response.data != null) {
        final groupCallData = response.data!['groupCall'] as Map<String, dynamic>;
        return GroupCallModel.fromJson(groupCallData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Leave group call
  Future<bool> leaveGroupCall(String groupCallId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/group-calls/$groupCallId/leave',
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // End group call (host only)
  Future<bool> endGroupCall(String groupCallId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/group-calls/$groupCallId/end',
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Get group call by ID
  Future<GroupCallModel?> getGroupCallById(String groupCallId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/group-calls/$groupCallId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final groupCallData = response.data!['groupCall'] as Map<String, dynamic>;
        return GroupCallModel.fromJson(groupCallData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get group call history
  Future<GroupCallHistoryResponse> getGroupCallHistory({
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (status != null) queryParams['status'] = status;
      if (fromDate != null) queryParams['fromDate'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['toDate'] = toDate.toIso8601String();

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/group-calls',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return GroupCallHistoryResponse.fromJson(response.data!);
      }
      return GroupCallHistoryResponse(groupCalls: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Get participants
  Future<GroupCallParticipantsResponse> getParticipants(String groupCallId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/group-calls/$groupCallId/participants',
      );

      if (response.statusCode == 200 && response.data != null) {
        return GroupCallParticipantsResponse.fromJson(response.data!);
      }
      return GroupCallParticipantsResponse(participants: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Update group call settings (host only)
  Future<GroupCallModel?> updateGroupCallSettings({
    required String groupCallId,
    String? title,
    bool? isRecording,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (isRecording != null) data['isRecording'] = isRecording;
      if (settings != null) data['settings'] = settings;

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/group-calls/$groupCallId/settings',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final groupCallData = response.data!['groupCall'] as Map<String, dynamic>;
        return GroupCallModel.fromJson(groupCallData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Update participant (host/moderator)
  Future<GroupCallParticipantModel?> updateParticipant({
    required String groupCallId,
    required String participantId,
    String? role,
    bool? isMuted,
    bool? isScreenSharing,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (role != null) data['role'] = role;
      if (isMuted != null) data['isMuted'] = isMuted;
      if (isScreenSharing != null) data['isScreenSharing'] = isScreenSharing;

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/group-calls/$groupCallId/participants/$participantId',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        final participantData = response.data!['participant'] as Map<String, dynamic>;
        return GroupCallParticipantModel.fromJson(participantData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}