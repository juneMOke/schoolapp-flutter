import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';

/// Les critères de la liste. Aucune sélection dans un groupe = aucun filtre
/// sur ce critère.
class AnnouncementFilters extends Equatable {
  final String query;
  final Set<AnnouncementStatus> statuses;
  final Set<AnnouncementCategory> categories;

  const AnnouncementFilters({
    this.query = '',
    this.statuses = const {},
    this.categories = const {},
  });

  /// Le nombre de critères posés, celui du bouton « Effacer (n) ».
  int get activeCount =>
      (query.trim().isEmpty ? 0 : 1) + statuses.length + categories.length;

  bool get isActive => activeCount > 0;

  AnnouncementFilters copyWith({
    String? query,
    Set<AnnouncementStatus>? statuses,
    Set<AnnouncementCategory>? categories,
  }) => AnnouncementFilters(
    query: query ?? this.query,
    statuses: statuses ?? this.statuses,
    categories: categories ?? this.categories,
  );

  @override
  List<Object?> get props => [query, statuses, categories];
}

/// Le filtrage de la liste, entièrement côté client (le lot de l'année).
abstract final class AnnouncementFiltering {
  static List<Announcement> apply(
    List<Announcement> all,
    AnnouncementFilters filters,
  ) => [
    for (final item in all)
      if (_matchesText(item, filters.query) &&
          _matchesStatus(item, filters.statuses) &&
          _matchesCategory(item, filters.categories))
        item,
  ];

  /// Compteur de chaque statut à **filtres croisés** : il tient compte de la
  /// recherche et des catégories, pas des autres statuts cochés.
  static Map<AnnouncementStatus, int> statusCounts(
    List<Announcement> all,
    AnnouncementFilters filters,
  ) {
    final counts = <AnnouncementStatus, int>{};
    for (final item in all) {
      if (!_matchesText(item, filters.query) ||
          !_matchesCategory(item, filters.categories)) {
        continue;
      }
      counts.update(item.status, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  /// Compteur de chaque catégorie, réciproque de [statusCounts].
  static Map<AnnouncementCategory, int> categoryCounts(
    List<Announcement> all,
    AnnouncementFilters filters,
  ) {
    final counts = <AnnouncementCategory, int>{};
    for (final item in all) {
      if (!_matchesText(item, filters.query) ||
          !_matchesStatus(item, filters.statuses)) {
        continue;
      }
      counts.update(item.content.category, (n) => n + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static bool _matchesText(Announcement item, String query) =>
      SearchNormalizationHelper.containsAllWords([
        item.content.title,
        item.content.body,
      ], query);

  static bool _matchesStatus(
    Announcement item,
    Set<AnnouncementStatus> statuses,
  ) => statuses.isEmpty || statuses.contains(item.status);

  static bool _matchesCategory(
    Announcement item,
    Set<AnnouncementCategory> categories,
  ) => categories.isEmpty || categories.contains(item.content.category);
}
