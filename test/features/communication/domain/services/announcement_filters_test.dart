import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_status.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_filters.dart';

import '../../communication_fixtures.dart';

void main() {
  final all = [
    announcement(
      id: '1',
      title: 'Journée portes ouvertes',
      category: AnnouncementCategory.event,
      status: AnnouncementStatus.scheduled,
    ),
    announcement(
      id: '2',
      title: 'Fermeture exceptionnelle',
      category: AnnouncementCategory.urgent,
      status: AnnouncementStatus.sent,
    ),
    announcement(
      id: '3',
      title: 'Réunion',
      body: 'École fermée à 12 h',
      status: AnnouncementStatus.draft,
    ),
    announcement(
      id: '4',
      title: 'Rappel de paiement',
      category: AnnouncementCategory.administrative,
      status: AnnouncementStatus.sent,
    ),
  ];

  test('sans critère : tout', () {
    expect(AnnouncementFiltering.apply(all, const AnnouncementFilters()), all);
  });

  test('recherche titre + message, sans accents ni casse', () {
    final found = AnnouncementFiltering.apply(
      all,
      const AnnouncementFilters(query: 'ecole FERM'),
    );
    expect(found.map((a) => a.id), ['3']);
  });

  test('statuts et catégories : OU dans un groupe, ET entre groupes', () {
    final found = AnnouncementFiltering.apply(
      all,
      const AnnouncementFilters(
        statuses: {AnnouncementStatus.sent, AnnouncementStatus.draft},
        categories: {AnnouncementCategory.urgent, AnnouncementCategory.info},
      ),
    );
    expect(found.map((a) => a.id), ['2', '3']);
  });

  test('compteurs croisés : un statut ignore les autres statuts cochés', () {
    const filters = AnnouncementFilters(
      statuses: {AnnouncementStatus.sent},
      categories: {AnnouncementCategory.administrative},
    );
    expect(AnnouncementFiltering.statusCounts(all, filters), {
      AnnouncementStatus.sent: 1,
    });
    expect(AnnouncementFiltering.categoryCounts(all, filters), {
      AnnouncementCategory.urgent: 1,
      AnnouncementCategory.administrative: 1,
    });
  });

  test('« Effacer (n) » compte chaque critère', () {
    expect(
      const AnnouncementFilters(
        query: ' x',
        statuses: {AnnouncementStatus.sent},
        categories: {AnnouncementCategory.info, AnnouncementCategory.event},
      ).activeCount,
      4,
    );
  });
}
