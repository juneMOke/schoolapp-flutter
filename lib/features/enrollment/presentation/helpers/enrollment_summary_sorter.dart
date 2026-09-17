import 'package:school_app_flutter/core/helpers/student_name_comparator.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';

/// Ce sur quoi une table de résumés se trie.
///
/// [identity] est la cascade complète Nom → Post-nom → Prénom : c'est l'ordre
/// par défaut de toutes les listes d'élèves. Les trois champs isolés servent
/// une colonne cliquée en particulier — ils placent ce champ en tête, mais
/// gardent la cascade en départage, sans quoi deux homonymes du champ trié
/// s'ordonneraient au hasard de leur arrivée.
enum EnrollmentSummarySortField {
  identity,
  lastName,
  surname,
  firstName,
  dateOfBirth,
}

/// Tri **partagé** des résumés d'inscription — Inscriptions, Facturation et
/// Documents rendent les mêmes colonnes et doivent les ordonner pareil.
///
/// Les trois tables portaient jusqu'ici trois comparateurs distincts : l'un
/// minusculait, l'autre non, aucun ne repliait les accents, et la clé de tri
/// des Inscriptions (`Nom|Prénom|Post-nom`) divergeait de ce que la colonne
/// affiche. La règle d'ordre ne vit plus qu'ici, adossée à
/// [StudentNameComparator].
abstract final class EnrollmentSummarySorter {
  /// Ordonne [summaries] sans le muter.
  ///
  /// Les fiches dont le champ trié est **vide** ferment la marche, y compris en
  /// ordre descendant : un tri inversé n'est pas une raison de promouvoir en
  /// tête ceux dont on ne sait justement rien. Même convention que les non
  /// classés de la table Résultats.
  static List<EnrollmentSummary> sort(
    List<EnrollmentSummary> summaries,
    EnrollmentSummarySortField field, {
    required bool ascending,
  }) {
    final named = <EnrollmentSummary>[];
    final blank = <EnrollmentSummary>[];
    for (final summary in summaries) {
      (_leadingValue(summary, field).trim().isEmpty ? blank : named).add(
        summary,
      );
    }

    named.sort(_comparatorFor(field));
    final ordered = ascending ? named : named.reversed.toList(growable: false);

    return [...ordered, ...blank];
  }

  /// La valeur qui décide si la fiche a « quelque chose à trier » — celle du
  /// rang de tête, pas de la cascade entière : un élève sans post-nom garde sa
  /// place alphabétique quand on trie par nom.
  static String _leadingValue(
    EnrollmentSummary summary,
    EnrollmentSummarySortField field,
  ) => switch (field) {
    EnrollmentSummarySortField.identity ||
    EnrollmentSummarySortField.lastName => summary.student.lastName,
    EnrollmentSummarySortField.surname => summary.student.surname,
    EnrollmentSummarySortField.firstName => summary.student.firstName,
    EnrollmentSummarySortField.dateOfBirth => summary.student.dateOfBirth,
  };

  static Comparator<EnrollmentSummary> _comparatorFor(
    EnrollmentSummarySortField field,
  ) => switch (field) {
    EnrollmentSummarySortField.identity ||
    EnrollmentSummarySortField.lastName => _identity,
    EnrollmentSummarySortField.surname => _leadingWith(
      (s) => s.student.surname,
    ),
    EnrollmentSummarySortField.firstName => _leadingWith(
      (s) => s.student.firstName,
    ),
    EnrollmentSummarySortField.dateOfBirth => _byDateOfBirth,
  };

  static final Comparator<EnrollmentSummary> _identity =
      StudentNameComparator.by<EnrollmentSummary>(
        lastName: (s) => s.student.lastName,
        surname: (s) => s.student.surname,
        firstName: (s) => s.student.firstName,
        id: (s) => s.student.id,
      );

  /// Le champ cliqué d'abord, la cascade d'identité ensuite.
  static Comparator<EnrollmentSummary> _leadingWith(
    String? Function(EnrollmentSummary summary) leading,
  ) {
    return (a, b) {
      final byLeading = StudentNameComparator.comparePart(
        leading(a),
        leading(b),
      );
      return byLeading != 0 ? byLeading : _identity(a, b);
    };
  }

  /// La date de naissance est stockée en ISO (`yyyy-MM-dd`) : son ordre
  /// lexicographique EST son ordre chronologique, aucune conversion requise.
  static int _byDateOfBirth(EnrollmentSummary a, EnrollmentSummary b) {
    final byDate = a.student.dateOfBirth.compareTo(b.student.dateOfBirth);
    return byDate != 0 ? byDate : _identity(a, b);
  }
}
