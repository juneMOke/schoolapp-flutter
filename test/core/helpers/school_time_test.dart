import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';

/// Ce que ces tests tiennent : **l'instant écrit en base ne dépend pas du
/// réglage de la tablette**. Un même geste de guichet, posé depuis un poste en
/// UTC, en heure de Kinshasa ou à l'autre bout du monde, doit tomber dans la
/// même journée de caisse.
void main() {
  group('wallClock', () {
    test('lit l\'heure murale de Kinshasa, soit UTC+1', () {
      final wall = SchoolTime.wallClock(DateTime.utc(2026, 9, 16, 8, 30));

      expect(wall.hour, 9);
      expect(wall.day, 16);
    });

    test('normalise un instant local avant de décaler', () {
      final instant = DateTime.utc(2026, 9, 16, 8, 30).toLocal();

      expect(SchoolTime.wallClock(instant), DateTime.utc(2026, 9, 16, 9, 30));
    });
  });

  group('today', () {
    test('rend le jour de Kinshasa, pas celui d\'UTC', () {
      // 23 h 30 UTC = 00 h 30 le lendemain à Kinshasa.
      final day = SchoolTime.today(DateTime.utc(2026, 9, 16, 23, 30));

      expect(day, DateTime(2026, 9, 17));
    });

    test('ramène à minuit', () {
      final day = SchoolTime.today(DateTime.utc(2026, 9, 16, 8, 30));

      expect(day, DateTime(2026, 9, 16));
    });
  });

  group('oneYearBefore', () {
    test('recule d\'un an sur le même jour de calendrier', () {
      expect(
        SchoolTime.oneYearBefore(DateTime(2026, 9, 16)),
        DateTime(2025, 9, 16),
      );
    });
  });

  group('composeInstant', () {
    test('garde l\'heure du guichet sur le jour choisi', () {
      // Il est 14 h 30 à Kinshasa (13 h 30 UTC) ; le caissier date du 12.
      final instant = SchoolTime.composeInstant(
        day: DateTime(2026, 9, 12),
        now: DateTime.utc(2026, 9, 16, 13, 30),
      );

      expect(instant, DateTime.utc(2026, 9, 12, 13, 30));
      expect(instant.isUtc, isTrue);
      // Relu à Kinshasa, c'est bien le 12 à 14 h 30.
      expect(SchoolTime.wallClock(instant), DateTime.utc(2026, 9, 12, 14, 30));
    });

    test(
      'le jour choisi survit à un poste dont l\'horloge est en UTC tard le soir',
      () {
        // 23 h 30 UTC le 16 = 00 h 30 le 17 à Kinshasa. Le caissier encaisse
        // « aujourd'hui », c'est-à-dire le 17 pour l'école.
        final now = DateTime.utc(2026, 9, 16, 23, 30);
        final today = SchoolTime.today(now);

        final instant = SchoolTime.composeInstant(day: today, now: now);

        // La journée de caisse de l'école est bien le 17, et non le 16.
        expect(SchoolTime.wallClock(instant).day, 17);
      },
    );

    test('ne lit de [day] que ses champs de calendrier', () {
      final withNoise = DateTime(2026, 9, 12, 7, 45, 3);

      expect(
        SchoolTime.composeInstant(
          day: withNoise,
          now: DateTime.utc(2026, 9, 16, 13, 30),
        ),
        DateTime.utc(2026, 9, 12, 13, 30),
      );
    });

    test(
      'un versement daté d\'aujourd\'hui reproduit l\'horodatage courant',
      () {
        // Non-régression A1 : le cas par défaut doit rendre exactement l'instant
        // que produisait `DateTime.now().toUtc()`.
        final now = DateTime.utc(2026, 9, 16, 13, 30, 12, 340);

        final instant = SchoolTime.composeInstant(
          day: SchoolTime.today(now),
          now: now,
        );

        expect(instant, now);
      },
    );
  });
}
