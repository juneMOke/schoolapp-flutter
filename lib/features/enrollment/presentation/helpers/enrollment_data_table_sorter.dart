import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

/// Énumération des colonnes triables dans la table Enrollment.
enum EnrollmentSortColumn { student, dateOfBirth }

/// Service stateless pour gérer le tri des résumés d'inscription.
///
/// Extrait la logique tri de [EnrollmentDataTable] pour la rendre
/// testable et réutilisable.
class EnrollmentDataTableSorter {
  const EnrollmentDataTableSorter._();

  /// Trie une liste d'[EnrollmentSummary] par colonne et direction.
  static List<EnrollmentSummary> sort(
    List<EnrollmentSummary> enrollments,
    EnrollmentSortColumn column,
    bool ascending,
  ) {
    final list = [...enrollments];
    list.sort((a, b) {
      final aValue = _getColumnValue(a, column);
      final bValue = _getColumnValue(b, column);
      final cmp = aValue.compareTo(bValue);
      return ascending ? cmp : -cmp;
    });
    return list;
  }

  /// Extrait la valeur d'une colonne pour un [EnrollmentSummary].
  static String _getColumnValue(
    EnrollmentSummary enrollment,
    EnrollmentSortColumn column,
  ) {
    return switch (column) {
      EnrollmentSortColumn.student =>
        '${enrollment.student.lastName}|${enrollment.student.firstName}|${enrollment.student.surname}',
      EnrollmentSortColumn.dateOfBirth => enrollment.student.dateOfBirth,
    };
  }
}
