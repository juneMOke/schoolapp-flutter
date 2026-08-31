import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/domain/academic_year_proposal.dart';

void main() {
  group('bascule du 1er juillet', () {
    test('en juin, on prépare encore l\'exercice commencé l\'an dernier', () {
      // Une école qui se paramètre le 30 juin 2026 ouvre l'année 2025-2026 :
      // celle qui court encore.
      expect(AcademicYearProposal.labelFor(DateTime(2026, 6, 30)), '2025-2026');
    });

    test('au 1er juillet, on bascule sur la rentrée qui vient', () {
      expect(AcademicYearProposal.labelFor(DateTime(2026, 7, 1)), '2026-2027');
    });

    test('en août, on prépare la rentrée de septembre', () {
      // Le cas nominal : c'est en août qu'une école se paramètre.
      expect(AcademicYearProposal.labelFor(DateTime(2026, 8, 28)), '2026-2027');
    });

    test('en décembre, l\'exercice en cours ne change pas de nom', () {
      expect(
        AcademicYearProposal.labelFor(DateTime(2026, 12, 15)),
        '2026-2027',
      );
    });

    test('en janvier, on reste sur le même exercice', () {
      // Le changement d'année civile ne fait pas changer d'année scolaire.
      expect(AcademicYearProposal.labelFor(DateTime(2027, 1, 5)), '2026-2027');
    });
  });

  group('dates proposées', () {
    final proposition = AcademicYearProposal.forDate(DateTime(2026, 8, 28));

    test('du 1er septembre au 30 juin', () {
      expect(proposition.startDate, DateTime.utc(2026, 9, 1));
      expect(proposition.endDate, DateTime.utc(2027, 6, 30));
    });

    test('les deux dates sont en UTC', () {
      // Le contrat l'impose, et les porter autrement décalerait le jour affiché
      // d'un fuseau à l'autre.
      expect(proposition.startDate.isUtc, isTrue);
      expect(proposition.endDate.isUtc, isTrue);
    });

    test('la proposition est courante par défaut', () {
      expect(proposition.current, isTrue);
    });

    test('l\'intervalle est valide', () {
      expect(proposition.hasValidRange, isTrue);
    });
  });

  group('pastille d\'origine', () {
    final today = DateTime(2026, 8, 28);

    test('intacte : proposée automatiquement', () {
      expect(
        AcademicYearProposal.isPristine(
          AcademicYearProposal.forDate(today),
          today,
        ),
        isTrue,
      );
    });

    test('une date touchée : modifiée', () {
      final touchee = AcademicYearProposal.forDate(
        today,
      ).copyWith(startDate: DateTime.utc(2026, 9, 15));
      expect(AcademicYearProposal.isPristine(touchee, today), isFalse);
    });

    test('un libellé touché : modifiée', () {
      final touchee = AcademicYearProposal.forDate(
        today,
      ).copyWith(name: '2026-2027 (bis)');
      expect(AcademicYearProposal.isPristine(touchee, today), isFalse);
    });
  });

  group('durée indicative', () {
    test('une année scolaire fait environ dix mois', () {
      expect(
        AcademicYearProposal.monthsBetween(
          DateTime.utc(2026, 9, 1),
          DateTime.utc(2027, 6, 30),
        ),
        10,
      );
    });

    test('un intervalle inversé ne rend pas un nombre négatif', () {
      // L'écran affiche alors son avertissement ; le compteur ne doit pas
      // ajouter un « ≈ -3 mois » qui ne veut rien dire.
      expect(
        AcademicYearProposal.monthsBetween(
          DateTime.utc(2027, 6, 30),
          DateTime.utc(2026, 9, 1),
        ),
        0,
      );
    });

    test('deux dates identiques valent zéro mois', () {
      final jour = DateTime.utc(2026, 9, 1);
      expect(AcademicYearProposal.monthsBetween(jour, jour), 0);
    });
  });
}
