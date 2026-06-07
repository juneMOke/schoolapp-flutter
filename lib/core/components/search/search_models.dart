import 'package:flutter/foundation.dart';

/// Briques de données de la recherche bi-mode (par nom OU par cycle/niveau).
///
/// Génériques (cœur design-system) : réutilisées par Facturation et
/// Réinscription, sans dépendance à une feature.

/// Option plate « cycle + niveau » proposée à la recherche.
@immutable
class SearchLevelOption {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;

  const SearchLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';
}

/// Critères émis par le formulaire au moment de la recherche.
@immutable
class SearchRequest {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const SearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });
}

/// Cycle dérivé d'un ensemble de [SearchLevelOption] partageant le même
/// [SearchLevelOption.schoolLevelGroupId].
@immutable
class SearchCycle {
  final String groupId;
  final String label;
  final List<SearchLevelOption> levels;

  const SearchCycle({
    required this.groupId,
    required this.label,
    required this.levels,
  });
}

/// Regroupe les options plates en cycles (par schoolLevelGroupId), en
/// préservant l'ordre d'apparition. Le libellé du cycle est dérivé du préfixe
/// du label (« cycle - niveau ») ; à défaut, le label complet est conservé.
List<SearchCycle> buildSearchCycles(List<SearchLevelOption> options) {
  final order = <String>[];
  final grouped = <String, List<SearchLevelOption>>{};

  for (final option in options) {
    grouped
        .putIfAbsent(option.schoolLevelGroupId, () {
          order.add(option.schoolLevelGroupId);
          return <SearchLevelOption>[];
        })
        .add(option);
  }

  return order
      .map((groupId) {
        final levels = grouped[groupId]!;
        final firstLabel = levels.first.label;
        final dashIndex = firstLabel.indexOf(' - ');
        final cycleLabel = dashIndex >= 0
            ? firstLabel.substring(0, dashIndex)
            : firstLabel;
        return SearchCycle(groupId: groupId, label: cycleLabel, levels: levels);
      })
      .toList(growable: false);
}

/// Libellé court d'un niveau (partie après le premier « - » du label complet).
String searchLevelShortLabel(SearchLevelOption option) {
  final dashIndex = option.label.indexOf(' - ');
  if (dashIndex < 0) return option.label;
  return option.label.substring(dashIndex + 3);
}
