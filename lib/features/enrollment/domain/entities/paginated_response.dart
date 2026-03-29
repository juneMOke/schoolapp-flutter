import 'package:equatable/equatable.dart';

class PaginatedResponse<T> extends Equatable {
  final List<T> content;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;

  const PaginatedResponse({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
  });

  @override
  List<Object?> get props => [content, totalElements, totalPages, page, size];
}
