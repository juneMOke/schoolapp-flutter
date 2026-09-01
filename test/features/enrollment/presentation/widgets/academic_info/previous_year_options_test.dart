import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/previous_year_options.dart';

/// Les années proposées au bloc « scolarité antérieure ».
///
/// Tout l'enjeu tient dans l'ancrage : l'année scolaire de l'école, jamais
/// l'horloge de la tablette. De janvier à août, `DateTime.now().year` désigne
/// le millésime de FIN de l'année en cours — la liste plaçait alors l'année
/// COURANTE en tête, c'est-à-dire à la place de l'année précédente.
void main() {
  group('build', () {
    test('remonte les trois années qui précèdent celle de l\'école', () {
      expect(PreviousYearOptions.build(currentAcademicYearName: '2026-2027'), [
        '2025-2026',
        '2024-2025',
        '2023-2024',
      ]);
    });

    test('ne propose jamais l\'année scolaire en cours', () {
      final options = PreviousYearOptions.build(
        currentAcademicYearName: '2026-2027',
      );
      expect(options, isNot(contains('2026-2027')));
    });

    /// Année inconnue ou libellé illisible : on retombe sur l'horloge plutôt
    /// que d'inventer un millésime — c'est le comportement historique, juste
    /// pendant la saison d'inscription (septembre → décembre).
    test('sans année de l\'école, se rabat sur l\'horloge', () {
      final currentYear = DateTime.now().year;
      expect(
        PreviousYearOptions.build().first,
        '${currentYear - 1}-$currentYear',
      );
      expect(
        PreviousYearOptions.build(
          currentAcademicYearName: 'Année scolaire',
        ).first,
        '${currentYear - 1}-$currentYear',
      );
    });
  });

  group('previousOf', () {
    test('est la première de la liste', () {
      expect(
        PreviousYearOptions.previousOf(currentAcademicYearName: '2030-2031'),
        '2029-2030',
      );
    });
  });

  group('resolve', () {
    final options = PreviousYearOptions.build(
      currentAcademicYearName: '2026-2027',
    );

    test('rend null quand le dossier ne dit rien', () {
      expect(PreviousYearOptions.resolve(null, options), isNull);
      expect(PreviousYearOptions.resolve('   ', options), isNull);
    });

    test('rapproche une écriture approchante de son entrée du catalogue', () {
      expect(PreviousYearOptions.resolve('2025 – 2026', options), '2025-2026');
    });

    /// Un libellé hors catalogue vient d'une vraie saisie : le remplacer par le
    /// premier élément serait une réponse inventée à sa place.
    test('conserve un libellé hors catalogue tel quel', () {
      expect(PreviousYearOptions.resolve('2012-2013', options), '2012-2013');
    });
  });
}
