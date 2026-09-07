import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model/day_enrollment_entry_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats/day_enrollment_entry.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';

/// Une page de la liste nominative du jour.
///
/// Modèle **concret** plutôt que `PaginatedResponseModel<T>` : Retrofit
/// désérialise sur un `fromJson(Map)` à un seul paramètre, et la fabrique
/// générique en demande deux. C'est déjà le choix fait pour
/// `EnrollmentSummaryPageModel`, sur le même endpoint paginé.
class DayEntriesPageModel {
  final List<DayEnrollmentEntryModel> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const DayEntriesPageModel({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory DayEntriesPageModel.fromJson(Map<String, dynamic> json) {
    final rawContent = json['content'] as List<dynamic>?;
    return DayEntriesPageModel(
      content: (rawContent ?? const <dynamic>[])
          .map(
            (item) =>
                DayEnrollmentEntryModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      page: json['page'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      totalElements: json['totalElements'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }

  PaginatedResponse<DayEnrollmentEntry> toEntity() =>
      PaginatedResponse<DayEnrollmentEntry>(
        content: content.map((item) => item.toEntity()).toList(growable: false),
        page: page,
        size: size,
        totalElements: totalElements,
        totalPages: totalPages,
      );
}
