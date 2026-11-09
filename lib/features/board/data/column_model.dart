import 'package:equatable/equatable.dart';

class ColumnModel extends Equatable {
  final String id;
  final String title;
  final int order;

  const ColumnModel({
    required this.id,
    required this.title,
    required this.order,
  });

  factory ColumnModel.fromJson(Map<String, dynamic> json) {
    return ColumnModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'order': order,
    };
  }

  @override
  List<Object?> get props => [id, title, order];
}

class ColumnsResponse extends Equatable {
  final List<ColumnModel> columns;

  const ColumnsResponse({required this.columns});

  factory ColumnsResponse.fromJson(Map<String, dynamic> json) {
    final list = json['columns'] as List? ?? [];
    return ColumnsResponse(
      columns: list.map((e) => ColumnModel.fromJson(e)).toList(),
    );
  }

  @override
  List<Object?> get props => [columns];
}