import 'package:dio/dio.dart';
import '../../../../../core/network/api_client.dart';
import '../data/livekit_call_model.dart';

class CallLiveKitRepository {
  final ApiClient _apiClient;

  CallLiveKitRepository({required this._apiClient});

  /// Initiate a 1-on-1 audio call via LiveKit
  /// POST /api/calls/initiate
  /// Body: { calleeId, type: 'audio' }
  /// Returns: { callId, token, roomName, livekitUrl }
  Future<CallModel> initiateCall(String calleeId) async {
    try {
      final response = await _apiClient.post(
        '/calls/initiate',
        data: {
          'calleeId': calleeId,
          'type': 'audio', // Explicitly specify audio/voice call
        },
      );

      return CallModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Accept an incoming LiveKit audio call
  /// POST /api/calls/:callId/accept
  /// Returns: { callId, token, roomName, livekitUrl, call }
  Future<CallModel> acceptCall(String callId) async {
    try {
      final response = await _apiClient.post('/calls/$callId/accept');
      return CallModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Answer an incoming call (WebRTC - uses signalingData)
  /// PUT /api/calls/:callId/answer
  /// Body: { signalingData }
  Future<void> answerCall({
    required String callId,
    required Map<String, dynamic> signalingData,
  }) async {
    try {
      await _apiClient.put(
        '/calls/$callId/answer',
        data: {'signalingData': signalingData},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Reject an incoming LiveKit audio call
  /// POST /api/calls/:callId/reject-livekit
  Future<void> rejectCall(String callId) async {
    try {
      await _apiClient.post('/calls/$callId/reject-livekit');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get call details by ID
  /// GET /api/calls/:callId
  Future<CallModel> getCallById(String callId) async {
    try {
      final response = await _apiClient.get('/calls/$callId');
      return CallModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// End a call
  /// PUT /api/calls/:callId/end (backend route is PUT)
  Future<CallModel> endCall(String callId) async {
    try {
      final response = await _apiClient.put('/calls/$callId/end');
      return CallModel.fromJson(response.data);
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