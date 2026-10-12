import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';
import 'package:school_app_flutter/features/communication/presentation/projections/announcement_list_view.dart';

import '../../communication_fixtures.dart';

void main() {
  final all = [
    announcement(
      id: 's-old',
      status: AnnouncementStatus.sent,
      sentAt: DateTime.utc(2026, 10, 1),
    ),
    announcement(
      id: 'p-late',
      status: AnnouncementStatus.scheduled,
      scheduledAt: DateTime.utc(2026, 10, 20),
    ),
    announcement(id: 'd', status: AnnouncementStatus.draft),
    announcement(
      id: 's-new',
      status: AnnouncementStatus.sent,
      sentAt: DateTime.utc(2026, 10, 9),
    ),
    announcement(
      id: 'p-soon',
      status: AnnouncementStatus.scheduled,
      scheduledAt: DateTime.utc(2026, 10, 13),
    ),
    announcement(id: 'f', status: AnnouncementStatus.failed),
  ];

  test(
    'groupes : échecs, programmés (le prochain d\'abord), brouillons, envoyés (récent d\'abord)',
    () {
      final view = AnnouncementListView.of(all, const AnnouncementFilters());
      expect([
        for (final g in view.groups) g.status,
      ], AnnouncementListView.groupOrder);
      expect(view.groups[1].items.map((a) => a.id), ['p-soon', 'p-late']);
      expect(view.groups[3].items.map((a) => a.id), ['s-new', 's-old']);
      expect(view.showHeaders, isTrue);
    },
  );

  test('un seul statut coché : pas d\'en-tête, et les comptes le disent', () {
    final view = AnnouncementListView.of(
      all,
      const AnnouncementFilters(statuses: {AnnouncementStatus.sent}),
    );
    expect(view.showHeaders, isFalse);
    expect(view.shown, 2);
    expect(view.total, 6);
    expect(view.groups.single.status, AnnouncementStatus.sent);
  });
}
