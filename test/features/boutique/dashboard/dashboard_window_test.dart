import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_period.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';

/// Les fenêtres glissantes du tableau de bord, lues dans le jour de l'école.
void main() {
  // Mardi 21 octobre 2026, 14 h 30 à Kinshasa (UTC+1).
  final now = DateTime.utc(2026, 10, 21, 13, 30);

  group('DashboardPeriod.windowAt', () {
    test('« 7 jours » finit aujourd\'hui, aujourd\'hui compris', () {
      final window = DashboardPeriod.sevenDays.windowAt(now);
      expect(window.from, DateTime(2026, 10, 15));
      expect(window.to, DateTime(2026, 10, 21));
      expect(window.dayCount, 7);
    });

    test('« Aujourd\'hui » est une seule journée', () {
      final window = DashboardPeriod.today.windowAt(now);
      expect(window.from, window.to);
      expect(window.isSingleDay, isTrue);
    });

    test('« 30 jours » traverse un changement de mois', () {
      final window = DashboardPeriod.thirtyDays.windowAt(now);
      expect(window.from, DateTime(2026, 9, 22));
      expect(window.dayCount, 30);
    });

    test('le jour est celui de KINSHASA, pas celui de la tablette', () {
      // 23 h 30 UTC le 20 = 0 h 30 le 21 à l'école.
      final window = DashboardPeriod.today.windowAt(
        DateTime.utc(2026, 10, 20, 23, 30),
      );
      expect(window.to, DateTime(2026, 10, 21));
    });

    test('une valeur mémorisée inconnue ne désigne rien', () {
      expect(
        DashboardPeriod.fromStorage('SEVEN_DAYS'),
        DashboardPeriod.sevenDays,
      );
      expect(DashboardPeriod.fromStorage('WEEK'), isNull);
      expect(DashboardPeriod.fromStorage(null), isNull);
    });
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
