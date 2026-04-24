import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

class EnrollmentSummaryPage {
  final List<EnrollmentSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const EnrollmentSummaryPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });
}
