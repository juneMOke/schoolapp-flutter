import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_candidate.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_level.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_duplicate_source.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/enrollment_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/duplicate/known_student_identity.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_enrollment_duplicates_use_case.dart';

class MockEnrollmentOfflineRepository extends Mock
    implements EnrollmentOfflineRepository {}

/// La saisie du guichet dans tous les cas : MUKENDI Kabeya Jean, né le
/// 4 mars 2015.
const _typed = EnrollmentIdentity(
  lastName: 'Mukendi',
  firstName: 'Jean',
  surname: 'Kabeya',
  dateOfBirth: '2015-03-04',
);

KnownStudentIdentity _known({
  required String studentId,
  String? enrollmentId,
  EnrollmentDuplicateSource source =
      EnrollmentDuplicateSource.currentYearDossier,
  String lastName = 'Mukendi',
  String firstName = 'Jean',
  String surname = 'Kabeya',
  String dateOfBirth = '2015-03-04',
}) => KnownStudentIdentity(
  studentId: studentId,
  enrollmentId: enrollmentId,
  source: source,
  identity: EnrollmentIdentity(
    lastName: lastName,
    firstName: firstName,
    surname: surname,
    dateOfBirth: dateOfBirth,
  ),
);

void main() {
  late MockEnrollmentOfflineRepository repository;
  late ProbeEnrollmentDuplicatesUseCase probe;

  setUp(() {
    repository = MockEnrollmentOfflineRepository();
    probe = ProbeEnrollmentDuplicatesUseCase(repository);
  });

  void givenCorpus(List<KnownStudentIdentity> corpus) {
    when(
      () => repository.loadDuplicateProbeCorpus(
        studentId: any(named: 'studentId'),
        enrollmentId: any(named: 'enrollmentId'),
        academicYearId: any(named: 'academicYearId'),
      ),
    ).thenAnswer((_) async => Right(corpus));
  }

  Future<List<EnrollmentDuplicateCandidate>> run({
    EnrollmentIdentity typed = _typed,
    String? academicYearId,
  }) async {
    final result = await probe(
      typed: typed,
      studentId: 'self',
      enrollmentId: 'self-e',
      academicYearId: academicYearId,
    );
    return result.getOrElse(() => throw StateError('attendu Right'));
  }

  group('confrontation', () {
    test('retient les rapprochés et écarte les autres', () async {
      givenCorpus([
        _known(studentId: 's1', enrollmentId: 'e1'),
        _known(
          studentId: 's2',
          enrollmentId: 'e2',
          firstName: 'Alphonse',
          surname: 'Tshibangu',
        ),
      ]);

      final found = await run();

      expect(found, hasLength(1));
      expect(found.single.studentId, 's1');
      expect(found.single.enrollmentId, 'e1');
      expect(found.single.level, EnrollmentDuplicateLevel.certain);
    });

    test('rien trouvé rend une liste vide, pas une erreur', () async {
      givenCorpus([
        _known(studentId: 's2', firstName: 'Alphonse', surname: 'Tshibangu'),
      ]);

      expect(await run(), isEmpty);
    });

    test('corpus vide — la sonde se tait', () async {
      givenCorpus(const []);

      expect(await run(), isEmpty);
    });
  });

  group('classement', () {
    test('du plus sûr au moins sûr', () async {
      givenCorpus([
        // possible : noms exacts, date différente
        _known(studentId: 'possible', dateOfBirth: '2014-03-04'),
        // probable : nom et post-nom inversés, même date
        _known(studentId: 'probable', lastName: 'Kabeya', surname: 'Mukendi'),
        // certain
        _known(studentId: 'certain'),
      ]);

      final found = await run();

      expect([
        for (final c in found) c.studentId,
      ], orderedEquals(const ['certain', 'probable', 'possible']));
      expect(
        [for (final c in found) c.level],
        orderedEquals(const [
          EnrollmentDuplicateLevel.certain,
          EnrollmentDuplicateLevel.probable,
          EnrollmentDuplicateLevel.possible,
        ]),
      );
    });

    test('à niveau égal, l\'ordre alphabétique ignore les accents', () async {
      // Saisie accentuée : ses permutations portent l'accent en tête de nom.
      // « Élenga » se range APRÈS « Kabeya » en octets bruts (É = U+00C9) et
      // AVANT une fois la clé pliée. Sans accent dans le nom trié, le tri brut
      // et le tri sur clé donnent le même ordre, et le test ne prouve rien.
      const accentedTyped = EnrollmentIdentity(
        lastName: 'Élenga',
        firstName: 'Jean',
        surname: 'Kabeya',
        dateOfBirth: '2015-03-04',
      );
      givenCorpus([
        _known(
          studentId: 'kabeya',
          lastName: 'Kabeya',
          firstName: 'Jean',
          surname: 'Élenga',
        ),
        _known(
          studentId: 'elenga',
          lastName: 'Élenga',
          firstName: 'Kabeya',
          surname: 'Jean',
        ),
      ]);

      final found = await run(typed: accentedTyped);

      expect([
        for (final c in found) c.studentId,
      ], orderedEquals(const ['elenga', 'kabeya']));
    });
  });

  group('déduplication par élève', () {
    test('présent dans les deux sources, il ne se dit qu\'une fois', () async {
      givenCorpus([
        _known(
          studentId: 's1',
          source: EnrollmentDuplicateSource.previousYearCohort,
        ),
        _known(
          studentId: 's1',
          enrollmentId: 'e1',
          source: EnrollmentDuplicateSource.currentYearDossier,
        ),
      ]);

      final found = await run();

      expect(found, hasLength(1));
      expect(found.single.source, EnrollmentDuplicateSource.currentYearDossier);
      expect(found.single.enrollmentId, 'e1');
    });

    test('le dossier de l\'année prime même s\'il rapproche moins', () async {
      givenCorpus([
        // cohorte : rapprochement CERTAIN
        _known(
          studentId: 's1',
          source: EnrollmentDuplicateSource.previousYearCohort,
        ),
        // dossier de l'année : seulement POSSIBLE (date divergente)
        _known(
          studentId: 's1',
          enrollmentId: 'e1',
          source: EnrollmentDuplicateSource.currentYearDossier,
          dateOfBirth: '2014-03-04',
        ),
      ]);

      final found = await run();

      expect(found, hasLength(1));
      expect(found.single.source, EnrollmentDuplicateSource.currentYearDossier);
      expect(found.single.level, EnrollmentDuplicateLevel.possible);
    });

    test('à source égale, le rapprochement le plus fort gagne', () async {
      givenCorpus([
        _known(
          studentId: 's1',
          enrollmentId: 'faible',
          dateOfBirth: '2014-03-04',
        ),
        _known(studentId: 's1', enrollmentId: 'fort'),
      ]);

      final found = await run();

      expect(found, hasLength(1));
      expect(found.single.enrollmentId, 'fort');
      expect(found.single.level, EnrollmentDuplicateLevel.certain);
    });

    test(
      'l\'ordre du corpus ne décide pas : le dossier prime, même en tête',
      () async {
        // Le même couple qu'au-dessus, DANS L'AUTRE SENS. Sans ce miroir, « le
        // dernier lu gagne » passerait pour la règle et personne ne le verrait.
        givenCorpus([
          _known(
            studentId: 's1',
            enrollmentId: 'e1',
            source: EnrollmentDuplicateSource.currentYearDossier,
          ),
          _known(
            studentId: 's1',
            source: EnrollmentDuplicateSource.previousYearCohort,
          ),
        ]);

        final found = await run();

        expect(found, hasLength(1));
        expect(
          found.single.source,
          EnrollmentDuplicateSource.currentYearDossier,
        );
        expect(found.single.enrollmentId, 'e1');
      },
    );

    test('à source égale, le plus fort gagne même en tête', () async {
      givenCorpus([
        _known(studentId: 's1', enrollmentId: 'fort'),
        _known(
          studentId: 's1',
          enrollmentId: 'faible',
          dateOfBirth: '2014-03-04',
        ),
      ]);

      final found = await run();

      expect(found, hasLength(1));
      expect(found.single.enrollmentId, 'fort');
      expect(found.single.level, EnrollmentDuplicateLevel.certain);
    });

    test('deux élèves distincts restent deux lignes', () async {
      givenCorpus([
        _known(studentId: 's1', enrollmentId: 'e1'),
        _known(studentId: 's2', enrollmentId: 'e2'),
      ]);

      expect(await run(), hasLength(2));
    });
  });

  group('gardes', () {
    test('saisie inexploitable — aucune lecture n\'est même payée', () async {
      givenCorpus([_known(studentId: 's1')]);

      final found = await run(
        typed: const EnrollmentIdentity(
          lastName: 'Mukendi',
          firstName: '',
          dateOfBirth: '2015-03-04',
        ),
      );

      expect(found, isEmpty);
      verifyNever(
        () => repository.loadDuplicateProbeCorpus(
          studentId: any(named: 'studentId'),
          enrollmentId: any(named: 'enrollmentId'),
          academicYearId: any(named: 'academicYearId'),
        ),
      );
    });

    test(
      'un échec de lecture reste un Left — il ne se dit pas « vide »',
      () async {
        when(
          () => repository.loadDuplicateProbeCorpus(
            studentId: any(named: 'studentId'),
            enrollmentId: any(named: 'enrollmentId'),
            academicYearId: any(named: 'academicYearId'),
          ),
        ).thenAnswer((_) async => const Left(StorageFailure('base fermée')));

        final result = await probe(
          typed: _typed,
          studentId: 'self',
          enrollmentId: 'self-e',
        );

        expect(result.isLeft(), isTrue);
      },
    );

    test('les ids du brouillon et l\'année partent au corpus', () async {
      givenCorpus(const []);

      await probe(
        typed: _typed,
        studentId: 'self',
        enrollmentId: 'self-e',
        academicYearId: 'ay-2026',
      );

      verify(
        () => repository.loadDuplicateProbeCorpus(
          studentId: 'self',
          enrollmentId: 'self-e',
          academicYearId: 'ay-2026',
        ),
      ).called(1);
    });
  });
}
