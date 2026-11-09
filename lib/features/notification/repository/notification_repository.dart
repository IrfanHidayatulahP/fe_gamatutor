import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../data/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? sl<ApiClient>();

  // Get notifications
  Future<NotificationListResponse> getNotifications({
    String? type,
    bool? read,
    bool? delivered,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (type != null) queryParams['type'] = type;
      if (read != null) queryParams['read'] = read;
      if (delivered != null) queryParams['delivered'] = delivered;

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        return NotificationListResponse.fromJson(response.data!);
      }
      return NotificationListResponse(notifications: [], total: 0);
    } catch (e) {
      rethrow;
    }
  }

  // Get notification by ID
  Future<NotificationModel?> getNotificationById(String notifId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/notifications/$notifId',
      );

      if (response.statusCode == 200 && response.data != null) {
        return NotificationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Mark as read
  Future<NotificationModel?> markAsRead(String notifId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/notifications/$notifId/read',
      );

      if (response.statusCode == 200 && response.data != null) {
        return NotificationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Mark as clicked
  Future<NotificationModel?> markAsClicked(String notifId) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/notifications/$notifId/click',
      );

      if (response.statusCode == 200 && response.data != null) {
        return NotificationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/notifications/read-all',
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notifId) async {
    try {
      final response = await _apiClient.delete<Map<String, dynamic>>(
        '/notifications/$notifId',
      );

      return response.statusCode == 200;
    } catch (e) {
      rethrow;
    }
  }

  // Create notification (admin typically)
  Future<NotificationModel?> createNotification({
    required String userId,
    required String type,
    required String message,
    String? title,
    DateTime? scheduledFor,
    String? reminderReason,
    String? triggerAction,
    String? triggerUserId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/notifications',
        data: {
          'userId': userId,
          'type': type,
          'message': message,
          'title': title,
          'scheduledFor': scheduledFor?.toIso8601String(),
          'reminderReason': reminderReason,
          'triggerAction': triggerAction,
          'triggerUserId': triggerUserId,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        return NotificationModel.fromJson(response.data!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}