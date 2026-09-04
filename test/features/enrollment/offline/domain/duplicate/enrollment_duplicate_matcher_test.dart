import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_matcher.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';

/// La saisie de référence de tous les cas : MUKENDI Kabeya Jean, né le
/// 4 mars 2015.
const _typed = EnrollmentIdentity(
  lastName: 'Mukendi',
  firstName: 'Jean',
  surname: 'Kabeya',
  dateOfBirth: '2015-03-04',
);

EnrollmentDuplicateLevel? _match(EnrollmentIdentity candidate) =>
    EnrollmentDuplicateMatcher(_typed).match(candidate);

void main() {
  group('certain — mêmes noms en position, même date', () {
    test('à l\'identique', () {
      expect(_match(_typed), EnrollmentDuplicateLevel.certain);
    });

    test('malgré la casse, les accents et le tiret', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'MUKÉNDI',
            firstName: 'jean',
            surname: 'Kabeya',
            dateOfBirth: '2015-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.certain,
      );
    });

    test('malgré une date descendue avec sa partie horaire', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Kabeya',
            dateOfBirth: '2015-03-04T00:00:00.000Z',
          ),
        ),
        EnrollmentDuplicateLevel.certain,
      );
    });
  });

  group('probable — mêmes noms à l\'ordre près, même date', () {
    test('nom et post-nom inversés — l\'erreur de guichet', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Kabeya',
            firstName: 'Jean',
            surname: 'Mukendi',
            dateOfBirth: '2015-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.probable,
      );
    });

    test('prénom porté comme nom', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Jean',
            firstName: 'Mukendi',
            surname: 'Kabeya',
            dateOfBirth: '2015-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.probable,
      );
    });

    test('dossier ancien sans post-nom, ses deux noms se retrouvent', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            dateOfBirth: '2015-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.probable,
      );
    });
  });

  group('possible — les noms correspondent, la date ne suit pas', () {
    test('noms exacts, année différente', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Kabeya',
            dateOfBirth: '2014-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.possible,
      );
    });

    test('noms exacts, jour et mois intervertis', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Kabeya',
            dateOfBirth: '2015-04-03',
          ),
        ),
        EnrollmentDuplicateLevel.possible,
      );
    });

    test('noms inversés, date différente', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Kabeya',
            firstName: 'Jean',
            surname: 'Mukendi',
            dateOfBirth: '2014-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.possible,
      );
    });

    test('date du candidat absente — elle ne confirme rien', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Kabeya',
          ),
        ),
        EnrollmentDuplicateLevel.possible,
      );
    });

    test('date du candidat illisible — elle ne confirme rien non plus', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Kabeya',
            dateOfBirth: '04/03/2015',
          ),
        ),
        EnrollmentDuplicateLevel.possible,
      );
    });

    test('deux dates illisibles ne valent pas égalité', () {
      const typedWithUnreadableDate = EnrollmentIdentity(
        lastName: 'Mukendi',
        firstName: 'Jean',
        surname: 'Kabeya',
        dateOfBirth: '04/03/2015',
      );
      expect(
        EnrollmentDuplicateMatcher(
          typedWithUnreadableDate,
        ).match(typedWithUnreadableDate),
        EnrollmentDuplicateLevel.possible,
      );
    });
  });

  group('aucun rapprochement', () {
    test('un jumeau ne remonte pas — son prénom n\'est pas dans la saisie', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Pierre',
            surname: 'Kabeya',
            dateOfBirth: '2015-03-04',
          ),
        ),
        isNull,
      );
    });

    test('un seul nom en commun ne suffit pas', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Alphonse',
            surname: 'Tshibangu',
            dateOfBirth: '2015-03-04',
          ),
        ),
        isNull,
      );
    });

    test('un candidat réduit à un seul nom ne rapproche de personne', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: '',
            dateOfBirth: '2015-03-04',
          ),
        ),
        isNull,
      );
    });

    test('aucun nom en commun', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Ilunga',
            firstName: 'Marie',
            surname: 'Tshibangu',
            dateOfBirth: '2015-03-04',
          ),
        ),
        isNull,
      );
    });
  });

  group('multiplicités — un nom répété exige un nom répété', () {
    test('le candidat porte deux fois un nom que la saisie n\'a qu\'une', () {
      expect(
        _match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Jean',
            surname: 'Mukendi',
            dateOfBirth: '2015-03-04',
          ),
        ),
        isNull,
      );
    });

    test('les deux côtés portent le nom deux fois', () {
      const typedTwice = EnrollmentIdentity(
        lastName: 'Mukendi',
        firstName: 'Jean',
        surname: 'Mukendi',
        dateOfBirth: '2015-03-04',
      );
      expect(
        EnrollmentDuplicateMatcher(typedTwice).match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: 'Mukendi',
            surname: 'Jean',
            dateOfBirth: '2015-03-04',
          ),
        ),
        EnrollmentDuplicateLevel.probable,
      );
    });
  });

  group('garde de saisie dégradée', () {
    test('une saisie à un seul nom ne rapproche de personne', () {
      final matcher = EnrollmentDuplicateMatcher(
        const EnrollmentIdentity(
          lastName: 'Mukendi',
          firstName: '',
          dateOfBirth: '2015-03-04',
        ),
      );

      expect(matcher.isUsable, isFalse);
      expect(matcher.match(_typed), isNull);
      expect(
        matcher.match(
          const EnrollmentIdentity(
            lastName: 'Mukendi',
            firstName: '',
            dateOfBirth: '2015-03-04',
          ),
        ),
        isNull,
      );
    });

    test('une saisie à deux noms reste exploitable', () {
      final matcher = EnrollmentDuplicateMatcher(
        const EnrollmentIdentity(
          lastName: 'Mukendi',
          firstName: 'Jean',
          dateOfBirth: '2015-03-04',
        ),
      );

      expect(matcher.isUsable, isTrue);
      // Le candidat porte un post-nom que la saisie n'a pas : il n'est pas
      // inclus dans elle. L'inclusion se lit dans ce sens-là, et pas l'autre.
      expect(matcher.match(_typed), isNull);
    });
  });

  group('classement', () {
    test('l\'ordre de l\'enum va du plus sûr au moins sûr', () {
      expect(
        EnrollmentDuplicateLevel.values,
        orderedEquals(const [
          EnrollmentDuplicateLevel.certain,
          EnrollmentDuplicateLevel.probable,
          EnrollmentDuplicateLevel.possible,
        ]),
      );
    });
  });
}
