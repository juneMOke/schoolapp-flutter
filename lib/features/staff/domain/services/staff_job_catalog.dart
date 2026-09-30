import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Les fonctions qu'une école propose pour chaque catégorie d'agent, et les
/// niveaux de diplôme. Ce sont des **valeurs envoyées au serveur** telles
/// quelles (`jobTitle`, `level`), pas des libellés d'écran : elles ne se
/// traduisent pas.
///
/// Une fiche portant une fonction absente de la liste (saisie ailleurs, liste
/// modifiée) la garde : le formulaire l'ajoute alors en tête pour ne pas
/// l'effacer à l'affichage.
abstract final class StaffJobCatalog {
  static const Map<StaffCategory, List<String>> jobs = {
    StaffCategory.teacher: [
      'Enseignant titulaire',
      'Enseignant de cours',
      'Maître de maternelle',
    ],
    StaffCategory.administrative: [
      'Préfet des études',
      'Censeur',
      'Directeur de discipline',
      'Économe',
      'Secrétaire',
      'Comptable',
    ],
    StaffCategory.support: [
      'Sentinelle',
      'Huissier',
      "Agent d'entretien",
      'Chauffeur',
    ],
  };

  static const List<String> diplomaLevels = [
    "D6 — Diplôme d'État",
    'A2 — Pédagogie',
    'G3 — Graduat',
    'L2 — Licence',
    'Master',
    'Doctorat',
  ];

  /// Les fonctions de [category], [current] en tête s'il n'en fait pas partie.
  static List<String> jobsFor(StaffCategory? category, {String? current}) {
    final base = jobs[category] ?? const <String>[];
    final value = current?.trim() ?? '';
    if (value.isEmpty || base.contains(value)) return base;
    return [value, ...base];
  }
}
