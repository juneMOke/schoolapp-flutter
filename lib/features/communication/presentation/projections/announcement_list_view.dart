import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';

/// Un groupe de la liste : un statut et ses communiqués, déjà triés.
typedef AnnouncementGroup = ({
  AnnouncementStatus status,
  List<Announcement> items,
});

/// Ce que la liste affiche, calculé une fois par état.
class AnnouncementListView {
  /// L'ordre des groupes : ce qui demande un geste d'abord.
  static const groupOrder = [
    AnnouncementStatus.failed,
    AnnouncementStatus.scheduled,
    AnnouncementStatus.draft,
    AnnouncementStatus.sent,
  ];

  final List<AnnouncementGroup> groups;
  final int shown;
  final int total;
  final Map<AnnouncementStatus, int> statusCounts;
  final Map<AnnouncementCategory, int> categoryCounts;

  /// Un seul statut coché : l'en-tête de groupe ne dirait rien de plus.
  final bool showHeaders;

  const AnnouncementListView._({
    required this.groups,
    required this.shown,
    required this.total,
    required this.statusCounts,
    required this.categoryCounts,
    required this.showHeaders,
  });

  factory AnnouncementListView.of(
    List<Announcement> all,
    AnnouncementFilters filters,
  ) {
    final visible = AnnouncementFiltering.apply(all, filters);
    final groups = <AnnouncementGroup>[
      for (final status in groupOrder)
        (
          status: status,
          items: _sorted(status, [
            for (final item in visible)
              if (item.status == status) item,
          ]),
        ),
    ].where((group) => group.items.isNotEmpty).toList(growable: false);
    return AnnouncementListView._(
      groups: groups,
      shown: visible.length,
      total: all.length,
      statusCounts: AnnouncementFiltering.statusCounts(all, filters),
      categoryCounts: AnnouncementFiltering.categoryCounts(all, filters),
      showHeaders: filters.statuses.length != 1,
    );
  }

  bool get isEmpty => shown == 0;

  /// Programmés : le prochain d'abord. Les autres : le plus récent d'abord.
  static List<Announcement> _sorted(
    AnnouncementStatus status,
    List<Announcement> items,
  ) {
    int byDate(Announcement a, Announcement b) {
      final da = a.referenceDate;
      final db = b.referenceDate;
      if (da == null || db == null) {
        return da == db ? 0 : (da == null ? 1 : -1);
      }
      return status == AnnouncementStatus.scheduled
          ? da.compareTo(db)
          : db.compareTo(da);
    }

    return items..sort(byDate);
  }
}
