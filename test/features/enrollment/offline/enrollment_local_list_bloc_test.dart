import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/states/enrollment_error_type.dart';

class _MockGetLocalEnrollments extends Mock
    implements GetLocalEnrollmentsUseCase {}

class _MockSearchLocalEnrollments extends Mock
    implements SearchLocalEnrollmentsUseCase {}

LocalEnrollmentListItem _item({
  required String enrollmentId,
  String? studentId,
  String firstName = 'Awa',
  String lastName = 'Ndiaye',
  String? surname,
  String dateOfBirth = '2012-05-01',
  OfflineEnrollmentStatus status = OfflineEnrollmentStatus.inProgress,
  EnrollmentType type = EnrollmentType.newEnrollment,
  SyncState syncState = SyncState.pendingSync,
}) => LocalEnrollmentListItem(
  enrollmentId: enrollmentId,
  studentId: studentId ?? 's-$enrollmentId',
  firstName: firstName,
  lastName: lastName,
  surname: surname,
  dateOfBirth: dateOfBirth,
  gender: OfflineGender.female,
  enrollmentType: type,
  status: status,
  matriculationNumber: null,
  enrollmentDate: '2025-09-01',
  syncState: syncState,
);

ReenrollmentCandidate _candidate({
  required String studentId,
  String firstName = 'Awa',
  String lastName = 'Ndiaye',
  String? surname,
  String dateOfBirth = '2012-05-01',
  String matriculationNumber = 'MAT-1',
}) => ReenrollmentCandidate(
  studentId: studentId,
  matriculationNumber: matriculationNumber,
  firstName: firstName,
  lastName: lastName,
  surname: surname,
  gender: 'FEMALE',
  dateOfBirth: dateOfBirth,
);

void main() {
  late _MockGetLocalEnrollments getLocal;
  late _MockSearchLocalEnrollments search;

  EnrollmentLocalListBloc build() =>
      EnrollmentLocalListBloc(getEnrollments: getLocal, search: search);

  setUp(() {
    getLocal = _MockGetLocalEnrollments();
    search = _MockSearchLocalEnrollments();
  });

  List<Object> ids(EnrollmentLocalListState s) =>
      s.summaries.map((e) => e.enrollmentId).toList();

  group('LocalListByStatusRequested', () {
    blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
      'émet loading puis success avec les résumés locaux mappés',
      setUp: () {
        when(() => getLocal(status: any(named: 'status'))).thenAnswer(
          (_) async =>
              Right([_item(enrollmentId: 'e1'), _item(enrollmentId: 'e2')]),
        );
      },
      build: build,
      act: (bloc) =>
          bloc.add(const LocalListByStatusRequested(status: 'IN_PROGRESS')),
      expect: () => [
        isA<EnrollmentLocalListState>().having(
          (s) => s.summariesStatus,
          'status',
          EnrollmentLoadStatus.loading,
        ),
        isA<EnrollmentLocalListState>()
            .having(
              (s) => s.summariesStatus,
              'status',
              EnrollmentLoadStatus.success,
            )
            .having(ids, 'ids', ['e1', 'e2'])
            .having((s) => s.summariesTotalElements, 'total', 2)
            .having(
              (s) => s.summariesQueryType,
              'type',
              EnrollmentSummaryQueryType.byStatus,
            ),
      ],
      verify: (_) => verify(() => getLocal(status: 'IN_PROGRESS')).called(1),
    );

    blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
      'échec local → failure avec type d’erreur générique serveur',
      setUp: () {
        when(
          () => getLocal(status: any(named: 'status')),
        ).thenAnswer((_) async => const Left(StorageFailure('boom')));
      },
      build: build,
      act: (bloc) =>
          bloc.add(const LocalListByStatusRequested(status: 'IN_PROGRESS')),
      expect: () => [
        isA<EnrollmentLocalListState>().having(
          (s) => s.summariesStatus,
          'status',
          EnrollmentLoadStatus.loading,
        ),
        isA<EnrollmentLocalListState>()
            .having(
              (s) => s.summariesStatus,
              'status',
              EnrollmentLoadStatus.failure,
            )
            .having(
              (s) => s.summariesErrorType,
              'errorType',
              EnrollmentErrorType.server,
            ),
      ],
    );
  });

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'byStatus transmet l’année scolaire au getEnrollments (parité online)',
    setUp: () {
      when(
        () => getLocal(
          status: any(named: 'status'),
          academicYearId: any(named: 'academicYearId'),
        ),
      ).thenAnswer((_) async => Right([_item(enrollmentId: 'e1')]));
    },
    build: build,
    act: (bloc) => bloc.add(
      const LocalListByStatusRequested(
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
      ),
    ),
    verify: (_) => verify(
      () => getLocal(status: 'IN_PROGRESS', academicYearId: 'ay-2026'),
    ).called(1),
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'byAcademicInfo (RE) : superpose vivier N-1 + dossiers locaux, dédup studentId',
    setUp: () {
      when(
        () => search.byCohort(
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer(
        (_) async => Right(
          ReenrollmentSearchResult(
            candidates: [
              _candidate(studentId: 'stu-A', firstName: 'Awa'),
              _candidate(studentId: 'stu-B', firstName: 'Bob'),
            ],
            // Dossier RE déjà démarré pour stu-A → prime le candidat (dédup).
            localDossiers: [
              _item(
                enrollmentId: 'dossierA',
                studentId: 'stu-A',
                firstName: 'Awa',
                type: EnrollmentType.reEnrollment,
                syncState: SyncState.draft,
              ),
            ],
          ),
        ),
      );
    },
    build: build,
    act: (bloc) => bloc.add(
      const LocalListByAcademicInfoRequested(
        firstName: '',
        lastName: '',
        surname: '',
        schoolLevelGroupId: 'grp-1',
        schoolLevelId: 'lvl-2',
      ),
    ),
    skip: 1,
    expect: () => [
      // stu-A via son dossier ('dossierA'), stu-B en candidat frais ('' = pas
      // encore de dossier). Ordre du vivier préservé.
      isA<EnrollmentLocalListState>().having(ids, 'ids', ['dossierA', '']),
    ],
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'recherche par nom : raffinement client-side sur la base par statut',
    setUp: () {
      when(() => getLocal(status: any(named: 'status'))).thenAnswer(
        (_) async => Right([
          _item(enrollmentId: 'e1', firstName: 'Awa', lastName: 'Ndiaye'),
          _item(enrollmentId: 'e2', firstName: 'Bob', lastName: 'Diop'),
        ]),
      );
    },
    build: build,
    act: (bloc) => bloc.add(
      const LocalListByStudentNameRequested(
        status: 'IN_PROGRESS',
        firstName: 'Awa',
        lastName: 'Ndiaye',
        surname: '',
      ),
    ),
    expect: () => [
      isA<EnrollmentLocalListState>(),
      isA<EnrollmentLocalListState>()
          .having(ids, 'ids', ['e1'])
          .having(
            (s) => s.summariesQueryType,
            'type',
            EnrollmentSummaryQueryType.byStudentName,
          ),
    ],
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'byAcademicInfo (RE) : appelle byCohort, jamais getEnrollments côté bloc',
    setUp: () {
      when(
        () => search.byCohort(
          schoolLevelId: any(named: 'schoolLevelId'),
          schoolLevelGroupId: any(named: 'schoolLevelGroupId'),
        ),
      ).thenAnswer(
        (_) async => Right(
          ReenrollmentSearchResult(
            candidates: [_candidate(studentId: 'stu-9')],
            localDossiers: const [],
          ),
        ),
      );
    },
    build: build,
    act: (bloc) => bloc.add(
      const LocalListByAcademicInfoRequested(
        firstName: '',
        lastName: '',
        surname: '',
        schoolLevelGroupId: 'grp-1',
        schoolLevelId: 'lvl-2',
      ),
    ),
    expect: () => [
      isA<EnrollmentLocalListState>(),
      isA<EnrollmentLocalListState>()
          .having(ids, 'ids', [''])
          .having(
            (s) => s.summariesQueryType,
            'type',
            EnrollmentSummaryQueryType.byAcademicInfo,
          ),
    ],
    verify: (_) {
      verify(
        () => search.byCohort(
          schoolLevelGroupId: 'grp-1',
          schoolLevelId: 'lvl-2',
        ),
      ).called(1);
      // Le bloc n'appelle pas `_getEnrollments` pour la RE : c'est le repo
      // (searchReenrollmentCohort) qui superpose les dossiers de l'année courante.
      verifyNever(() => getLocal(status: any(named: 'status')));
    },
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'pagination client-side : LocalListPageRequested change de page sans re-lire la base',
    setUp: () {
      when(() => getLocal(status: any(named: 'status'))).thenAnswer(
        (_) async =>
            Right(List.generate(5, (i) => _item(enrollmentId: 'e${i + 1}'))),
      );
    },
    build: build,
    act: (bloc) async {
      bloc.add(
        const LocalListByStatusRequested(status: 'IN_PROGRESS', size: 2),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LocalListPageRequested(page: 1));
    },
    skip: 2, // loading + success page 0
    expect: () => [
      isA<EnrollmentLocalListState>()
          .having(ids, 'ids', ['e3', 'e4'])
          .having((s) => s.summariesPage, 'page', 1)
          .having((s) => s.summariesTotalPages, 'totalPages', 3),
    ],
    verify: (_) =>
        verify(() => getLocal(status: any(named: 'status'))).called(1),
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'LocalListPageRequested(page négatif) sur résultat vide ne lève pas',
    setUp: () {
      when(
        () => getLocal(status: any(named: 'status')),
      ).thenAnswer((_) async => const Right(<LocalEnrollmentListItem>[]));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const LocalListByStatusRequested(status: 'IN_PROGRESS'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LocalListPageRequested(page: -1));
    },
    errors: () => <Object>[],
    verify: (bloc) {
      expect(bloc.state.summariesStatus, EnrollmentLoadStatus.success);
      expect(bloc.state.summaries, isEmpty);
      expect(bloc.state.summariesPage, 0);
    },
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'échec de chargement purge le cache (pas de données périmées repaginables)',
    setUp: () {
      final answers = <Either<Failure, List<LocalEnrollmentListItem>>>[
        Right([_item(enrollmentId: 'e1'), _item(enrollmentId: 'e2')]),
        const Left(StorageFailure('boom')),
      ];
      when(() => getLocal(status: any(named: 'status'))).thenAnswer((_) async {
        return answers.removeAt(0);
      });
    },
    build: build,
    act: (bloc) async {
      // Load A réussit (peuple le cache), Load B échoue.
      bloc.add(
        const LocalListByStatusRequested(status: 'IN_PROGRESS', size: 2),
      );
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LocalListByStatusRequested(status: 'COMPLETED', size: 2));
      await Future<void>.delayed(Duration.zero);
      // Une pagination après l'échec ne doit PAS ressortir la liste de A.
      bloc.add(const LocalListPageRequested(page: 0));
    },
    verify: (bloc) => expect(bloc.state.summaries, isEmpty),
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'LocalListResetRequested → retour à l’état initial',
    setUp: () {
      when(
        () => getLocal(status: any(named: 'status')),
      ).thenAnswer((_) async => Right([_item(enrollmentId: 'e1')]));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const LocalListByStatusRequested(status: 'IN_PROGRESS'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LocalListResetRequested());
    },
    skip: 2,
    expect: () => [const EnrollmentLocalListState.initial()],
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'LocalListRefreshRequested rejoue la dernière requête',
    setUp: () {
      when(
        () => getLocal(status: any(named: 'status')),
      ).thenAnswer((_) async => Right([_item(enrollmentId: 'e1')]));
    },
    build: build,
    act: (bloc) async {
      bloc.add(const LocalListByStatusRequested(status: 'IN_PROGRESS'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const LocalListRefreshRequested());
    },
    verify: (_) => verify(() => getLocal(status: 'IN_PROGRESS')).called(2),
  );

  blocTest<EnrollmentLocalListBloc, EnrollmentLocalListState>(
    'LocalListRefreshRequested sans requête antérieure ne fait rien',
    build: build,
    act: (bloc) => bloc.add(const LocalListRefreshRequested()),
    expect: () => const <EnrollmentLocalListState>[],
    verify: (_) => verifyNever(() => getLocal(status: any(named: 'status'))),
  );

  group('course de requêtes concurrentes (restartable)', () {
    test('un résultat périmé résolu en DERNIER ne repeint pas la liste', () async {
      // A (lente) puis B (rapide) : B doit gagner ; quand A se résout ensuite,
      // elle est périmée → ni cache ni emit (sinon la barre montrerait B mais la
      // liste afficherait A).
      final slowA = Completer<Either<Failure, List<LocalEnrollmentListItem>>>();
      when(() => getLocal(status: 'A')).thenAnswer((_) => slowA.future);
      when(
        () => getLocal(status: 'B'),
      ).thenAnswer((_) async => Right([_item(enrollmentId: 'b1')]));

      final bloc = build();
      bloc.add(const LocalListByStatusRequested(status: 'A'));
      bloc.add(const LocalListByStatusRequested(status: 'B'));
      await pumpEventQueue();
      expect(ids(bloc.state), [
        'b1',
      ], reason: 'la requête la plus récente gagne');

      // A se résout APRÈS B : résultat périmé → écarté.
      slowA.complete(Right([_item(enrollmentId: 'a1')]));
      await pumpEventQueue();
      expect(ids(bloc.state), [
        'b1',
      ], reason: 'le résultat périmé A est ignoré');

      await bloc.close();
    });
  });
}
