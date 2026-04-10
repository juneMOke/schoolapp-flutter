import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';

class PaginatedResponseModel<T> {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;

  const PaginatedResponseModel({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
  });

  factory PaginatedResponseModel.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponseModel<T>(
      content: (json['content'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
    );
  }

  PaginatedResponse<T> toPaginatedResponse() => PaginatedResponse<T>(
    content: content,
    totalElements: totalElements,
    totalPages: totalPages,
    page: page,
    size: size,
  );
}
