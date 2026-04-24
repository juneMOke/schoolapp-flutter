import 'package:school_app_flutter/features/enrollment/data/models/enrollment_summary_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary_page.dart';

class EnrollmentSummaryPageModel {
  final List<EnrollmentSummaryModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const EnrollmentSummaryPageModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory EnrollmentSummaryPageModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List<dynamic>?;
    return EnrollmentSummaryPageModel(
      content: (rawContent ?? const <dynamic>[])
          .map((item) => EnrollmentSummaryModel.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  EnrollmentSummaryPage toEnrollmentSummaryPage() => EnrollmentSummaryPage(
    content: content.map((item) => item.toEnrollmentSummary()).toList(growable: false),
    page: page,
    size: size,
    totalElements: totalElements,
    totalPages: totalPages,
  );
}
