import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../data/call_model.dart';

class CallRepository {
  final ApiClient _apiClient;

  CallRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? sl<ApiClient>();

  // Initiate call (voice-only app, always audio)
  Future<CallModel?> initiateCall({
    required String calleeId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/calls',
        data: {
          'calleeId': calleeId,
          // type is hardcoded to 'audio' on backend for voice-only app
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        final callData = response.data!['call'] as Map<String, dynamic>;
        return CallModel.fromJson(callData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Answer call with signaling data
  Future<CallModel?> answerCall({
    required String callId,
    required Map<String, dynamic> signalingData,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/calls/$callId/answer',
        data: {
          'signalingData': signalingData,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final callData = response.data!['call'] as Map<String, dynamic>;
        return CallModel.fromJson(callData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Reject call
  Future<bool> rejectCall(String callId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/calls/$callId/reject',
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // End call
  Future<bool> endCall(String callId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/calls/$callId/end',
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Cancel call
  Future<bool> cancelCall(String callId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/calls/$callId/cancel',
      );
      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Get call by ID
  Future<CallModel?> getCallById(String callId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/calls/$callId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final callData = response.data!['call'] as Map<String, dynamic>;
        return CallModel.fromJson(callData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Get call history
  Future<CallHistoryResponse> getCallHistory({
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
        '/calls',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return CallHistoryResponse.fromJson(response.data!);
      }
      return CallHistoryResponse(calls: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Update call signaling data
  Future<CallModel?> updateCallSignaling({
    required String callId,
    required Map<String, dynamic> signalingData,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/calls/$callId/signaling',
        data: {
          'signalingData': signalingData,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final callData = response.data!['call'] as Map<String, dynamic>;
        return CallModel.fromJson(callData);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}