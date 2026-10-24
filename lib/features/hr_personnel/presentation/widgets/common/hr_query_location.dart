import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/navigation/location_params_sync.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_location_filters.dart';

export 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_location_filters.dart';

/// Les filtres d'une liste d'agents tenus dans l'adresse :
/// `?categorie=teacher&tri=oldest&vue=list`. F5 les retrouve sur le web,
/// Précédent revient aux filtres d'avant.
///
/// La recherche n'y va pas : chaque frappe serait une entrée d'historique.
/// Les valeurs par défaut (toutes catégories, tri par nom, cartes) laissent
/// l'adresse nue.
class HrQueryLocation extends StatelessWidget {
  static const categoryParam = 'categorie';
  static const sortParam = 'tri';
  static const viewParam = 'vue';

  final HrRosterQuery query;

  /// `null` : l'écran n'a pas de bascule cartes/liste.
  final CollectionViewMode? viewMode;
  final void Function(HrLocationFilters filters) onLocation;
  final Widget child;

  const HrQueryLocation({
    super.key,
    required this.query,
    this.viewMode,
    required this.onLocation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final view = viewMode;
    return LocationParamsSync(
      current: {
        categoryParam: query.category?.name,
        sortParam: query.sort == HrRosterSort.name ? null : query.sort.name,
        if (view != null)
          viewParam: view == CollectionViewMode.grid ? null : view.name,
      },
      onLocation: (values) => onLocation(
        HrLocationFilters(
          category: _byName(HrCategoryKey.values, values[categoryParam]),
          sort:
              _byName(HrRosterSort.values, values[sortParam]) ??
              HrRosterSort.name,
          viewMode:
              _byName(CollectionViewMode.values, values[viewParam]) ??
              CollectionViewMode.grid,
        ),
      ),
      child: child,
    );
  }

  /// Une valeur inconnue (lien tronqué, ancienne version) vaut le défaut.
  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      name == null ? null : values.where((v) => v.name == name).firstOrNull;
}
