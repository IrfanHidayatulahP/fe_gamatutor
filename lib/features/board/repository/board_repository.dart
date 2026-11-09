import '../../../../core/network/api_client.dart';
import '../data/board_model.dart';
import '../data/column_model.dart';

class BoardRepository {
  final ApiClient _apiClient;

  BoardRepository({required this._apiClient});

  Future<BoardResponse> getBoard({
    String? column,
    int limit = 100,
    int offset = 0,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (column != null && column.isNotEmpty) {
      queryParams['column'] = column;
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/board',
      queryParameters: queryParams,
    );

    if (response.statusCode == 200 && response.data != null) {
      return BoardResponse.fromJson(response.data!);
    } else {
      throw Exception('Failed to load board: ${response.data?['message'] ?? response.statusCode}');
    }
  }

  Future<ColumnsResponse> getColumns() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/board/columns');

    if (response.statusCode == 200 && response.data != null) {
      return ColumnsResponse.fromJson(response.data!);
    } else {
      throw Exception('Failed to load columns: ${response.data?['message'] ?? response.statusCode}');
    }
  }
}