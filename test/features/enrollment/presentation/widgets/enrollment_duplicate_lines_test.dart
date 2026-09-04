import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/enrollment_duplicate_lines.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

EnrollmentDuplicateCandidate _candidate({
  String studentId = 's1',
  String lastName = 'Mukendi',
  String firstName = 'Jean',
  String surname = 'Kabeya',
  String dateOfBirth = '2015-03-04',
  EnrollmentDuplicateSource source =
      EnrollmentDuplicateSource.currentYearDossier,
}) => EnrollmentDuplicateCandidate(
  studentId: studentId,
  source: source,
  level: EnrollmentDuplicateLevel.certain,
  identity: EnrollmentIdentity(
    lastName: lastName,
    firstName: firstName,
    surname: surname,
    dateOfBirth: dateOfBirth,
  ),
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  group('displayName', () {
    test('nom, post-nom, prénom — dans cet ordre', () {
      expect(
        EnrollmentDuplicateLines.displayName(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Kabeya',
          ),
        ),
        'Mukendi Kabeya Jean',
      );
    });

    test('un post-nom absent ne laisse pas de double espace', () {
      expect(
        EnrollmentDuplicateLines.displayName(
          const EnrollmentIdentity(lastName: 'Mukendi', firstName: 'Jean'),
        ),
        'Mukendi Jean',
      );
    });
  });

  group('displayDate', () {
    test('ISO nue → JJ/MM/AAAA', () {
      expect(EnrollmentDuplicateLines.displayDate('2015-03-04'), '04/03/2015');
    });

    test('ISO avec partie horaire → JJ/MM/AAAA, pas de résidu', () {
      // Un découpage naïf sur les tirets afficherait « 04T00:00:00.000Z/03/2015 ».
      expect(
        EnrollmentDuplicateLines.displayDate('2015-03-04T00:00:00.000Z'),
        '04/03/2015',
      );
    });

    test('date illisible → rendue telle quelle', () {
      expect(EnrollmentDuplicateLines.displayDate('04/03/2015'), '04/03/2015');
      expect(EnrollmentDuplicateLines.displayDate('inconnue'), 'inconnue');
    });

    test('date absente → chaîne vide', () {
      expect(EnrollmentDuplicateLines.displayDate(''), '');
      expect(EnrollmentDuplicateLines.displayDate('   '), '');
    });
  });

  group('identityOf', () {
    test('nomme et date', () {
      expect(
        EnrollmentDuplicateLines.identityOf(_candidate(), l10n),
        'Mukendi Kabeya Jean · né(e) le 04/03/2015',
      );
    });

    test('sans date, la mention « né(e) le » tombe entièrement', () {
      final line = EnrollmentDuplicateLines.identityOf(
        _candidate(dateOfBirth: ''),
        l10n,
      );

      expect(line, 'Mukendi Kabeya Jean');
      expect(line, isNot(contains('né(e)')));
    });
  });

  group('sourceOf', () {
    test('un dossier de l\'année se dit comme tel', () {
      expect(
        EnrollmentDuplicateLines.sourceOf(
          EnrollmentDuplicateSource.currentYearDossier,
          l10n,
        ),
        l10n.enrollmentDuplicateSourceCurrentYear,
      );
    });

    test('un candidat N-1 renvoie vers la Réinscription', () {
      final label = EnrollmentDuplicateLines.sourceOf(
        EnrollmentDuplicateSource.previousYearCohort,
        l10n,
      );

      expect(label, l10n.enrollmentDuplicateSourcePreviousYear);
      expect(label, contains('Réinscription'));
    });
  });

  group('named / othersCount', () {
    List<EnrollmentDuplicateCandidate> many(int count) => [
      for (var i = 0; i < count; i++) _candidate(studentId: 's$i'),
    ];

    test('trois ou moins : tous nommés, personne à compter', () {
      expect(EnrollmentDuplicateLines.named(many(3)), hasLength(3));
      expect(EnrollmentDuplicateLines.othersCount(many(3)), 0);
      expect(EnrollmentDuplicateLines.othersCount(many(1)), 0);
    });

    test('au-delà : trois nommés, le reste compté', () {
      expect(EnrollmentDuplicateLines.named(many(5)), hasLength(3));
      expect(EnrollmentDuplicateLines.othersCount(many(5)), 2);
    });

    test('l\'ordre de la sonde est conservé', () {
      final candidates = [
        _candidate(studentId: 'a'),
        _candidate(studentId: 'b'),
        _candidate(studentId: 'c'),
        _candidate(studentId: 'd'),
      ];

      expect([
        for (final c in EnrollmentDuplicateLines.named(candidates)) c.studentId,
      ], orderedEquals(const ['a', 'b', 'c']));
    });
  });
}
