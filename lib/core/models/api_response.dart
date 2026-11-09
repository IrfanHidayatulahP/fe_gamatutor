import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final bool success;
  final T? data;
  final String? message;
  final List<ApiError>? errors;
  final int? statusCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? json['error'] == null,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] ?? json['error'],
      errors: json['errors'] != null
          ? (json['errors'] as List)
              .map((e) => ApiError.fromJson(e))
              .toList()
          : null,
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return {
      'success': success,
      'data': data != null ? toJsonT(data as T) : null,
      'message': message,
      'errors': errors?.map((e) => e.toJson()).toList(),
      'statusCode': statusCode,
    };
  }

  @override
  List<Object?> get props => [success, data, message, errors, statusCode];
}

class ApiError extends Equatable {
  final String field;
  final String message;

  const ApiError({required this.field, required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      field: json['field'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'field': field, 'message': message};
  }

  @override
  List<Object?> get props => [field, message];
}

class PaginatedResponse<T> extends Equatable {
  final List<T> items;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final itemsJson = json['items'] ?? json['data'] ?? json['users'] ?? json['calls'] ?? json['notifications'] ?? json['friendships'] ?? json['messages'] ?? [];
    return PaginatedResponse<T>(
      items: (itemsJson as List).map((e) => fromJsonT(e)).toList(),
      total: json['total'] ?? itemsJson.length,
      limit: json['limit'] ?? 50,
      offset: json['offset'] ?? 0,
      hasMore: (json['offset'] ?? 0) + (itemsJson).length < (json['total'] ?? itemsJson.length),
    );
  }

  @override
  List<Object?> get props => [items, total, limit, offset, hasMore];
}