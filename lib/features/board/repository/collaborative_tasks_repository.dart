import '../../../../core/network/api_client.dart';
import '../data/collaborative_task_model.dart';

class CollaborativeTasksRepository {
  final ApiClient _apiClient;

  CollaborativeTasksRepository({required this._apiClient});

  /// GET /board/collaborative-tasks
  Future<List<CollaborativeTaskModel>> getCollaborativeTasks() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/board/collaborative-tasks',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> tasksJson = response.data!['tasks'] ?? [];
        return tasksJson
            .map((json) => CollaborativeTaskModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
            'Failed to load collaborative tasks: ${response.data?['message'] ?? response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}