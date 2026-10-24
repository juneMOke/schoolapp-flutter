import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// Les critères de la liste tels que le serveur les lit.
abstract final class HrStaffDashboardWire {
  static String sort(HrRosterSort sort) => switch (sort) {
    HrRosterSort.name => 'NAME',
    HrRosterSort.nameDescending => 'NAME_DESC',
    HrRosterSort.oldest => 'OLDEST',
    HrRosterSort.newest => 'NEWEST',
  };

  /// `null` pour toutes les catégories — et pour [HrCategoryKey.unknown], que
  /// le serveur refuserait en 400 : il ne connaît pas de catégorie absente.
  static String? category(HrCategoryKey? key) => key?.category?.wire;

  /// Une recherche blanche ne part pas.
  static String? search(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Une catégorie que ce poste ne connaît pas (ajoutée sans release) se
  /// compte à part plutôt que de rendre la réponse illisible.
  static HrCategoryKey categoryOf(Object? wire) =>
      HrCategoryKey.of(StaffCategory.fromWire(wire as String?));
}
