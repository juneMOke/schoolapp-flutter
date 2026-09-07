import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';

/// La fenêtre est **valide par construction**.
///
/// Le serveur refuse trois combinaisons en 400 — `date` hors de `day`, `custom`
/// sans ses bornes, bornes inversées — et ces refus sont de bons refus. La
/// bonne réponse n'est pas de les afficher à l'utilisateur, c'est de ne pas
/// pouvoir composer la requête fautive. C'est ce que ces tests épinglent.
void main() {
  group('les paramètres du contrat', () {
    test('une journée pose `date`, et rien d\'autre', () {
      final window = EnrollmentStatsWindow.day(DateTime(2026, 9, 5));

      expect(window.apiPeriod, 'day');
      expect(window.apiDate, '2026-09-05');
      expect(window.apiFrom, isNull);
      expect(window.apiTo, isNull);
    });

    test('semaine, mois et année ne posent AUCUNE borne', () {
      // `date` avec une autre période que `day` est un 400 délibéré.
      for (final window in const [
        EnrollmentStatsWindow.week(),
        EnrollmentStatsWindow.month(),
        EnrollmentStatsWindow.year(),
      ]) {
        expect(window.apiDate, isNull, reason: window.apiPeriod);
        expect(window.apiFrom, isNull, reason: window.apiPeriod);
        expect(window.apiTo, isNull, reason: window.apiPeriod);
      }
    });

    test('une fenêtre libre pose ses DEUX bornes', () {
      // `custom` sans ses deux bornes est un 400 : pas de repli sur l'année.
      final window = EnrollmentStatsWindow.custom(
        from: DateTime(2026, 5, 18),
        to: DateTime(2026, 5, 24),
      );

      expect(window.apiPeriod, 'custom');
      expect(window.apiFrom, '2026-05-18');
      expect(window.apiTo, '2026-05-24');
      expect(window.apiDate, isNull);
    });

    test('les dates partent au format du contrat, zéros compris', () {
      expect(
        EnrollmentStatsWindow.day(DateTime(2026, 1, 7)).apiDate,
        '2026-01-07',
      );
    });

    test('des bornes inversées ne se construisent pas', () {
      // Le serveur ne les échange pas volontairement — « ce peut être un bug
      // de calcul côté client qu'il vaut mieux te faire voir ». Ici on ne le
      // laisse même pas partir.
      expect(
        () => EnrollmentStatsWindow.custom(
          from: DateTime(2026, 5, 24),
          to: DateTime(2026, 5, 18),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('l\'heure ne fait pas partie d\'une fenêtre', () {
    test(
      'deux fenêtres du même jour construites à deux instants sont égales',
      () {
        // Sans normalisation, le `buildWhen` du bloc rejouerait à chaque
        // reconstruction et `from == to` deviendrait faux pour une plage d'un
        // jour saisie à midi.
        final morning = EnrollmentStatsWindow.day(DateTime(2026, 9, 5, 8, 30));
        final evening = EnrollmentStatsWindow.day(DateTime(2026, 9, 5, 19, 45));

        expect(morning, evening);
      },
    );

    test('une plage d\'un jour saisie à midi reste une plage d\'un jour', () {
      final window = EnrollmentStatsWindow.custom(
        from: DateTime(2026, 9, 5, 9),
        to: DateTime(2026, 9, 5, 17),
      );

      expect(window.isSingleDay, isTrue);
      expect(window.singleDay, DateTime(2026, 9, 5));
    });
  });

  group('la fenêtre d\'un seul jour — ce qui ouvre la liste nominative', () {
    test('l\'onglet du jour en est une', () {
      expect(
        EnrollmentStatsWindow.day(DateTime(2026, 9, 5)).isSingleDay,
        isTrue,
      );
    });

    test('une plage dont les deux bornes tombent le même jour AUSSI', () {
      // La borne haute étant incluse, `from == to` cadre bien une journée.
      // C'est ce qui rend la règle vraie sur `custom` et pas seulement sur
      // l'onglet « Aujourd'hui ».
      final window = EnrollmentStatsWindow.custom(
        from: DateTime(2026, 9, 5),
        to: DateTime(2026, 9, 5),
      );

      expect(window.isSingleDay, isTrue);
      expect(window.singleDay, DateTime(2026, 9, 5));
    });

    test('une plage de deux jours n\'en est pas une', () {
      final window = EnrollmentStatsWindow.custom(
        from: DateTime(2026, 9, 5),
        to: DateTime(2026, 9, 6),
      );

      expect(window.isSingleDay, isFalse);
      expect(window.singleDay, isNull);
    });

    test('semaine, mois et année n\'en sont pas', () {
      for (final window in const [
        EnrollmentStatsWindow.week(),
        EnrollmentStatsWindow.month(),
        EnrollmentStatsWindow.year(),
      ]) {
        expect(window.isSingleDay, isFalse, reason: window.apiPeriod);
        expect(window.singleDay, isNull, reason: window.apiPeriod);
      }
    });
  });

  group('la plus large', () {
    test('c\'est l\'année, et elle seule', () {
      expect(const EnrollmentStatsWindow.year().isWidest, isTrue);
      expect(const EnrollmentStatsWindow.month().isWidest, isFalse);
      expect(const EnrollmentStatsWindow.week().isWidest, isFalse);
      expect(EnrollmentStatsWindow.day(DateTime(2026, 9, 5)).isWidest, isFalse);
    });

    test('une fenêtre libre ne compte pas comme la plus large', () {
      // Elle peut être n'importe quoi, y compris deux jours : proposer
      // « voir l'année entière » y garde donc tout son sens.
      final window = EnrollmentStatsWindow.custom(
        from: DateTime(2026, 1, 1),
        to: DateTime(2026, 12, 31),
      );

      expect(window.isWidest, isFalse);
    });
  });
}
