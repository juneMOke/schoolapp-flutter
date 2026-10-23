import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Les fenêtres calendaires du tableau de bord, lues dans le jour de l'école.
void main() {
  // Mercredi 21 octobre 2026, 14 h 30 à Kinshasa (UTC+1).
  final now = DateTime.utc(2026, 10, 21, 13, 30);

  group('DashboardPeriod.windowAt', () {
    test('« Aujourd\'hui » est une seule journée', () {
      final window = DashboardPeriod.today.windowAt(now);
      expect(window.from, window.to);
      expect(window.isSingleDay, isTrue);
    });

    test('« Cette semaine » part du lundi, aujourd\'hui compris', () {
      final window = DashboardPeriod.week.windowAt(now);
      expect(window.from, DateTime(2026, 10, 19));
      expect(window.to, DateTime(2026, 10, 21));
      expect(window.dayCount, 3);
    });

    test('« Cette semaine » un lundi est une journée', () {
      final window = DashboardPeriod.week.windowAt(
        DateTime.utc(2026, 10, 19, 9),
      );
      expect(window.isSingleDay, isTrue);
    });

    test('« Cette semaine » remonte au mois précédent si le lundi y tombe', () {
      // Jeudi 1er octobre 2026 : le lundi est le 28 septembre.
      final window = DashboardPeriod.week.windowAt(
        DateTime.utc(2026, 10, 1, 9),
      );
      expect(window.from, DateTime(2026, 9, 28));
    });

    test('« Ce mois » part du 1er', () {
      final window = DashboardPeriod.month.windowAt(now);
      expect(window.from, DateTime(2026, 10));
      expect(window.dayCount, 21);
    });

    test('« Année » part de l\'ouverture de l\'année scolaire', () {
      final window = DashboardPeriod.year.windowAt(
        now,
        yearStart: DateTime(2026, 9, 1, 8),
      );
      expect(window.from, DateTime(2026, 9));
      expect(window.to, DateTime(2026, 10, 21));
    });

    test('« Année » sans ouverture connue : au plus large que le serveur '
        'accepte', () {
      final window = DashboardPeriod.year.windowAt(now);
      expect(window.dayCount, DashboardWindow.maxDayCount);
    });

    test('« Année » ne dépasse jamais 366 jours, ni ne part dans le futur', () {
      expect(
        DashboardPeriod.year
            .windowAt(now, yearStart: DateTime(2024, 9))
            .dayCount,
        DashboardWindow.maxDayCount,
      );
      expect(
        DashboardPeriod.year
            .windowAt(now, yearStart: DateTime(2026, 11, 2))
            .isSingleDay,
        isTrue,
      );
    });

    test('la période précise n\'a pas de fenêtre calculée', () {
      expect(() => DashboardPeriod.custom.windowAt(now), throwsStateError);
    });

    test('le jour est celui de KINSHASA, pas celui de la tablette', () {
      // 23 h 30 UTC le 20 = 0 h 30 le 21 à l'école.
      final window = DashboardPeriod.today.windowAt(
        DateTime.utc(2026, 10, 20, 23, 30),
      );
      expect(window.to, DateTime(2026, 10, 21));
    });

    test(
      'valeurs mémorisées : les anciennes fenêtres glissantes survivent',
      () {
        expect(DashboardPeriod.fromStorage('WEEK'), DashboardPeriod.week);
        expect(DashboardPeriod.fromStorage('YEAR'), DashboardPeriod.year);
        expect(DashboardPeriod.fromStorage('SEVEN_DAYS'), DashboardPeriod.week);
        expect(
          DashboardPeriod.fromStorage('THIRTY_DAYS'),
          DashboardPeriod.month,
        );
        expect(DashboardPeriod.custom.storageKey, isNull);
        expect(DashboardPeriod.fromStorage('CUSTOM'), isNull);
        expect(DashboardPeriod.fromStorage(null), isNull);
      },
    );
  });

  group('DashboardWindow', () {
    final window = DashboardWindow(
      from: DateTime(2026, 10, 15),
      to: DateTime(2026, 10, 21),
    );

    test('la fenêtre précédente a la même largeur, juste avant', () {
      expect(window.previousFrom, DateTime(2026, 10, 8));
    });

    test('bornes : minuit à Kinshasa, la fin exclue', () {
      expect(window.startInstant, DateTime.utc(2026, 10, 14, 23));
      expect(window.endInstantExclusive, DateTime.utc(2026, 10, 21, 23));
    });

    test('une vente de 23 h 30 à Kinshasa reste dans son jour', () {
      // 23 h 30 le 21 à l'école = 22 h 30 UTC.
      expect(
        window.containsInstant(DateTime.utc(2026, 10, 21, 22, 30)),
        isTrue,
      );
      // 0 h 10 le 22 à l'école = 23 h 10 UTC le 21 : hors fenêtre.
      expect(
        window.containsInstant(DateTime.utc(2026, 10, 21, 23, 10)),
        isFalse,
      );
      // 0 h 10 le 15 à l'école = 23 h 10 UTC le 14 : dedans.
      expect(
        window.containsInstant(DateTime.utc(2026, 10, 14, 23, 10)),
        isTrue,
      );
    });

    test('l\'heure passée au constructeur est oubliée', () {
      final w = DashboardWindow(
        from: DateTime(2026, 10, 15, 9),
        to: DateTime(2026, 10, 15, 18),
      );
      expect(w.isSingleDay, isTrue);
      expect(w.from, DateTime(2026, 10, 15));
    });
  });
}
