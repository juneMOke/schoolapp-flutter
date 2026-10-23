import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/school_time_label.dart';

/// Ce que ces tests tiennent : **une ligne se date à Kinshasa**, jamais à
/// l'heure du poste, et ne dit la date que lorsqu'elle apprend quelque chose.
void main() {
  // 10 h 00 à Kinshasa, le 23 octobre 2026.
  final now = DateTime.utc(2026, 10, 23, 9);

  test('aujourd\'hui : l\'heure seule, à l\'heure de l\'école', () {
    expect(
      SchoolTimeLabel.compact(DateTime.utc(2026, 10, 23, 13, 5), now),
      '14:05',
    );
  });

  test('un autre jour de l\'année : jour, mois et heure', () {
    expect(
      SchoolTimeLabel.compact(DateTime.utc(2026, 8, 30, 7, 41), now),
      '30/08 08:41',
    );
  });

  test('23 h 30 UTC tombe le lendemain à Kinshasa', () {
    // Le 22 à 23 h 30 UTC, c'est le 23 à 00 h 30 à l'école : aujourd'hui.
    expect(
      SchoolTimeLabel.compact(DateTime.utc(2026, 10, 22, 23, 30), now),
      '00:30',
    );
  });

  test('« aujourd\'hui » se juge aussi à Kinshasa', () {
    // 23 h 30 UTC le 22 : il est déjà le 23 à l'école, la vente de 22 h 00
    // UTC (23 h 00 à Kinshasa) est donc d'hier.
    expect(
      SchoolTimeLabel.compact(
        DateTime.utc(2026, 10, 22, 22),
        DateTime.utc(2026, 10, 22, 23, 30),
      ),
      '22/10 23:00',
    );
  });

  test('une autre année : l\'année s\'ajoute', () {
    expect(
      SchoolTimeLabel.compact(DateTime.utc(2025, 12, 30, 15), now),
      '30/12/2025 16:00',
    );
  });

  test('un instant local est normalisé avant lecture', () {
    final local = DateTime.utc(2026, 10, 23, 13, 5).toLocal();
    expect(SchoolTimeLabel.compact(local, now), '14:05');
  });
}
