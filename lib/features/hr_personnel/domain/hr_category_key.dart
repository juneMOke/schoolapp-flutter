import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// La catégorie d'un agent telle que le module RH · Personnel la compte : les
/// trois du fichier, plus [unknown] pour une fiche dont la catégorie est
/// absente ou inconnue de ce poste (valeur ajoutée par le serveur sans
/// release).
///
/// Sans [unknown], un agent illisible sortirait des barres « Par catégorie » et
/// leur somme ne serait plus l'effectif.
enum HrCategoryKey {
  teacher,
  administrative,
  support,
  unknown;

  static HrCategoryKey of(StaffCategory? category) => switch (category) {
    StaffCategory.teacher => HrCategoryKey.teacher,
    StaffCategory.administrative => HrCategoryKey.administrative,
    StaffCategory.support => HrCategoryKey.support,
    null => HrCategoryKey.unknown,
  };

  /// La catégorie du fichier, ou `null` pour [unknown].
  StaffCategory? get category => switch (this) {
    HrCategoryKey.teacher => StaffCategory.teacher,
    HrCategoryKey.administrative => StaffCategory.administrative,
    HrCategoryKey.support => StaffCategory.support,
    HrCategoryKey.unknown => null,
  };
}
