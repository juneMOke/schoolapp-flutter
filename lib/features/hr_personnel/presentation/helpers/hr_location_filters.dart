import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';

/// Ce que l'adresse demande — chaque champ déjà ramené à une valeur valide.
class HrLocationFilters {
  final HrCategoryKey? category;
  final HrRosterSort sort;
  final CollectionViewMode viewMode;

  const HrLocationFilters({
    required this.category,
    required this.sort,
    required this.viewMode,
  });
}
