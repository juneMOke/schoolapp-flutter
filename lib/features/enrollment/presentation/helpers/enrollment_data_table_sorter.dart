import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/helpers/enrollment_summary_sorter.dart';

/// Énumération des colonnes triables dans la table Enrollment.
enum EnrollmentSortColumn { student, dateOfBirth }

/// Traduit une colonne de la table Enrollment en champ de tri.
///
/// La règle d'ordre elle-même vit dans [EnrollmentSummarySorter], partagée avec
/// la Facturation et les Documents : ce fichier ne fait plus que nommer la
/// colonne cliquée.
///
/// La clé de la colonne « élève » concaténait `Nom|Prénom|Post-nom` alors que la
/// table affiche « Nom Post-nom Prénom » — deux fiches de même nom se classaient
/// donc dans un ordre que la colonne ne montrait pas.
class EnrollmentDataTableSorter {
  const EnrollmentDataTableSorter._();

  /// Trie une liste d'[EnrollmentSummary] par colonne et direction.
  static List<EnrollmentSummary> sort(
    List<EnrollmentSummary> enrollments,
    EnrollmentSortColumn column,
    bool ascending,
  ) => EnrollmentSummarySorter.sort(enrollments, switch (column) {
    EnrollmentSortColumn.student => EnrollmentSummarySortField.identity,
    EnrollmentSortColumn.dateOfBirth => EnrollmentSummarySortField.dateOfBirth,
  }, ascending: ascending);
}
