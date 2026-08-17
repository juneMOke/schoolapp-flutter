import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:retrofit/retrofit.dart' show HttpResponse;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_models.dart';

import '../../offline_full_db.dart';

class MockEnrollmentPullApi extends Mock implements EnrollmentPullApi {}

void main() {
  late Database db;
  late MockEnrollmentPullApi api;
  late SyncMetaDao syncMeta;
  late List<FeeTariffLocalModel> capturedTariffs;
  late List<String> capturedYears;
  late EnrollmentPullRepositoryImpl repo;

  const auth = <String, dynamic>{'requiresAuth': true};
  const limit = EnrollmentPullRepositoryImpl.pageLimit;
  var clock = 10000;

  setUp(() async {
    db = await openFullOfflineDb();
    api = MockEnrollmentPullApi();
    syncMeta = SyncMetaDao(db);
    capturedTariffs = [];
    capturedYears = [];
    clock = 10000;
    repo = EnrollmentPullRepositoryImpl(
      api: api,
      referentialDao: EnrollmentReferentialDao(db),
      seedDao: EnrollmentSeedDao(db),
      reconciliationDao: EnrollmentReconciliationDao(db),
      replaceTariffs: (tariffs, academicYearIds) async {
        capturedTariffs.addAll(tariffs);
        capturedYears = academicYearIds;
      },
      syncMetaDao: syncMeta,
      requiredAuth: auth,
      currentUser: CurrentUserContext()..set('u1', schoolId: 'school-1'),
      now: () => clock,
    );
  });

  tearDown(() async {
    await db.close();
  });

  HttpResponse<T> httpOk<T>(T body) => HttpResponse(
    body,
    Response(requestOptions: RequestOptions(path: '/'), statusCode: 200),
  );

  DioException notModified304() => DioException(
    requestOptions: RequestOptions(path: '/'),
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: 304,
    ),
  );

  DioException network() => DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.connectionError,
  );

  // Enveloppe keyset (ADR-008/009). `hasMore` → `nextCursor` (progression) ;
  // sinon `nextWatermark` (fin de cycle).
  KeysetPageEnvelope env({
    String? nextCursor,
    String? nextWatermark,
    bool hasMore = false,
    String serverTime = '2026-07-08T10:00:01Z',
  }) => KeysetPageEnvelope(
    nextCursor: nextCursor,
    nextWatermark: nextWatermark,
    hasMore: hasMore,
    serverTime: serverTime,
  );

  /// [withheldTariffs] simule la portion retirée par le serveur (ADR-014 §4) :
  /// `feeTariffs: null`, à ne pas confondre avec `tariffs: const []` qui, lui,
  /// dit que l'école n'a réellement aucun tarif.
  ReferentialBundleDto bundle({
    List<RefFeeTariffDto>? tariffs,
    ReferentialYearBundleDto? previous,
    bool withheldTariffs = false,
  }) => ReferentialBundleDto(
    school: const RefSchoolDto(id: 'sch-1', name: 'Ecole Etoile'),
    current: ReferentialYearBundleDto(
      academicYear: const RefAcademicYearDto(
        id: 'ay-1',
        name: '2026',
        isCurrent: true,
      ),
      schoolLevelGroups: const [],
      schoolLevels: const [],
      feeTariffs: withheldTariffs
          ? null
          : tariffs ??
                const [
                  RefFeeTariffDto(
                    id: 'tar-1',
                    feeCode: 'INSCRIPTION',
                    schoolLevelGroupId: 'grp-1',
                    schoolLevelId: 'lvl-1',
                    amountInCents: 5000,
                    currency: 'USD',
                    academicYearId: 'ay-1',
                  ),
                ],
    ),
    previous: previous,
    serverTime: '2026-07-08T10:00:00Z',
  );

  ReenrollmentCandidateDto candidate({
    required String studentId,
    String matriculationNumber = 'KIN-2025-0001',
  }) => ReenrollmentCandidateDto(
    studentId: studentId,
    matriculationNumber: matriculationNumber,
    firstName: 'Amina',
    lastName: 'Moke',
    surname: 'Junior',
    gender: 'FEMALE',
    dateOfBirth: '2015-04-02',
    birthPlace: 'Kinshasa',
    previousBalanceInCents: 0,
  );

  ReenrollmentCohortPageDto cohortPage({
    required List<ReenrollmentCandidateDto> items,
    required bool bootstrapComplete,
    String? nextCursorId,
    String serverTime = '2026-07-08T10:00:00Z',
  }) => ReenrollmentCohortPageDto(
    items: items,
    nextCursorId: nextCursorId,
    bootstrapComplete: bootstrapComplete,
    serverTime: serverTime,
  );

  PreEnrollmentDto preItem({String updatedAt = '2026-07-08T09:30:00Z'}) =>
      PreEnrollmentDto(
        id: 'pre-1',
        firstName: 'Beni',
        lastName: 'Kabila',
        surname: 'Divin',
        updatedAt: updatedAt,
      );

  EnrollmentDeltaDto deltaItem({String id = 'e1', String status = 'ACTIVE'}) =>
      EnrollmentDeltaDto(
        id: id,
        studentId: 'stu-1',
        academicYearId: 'ay-1',
        status: status,
        updatedAt: '2026-07-08T10:00:00Z',
        serverUpdatedAt: '2026-07-08T10:00:01Z',
      );

  // ── Snapshot (pull hydratant) : fixtures d'agrégat complet ────────────────
  EnrollmentAggregateSnapshotDto aggregate({
    String enrollmentId = 'e-snap-1',
    String studentId = 'stu-snap-1',
    String status = 'IN_PROGRESS',
    String? updatedAt = '2026-07-08T09:00:00Z',
    String serverUpdatedAt = '2026-07-08T10:00:00Z',
    List<ParentSnapshotDto> parents = const [
      ParentSnapshotDto(
        id: 'par-snap-1',
        firstName: 'Joseph',
        lastName: 'Ilunga',
        phoneNumber: '+243900000001',
        relationshipType: 'FATHER',
      ),
    ],
  }) => EnrollmentAggregateSnapshotDto(
    enrollment: EnrollmentSnapshotDto(
      id: enrollmentId,
      studentId: studentId,
      academicYearId: 'ay-1',
      status: status,
      enrollmentType: 'NEW_ENROLLMENT',
      enrollmentCode: 'ETL-2026-0001',
      enrollmentDate: '2026-07-01',
      firstName: 'Grace',
      lastName: 'Ilunga',
      surname: 'Divine',
      dateOfBirth: '2015-05-05',
      gender: 'FEMALE',
      updatedAt: updatedAt,
    ),
    student: StudentSnapshotDto(
      id: studentId,
      matriculationNumber: 'KIN-2026-0001',
      firstName: 'Grace',
      lastName: 'Ilunga',
      surname: 'Divine',
      gender: 'FEMALE',
      dateOfBirth: '2015-05-05',
      email: 'grace@school.local',
    ),
    parents: parents,
    serverUpdatedAt: serverUpdatedAt,
  );

  EnrollmentSnapshotPageDto snapshotPage({
    List<EnrollmentAggregateSnapshotDto>? items,
    KeysetPageEnvelope? page,
  }) => EnrollmentSnapshotPageDto(
    items: items ?? [aggregate()],
    page: page ?? env(nextWatermark: 'WM-SNAP'),
  );

  group('syncReferential (bundle always-200)', () {
    test(
      '200 → upsert local + tarifs délégués + curseur = serverTime',
      () async {
        when(
          () => api.pullReferential(any()),
        ).thenAnswer((_) async => httpOk(bundle()));

        final result = await repo.syncReferential();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isFalse);
        expect(outcome.upserted, 3); // 1 école + 1 année + 1 tarif
        // Horloge SERVEUR (serverTime du bundle), pas l'horloge locale.
        expect(
          outcome.serverTimeMs,
          DateTime.parse('2026-07-08T10:00:00Z').millisecondsSinceEpoch,
        );
        expect(await db.query('ref_school'), hasLength(1));
        expect(await db.query('ref_academic_years'), hasLength(1));
        expect(capturedTariffs, hasLength(1));
        expect(capturedTariffs.single.label, 'INSCRIPTION'); // repli fee_code
        expect(capturedTariffs.single.amountInCents, 5000);
        expect(capturedYears, ['ay-1']); // purge scopée aux années du bundle
        // Curseur = serverTime du bundle, plus de query param académique.
        verify(() => api.pullReferential(auth)).called(1);
        expect(
          await syncMeta.getCursor(
            EnrollmentPullRepositoryImpl.referentialResource,
          ),
          '2026-07-08T10:00:00Z',
        );
        expect(
          await syncMeta.getSyncedAt(
            EnrollmentPullRepositoryImpl.referentialResource,
          ),
          10000,
        );
      },
    );

    test(
      'previous non-null → tarifs des deux années agrégés et années scopées',
      () async {
        when(() => api.pullReferential(any())).thenAnswer(
          (_) async => httpOk(
            bundle(
              previous: const ReferentialYearBundleDto(
                academicYear: RefAcademicYearDto(
                  id: 'ay-0',
                  name: '2025',
                  isCurrent: false,
                ),
                schoolLevelGroups: [],
                schoolLevels: [],
                feeTariffs: [
                  RefFeeTariffDto(
                    id: 'tar-0',
                    feeCode: 'INSCRIPTION',
                    schoolLevelGroupId: 'grp-0',
                    schoolLevelId: 'lvl-0',
                    amountInCents: 4500,
                    currency: 'USD',
                    academicYearId: 'ay-0',
                  ),
                ],
              ),
            ),
          ),
        );

        final result = await repo.syncReferential();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 5); // 1 école + 2 années + 2 tarifs
        expect(capturedTariffs, hasLength(2));
        expect(capturedYears, containsAll(['ay-1', 'ay-0']));
        expect(await db.query('ref_academic_years'), hasLength(2));
      },
    );

    // ADR-014 §4 — la grille tarifaire est retirée du bundle pour qui n'a pas
    // `finance.grid.read`. La purge scopée ne connaît que l'année, jamais le
    // compte : la déclencher sur une portion absente effacerait, sur une
    // tablette partagée, la grille dont dépend l'inscription hors ligne d'un
    // autre poste.
    test(
      'portion tarifaire retirée (null) → aucune purge, le reste s\'applique',
      () async {
        when(
          () => api.pullReferential(any()),
        ).thenAnswer((_) async => httpOk(bundle(withheldTariffs: true)));

        final result = await repo.syncReferential();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 2); // 1 école + 1 année, aucun tarif
        expect(capturedTariffs, isEmpty);
        // Le point qui compte : `replaceTariffs` n'est pas appelé du tout.
        expect(capturedYears, isEmpty);
        // École, années et niveaux s'appliquent normalement — l'amorçage de
        // l'application ne dépend pas de la portion réservée.
        expect(await db.query('ref_school'), hasLength(1));
        expect(await db.query('ref_academic_years'), hasLength(1));
      },
    );

    test(
      'portion présente mais vide ([]) → purge légitime de l\'année',
      () async {
        when(
          () => api.pullReferential(any()),
        ).thenAnswer((_) async => httpOk(bundle(tariffs: const [])));

        final result = await repo.syncReferential();

        expect(result.isRight(), isTrue);
        expect(capturedTariffs, isEmpty);
        // « Cette école n'a plus aucun tarif » est une information : les
        // lignes locales de l'année doivent disparaître.
        expect(capturedYears, ['ay-1']);
      },
    );

    test(
      'portion retirée sur `current` seulement → seule l\'année de `previous` '
      'est purgée',
      () async {
        when(() => api.pullReferential(any())).thenAnswer(
          (_) async => httpOk(
            bundle(
              withheldTariffs: true,
              previous: const ReferentialYearBundleDto(
                academicYear: RefAcademicYearDto(
                  id: 'ay-0',
                  name: '2025',
                  isCurrent: false,
                ),
                schoolLevelGroups: [],
                schoolLevels: [],
                feeTariffs: [
                  RefFeeTariffDto(
                    id: 'tar-0',
                    feeCode: 'INSCRIPTION',
                    schoolLevelGroupId: 'grp-0',
                    schoolLevelId: 'lvl-0',
                    amountInCents: 4500,
                    currency: 'USD',
                    academicYearId: 'ay-0',
                  ),
                ],
              ),
            ),
          ),
        );

        await repo.syncReferential();

        expect(capturedTariffs, hasLength(1));
        expect(capturedYears, ['ay-0']);
      },
    );

    test('curseur mémorisé n\'empêche pas le re-fetch (always-200)', () async {
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.referentialResource,
        cursor: '2026-07-01T00:00:00Z',
        syncedAt: 1,
      );
      when(
        () => api.pullReferential(any()),
      ).thenAnswer((_) async => httpOk(bundle()));

      await repo.syncReferential();

      // Toujours re-fetché (jamais de conditionnel), curseur avancé au serverTime.
      verify(() => api.pullReferential(auth)).called(1);
      expect(
        await syncMeta.getCursor(
          EnrollmentPullRepositoryImpl.referentialResource,
        ),
        '2026-07-08T10:00:00Z',
      );
    });

    test('erreur réseau → NetworkFailure', () async {
      when(() => api.pullReferential(any())).thenThrow(network());

      final result = await repo.syncReferential();

      expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
    });

    test('DioException portant une Failure (interceptor) → relayée telle '
        'quelle', () async {
      const failure = ServerFailure('Session expirée');
      when(() => api.pullReferential(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          error: failure,
        ),
      );

      final result = await repo.syncReferential();

      expect(result.fold((f) => f, (_) => null), same(failure));
    });

    test('échec du seam tarifs → Left(ServerFailure) et curseur NON '
        'avancé', () async {
      final failingRepo = EnrollmentPullRepositoryImpl(
        api: api,
        referentialDao: EnrollmentReferentialDao(db),
        seedDao: EnrollmentSeedDao(db),
        reconciliationDao: EnrollmentReconciliationDao(db),
        replaceTariffs: (_, _) async =>
            throw StateError('ref_fee_tariffs indisponible'),
        syncMetaDao: syncMeta,
        requiredAuth: auth,
        currentUser: CurrentUserContext()..set('u1', schoolId: 'school-1'),
        now: () => clock,
      );
      when(
        () => api.pullReferential(any()),
      ).thenAnswer((_) async => httpOk(bundle()));

      final result = await failingRepo.syncReferential();

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      expect(
        await syncMeta.getCursor(
          EnrollmentPullRepositoryImpl.referentialResource,
        ),
        isNull, // rejoué intégralement au prochain pull
      );
    });
  });

  group('syncReenrollmentCohort (statique, paginé par cursorId)', () {
    test(
      'page unique complète → snapshot remplacé + curseur serverTime',
      () async {
        when(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async => httpOk(
            cohortPage(
              items: [candidate(studentId: 'stu-1')],
              bootstrapComplete: true,
            ),
          ),
        );

        final result = await repo.syncReenrollmentCohort();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 1);
        expect(await db.query('ref_previous_year_students'), hasLength(1));
        expect(
          outcome.serverTimeMs,
          DateTime.parse('2026-07-08T10:00:00Z').millisecondsSinceEpoch,
        );
        expect(
          await syncMeta.getCursor(EnrollmentPullRepositoryImpl.cohortResource),
          '2026-07-08T10:00:00Z',
        );
        // 1re page : cursorId & previousAcademicYearId absents, limit envoyé.
        verify(
          () => api.pullReenrollmentCohort(auth, null, null, limit),
        ).called(1);
      },
    );

    test(
      'roster complet, année non résolue → skip via clé de repli non scopée',
      () async {
        // Aucune année courante en base (référentiel non pullé) → marqueur de repli
        // = clé non scopée [cohortResource]. Sa présence court-circuite le pull.
        await syncMeta.setCursor(
          EnrollmentPullRepositoryImpl.cohortResource,
          cursor: '2026-07-08T10:00:00Z',
          syncedAt: 1,
        );

        final result = await repo.syncReenrollmentCohort();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        // Aucun appel réseau : la cohorte figée n'est pas re-scannée.
        verifyNever(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        );
      },
    );

    test(
      'roster complet pour l\'année courante → skip (marqueur scopé saison)',
      () async {
        await db.insert('ref_academic_years', {
          'id': 'ay-1',
          'name': '2025-2026',
          'is_current': 1,
        });
        await syncMeta.setCursor(
          '${EnrollmentPullRepositoryImpl.cohortResource}:ay-1',
          cursor: '2026-07-08T10:00:00Z',
          syncedAt: 1,
        );

        final result = await repo.syncReenrollmentCohort();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        verifyNever(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        );
      },
    );

    test(
      'rollover d\'année : marqueur de l\'ancienne saison → re-pull + nouveau '
      'marqueur',
      () async {
        // Nouvelle saison active = ay-2, mais marqueur seulement pour ay-1.
        await db.insert('ref_academic_years', {
          'id': 'ay-2',
          'name': '2026-2027',
          'is_current': 1,
        });
        await syncMeta.setCursor(
          '${EnrollmentPullRepositoryImpl.cohortResource}:ay-1',
          cursor: '2025-07-08T10:00:00Z',
          syncedAt: 1,
        );
        when(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async => httpOk(
            cohortPage(
              items: [candidate(studentId: 'stu-new')],
              bootstrapComplete: true,
            ),
          ),
        );

        final result = await repo.syncReenrollmentCohort();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 1);
        // L'ancien marqueur ay-1 n'empêche pas le re-pull de la nouvelle saison…
        verify(
          () => api.pullReenrollmentCohort(auth, null, null, limit),
        ).called(1);
        // …et le nouveau roster est marqué sous ay-2.
        expect(
          await syncMeta.getCursor(
            '${EnrollmentPullRepositoryImpl.cohortResource}:ay-2',
          ),
          '2026-07-08T10:00:00Z',
        );
      },
    );

    test(
      'multi-pages : accumule jusqu\'à bootstrapComplete puis swap',
      () async {
        var call = 0;
        when(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        ).thenAnswer((_) async {
          call++;
          return call == 1
              ? httpOk(
                  cohortPage(
                    items: [candidate(studentId: 'stu-1')],
                    bootstrapComplete: false,
                    nextCursorId: 'stu-1',
                  ),
                )
              : httpOk(
                  cohortPage(
                    items: [candidate(studentId: 'stu-2')],
                    bootstrapComplete: true,
                  ),
                );
        });

        final result = await repo.syncReenrollmentCohort();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 2); // les 2 pages remplacées d'un bloc
        expect(await db.query('ref_previous_year_students'), hasLength(2));
        // 2e page tirée avec cursorId = studentId du dernier item de la page 1.
        final captured = verify(
          () => api.pullReenrollmentCohort(any(), captureAny(), any(), any()),
        ).captured;
        expect(captured, [null, 'stu-1']);
      },
    );

    test(
      'page vide COMPLÈTE après cohorte locale → wipe rapporté updated',
      () async {
        await db.insert('ref_previous_year_students', {
          'student_id': 'stu-radie',
          'matriculation_number': 'KIN-2025-0009',
          'first_name': 'Radié',
          'last_name': 'Moke',
          'gender': 'MALE',
          'date_of_birth': '2014-01-01',
          'previous_balance_in_cents': 0,
          'synced_at': 1,
        });
        when(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async =>
              httpOk(cohortPage(items: const [], bootstrapComplete: true)),
        );

        final result = await repo.syncReenrollmentCohort();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isFalse); // le wipe EST un changement local
        expect(outcome.upserted, 1);
        expect(await db.query('ref_previous_year_students'), isEmpty);
      },
    );

    test(
      'interruption réseau mi-roster → roster préservé, curseur NON avancé',
      () async {
        await db.insert('ref_previous_year_students', {
          'student_id': 'stu-existant',
          'matriculation_number': 'KIN-2024-0001',
          'first_name': 'Ancien',
          'last_name': 'Roster',
          'gender': 'MALE',
          'date_of_birth': '2013-01-01',
          'previous_balance_in_cents': 0,
          'synced_at': 1,
        });
        var call = 0;
        when(
          () => api.pullReenrollmentCohort(any(), any(), any(), any()),
        ).thenAnswer((_) async {
          call++;
          if (call == 1) {
            return httpOk(
              cohortPage(
                items: [candidate(studentId: 'stu-1')],
                bootstrapComplete: false,
                nextCursorId: 'stu-1',
              ),
            );
          }
          throw network();
        });

        final result = await repo.syncReenrollmentCohort();

        expect(result.fold((f) => f, (_) => null), isA<NetworkFailure>());
        // Jamais un demi-roster : l'ancien snapshot est intact, curseur non posé.
        final rows = await db.query('ref_previous_year_students');
        expect(rows, hasLength(1));
        expect(rows.single['student_id'], 'stu-existant');
        expect(
          await syncMeta.getCursor(EnrollmentPullRepositoryImpl.cohortResource),
          isNull,
        );
      },
    );

    test('serveur non-avançant (même nextCursorId, jamais complete) → arrêt '
        'sûr, roster jeté', () async {
      // Le serveur ré-émet le même cursorId sans jamais compléter : la garde
      // anti-boucle doit stopper (sinon `all` gonfle à l'infini en mémoire).
      when(
        () => api.pullReenrollmentCohort(any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          cohortPage(
            items: [candidate(studentId: 'stu-1')],
            bootstrapComplete: false,
            nextCursorId: 'stu-1',
          ),
        ),
      );

      final result = await repo.syncReenrollmentCohort().timeout(
        const Duration(seconds: 5),
      );

      // Pas de progrès → roster incomplet : jamais un demi-roster remplacé.
      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      expect(await db.query('ref_previous_year_students'), isEmpty);
      expect(
        await syncMeta.getCursor(EnrollmentPullRepositoryImpl.cohortResource),
        isNull,
      );
    });

    test('roster incomplet (contrat violé : ni complete ni nextCursorId) → '
        'ServerFailure sans remplacement', () async {
      when(
        () => api.pullReenrollmentCohort(any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          cohortPage(
            items: [candidate(studentId: 'stu-1')],
            bootstrapComplete: false,
            nextCursorId: null,
          ),
        ),
      );

      final result = await repo.syncReenrollmentCohort();

      expect(result.fold((f) => f, (_) => null), isA<ServerFailure>());
      expect(await db.query('ref_previous_year_students'), isEmpty);
      expect(
        await syncMeta.getCursor(EnrollmentPullRepositoryImpl.cohortResource),
        isNull,
      );
    });
  });

  group('syncPreEnrollments (keyset)', () {
    // Le curseur des préinscriptions vit sous une clé SCOPÉE PAR ÉCOLE — le
    // nom de ressource plat, lui, ne sert plus qu'à nommer le flux devant le
    // coordinateur. Le `repo` du `setUp` est monté sur `school-1`.
    final preKey = preEnrollmentsCursorKey('school-1');

    test('page terminale → upsert + curseur = nextWatermark', () async {
      await syncMeta.setCursor(preKey, cursor: 'CUR-PREV', syncedAt: 1);
      when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
        (_) async => httpOk(
          PreEnrollmentsPageDto(
            items: [preItem()],
            page: env(nextWatermark: 'WM-PRE'),
          ),
        ),
      );

      final result = await repo.syncPreEnrollments();

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.upserted, 1);
      // Horloge SERVEUR (page.serverTime), pas l'horloge locale.
      expect(
        outcome.serverTimeMs,
        DateTime.parse('2026-07-08T10:00:01Z').millisecondsSinceEpoch,
      );
      // Curseur mémorisé renvoyé verbatim en `cursor`.
      verify(() => api.pullPreEnrollments(auth, 'CUR-PREV', limit)).called(1);
      expect(await syncMeta.getCursor(preKey), 'WM-PRE');
    });

    test(
      'bootstrap (aucun curseur) → cursor null, jamais l\'horloge locale',
      () async {
        when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
          (_) async =>
              httpOk(PreEnrollmentsPageDto(items: const [], page: env())),
        );

        await repo.syncPreEnrollments();

        verify(() => api.pullPreEnrollments(auth, null, limit)).called(1);
      },
    );

    test(
      'page vide de fin (sans watermark) → notModified, curseur conservé',
      () async {
        await syncMeta.setCursor(preKey, cursor: 'CUR-KEEP', syncedAt: 1);
        when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
          (_) async =>
              httpOk(PreEnrollmentsPageDto(items: const [], page: env())),
        );

        final result = await repo.syncPreEnrollments();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        expect(
          await syncMeta.getCursor(preKey),
          'CUR-KEEP', // pas de watermark → curseur inchangé
        );
      },
    );

    test('updatedAt illisible → PAS de blocage : ligne appliquée (repli) et '
        'curseur AVANCE (anti poison-page, #21)', () async {
      // Régression : avant #21, un seul horodatage malformé levait FormatException
      // → Left(ServerFailure) → curseur figé → la MÊME page rejouée à l'infini,
      // ressource bloquée en silence. Désormais la page s'applique et avance.
      when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
        (_) async => httpOk(
          PreEnrollmentsPageDto(
            items: [preItem(updatedAt: 'pas-une-date')],
            page: env(nextWatermark: 'WM-PRE'),
          ),
        ),
      );

      final result = await repo.syncPreEnrollments();

      expect(result.isRight(), isTrue);
      expect(
        await syncMeta.getCursor(preKey),
        'WM-PRE', // curseur avancé : plus de rejeu infini de la page empoisonnée
      );
    });

    test('304 → notModified, curseur conservé', () async {
      await syncMeta.setCursor(preKey, cursor: 'CUR-304', syncedAt: 1);
      when(
        () => api.pullPreEnrollments(any(), any(), any()),
      ).thenThrow(notModified304());

      final result = await repo.syncPreEnrollments();

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isTrue);
      expect(outcome.serverTimeMs, isNull);
      expect(await syncMeta.getCursor(preKey), 'CUR-304');
    });
  });

  // ── Le scope école du curseur des préinscriptions ─────────────────────────
  //
  // LE CURSEUR NE FRANCHIT JAMAIS CE QUI N'A PAS ÉTÉ GARDÉ. La clé était plate
  // (`enrollment_pre_enrollments`) : sur une tablette réaffectée, le second
  // établissement héritait du curseur du premier, le serveur répondait « rien
  // de neuf », et ses propres préinscriptions ne descendaient JAMAIS.
  group('syncPreEnrollments — scope école du curseur', () {
    /// Un second repository, même base, mais monté sur une AUTRE école : c'est
    /// la tablette réaffectée.
    EnrollmentPullRepositoryImpl repoOfSchool(String schoolId) =>
        EnrollmentPullRepositoryImpl(
          api: api,
          referentialDao: EnrollmentReferentialDao(db),
          seedDao: EnrollmentSeedDao(db),
          reconciliationDao: EnrollmentReconciliationDao(db),
          replaceTariffs: (_, _) async {},
          syncMetaDao: syncMeta,
          requiredAuth: auth,
          currentUser: CurrentUserContext()..set('u2', schoolId: schoolId),
          now: () => clock,
        );

    test('la clé du curseur porte l\'école courante', () async {
      when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
        (_) async => httpOk(
          PreEnrollmentsPageDto(
            items: [preItem()],
            page: env(nextWatermark: 'WM-S1'),
          ),
        ),
      );

      await repo.syncPreEnrollments();

      expect(
        await syncMeta.getCursor(preEnrollmentsCursorKey('school-1')),
        'WM-S1',
      );
      // La clé plate héritée n'est plus jamais écrite.
      expect(
        await syncMeta.getCursor(
          EnrollmentPullRepositoryImpl.preEnrollmentsResource,
        ),
        isNull,
      );
    });

    test('la tablette réaffectée : la seconde école ne reprend pas le curseur '
        'de la première, elle bootstrape', () async {
      // Bout à bout, sans poser le curseur à la main : c'est le pull de
      // l'école 1 qui l'écrit, là où l'implémentation décide de l'écrire. Une
      // clé plate ferait donc bien hériter l'école 2 — ce test tomberait.
      when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
        (_) async => httpOk(
          PreEnrollmentsPageDto(
            items: [preItem()],
            page: env(nextWatermark: 'WM-S1'),
          ),
        ),
      );
      await repo.syncPreEnrollments(); // école 1, cycle complet
      clearInteractions(api);

      // La tablette est réaffectée : nouveau porteur, nouvelle école.
      when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
        (_) async =>
            httpOk(PreEnrollmentsPageDto(items: const [], page: env())),
      );
      await repoOfSchool('school-2').syncPreEnrollments();

      // Avant le scope : `WM-S1` repartait au serveur, qui répondait « rien de
      // neuf » — et l'école 2 ne voyait JAMAIS ses préinscriptions.
      verify(() => api.pullPreEnrollments(auth, null, limit)).called(1);
      // Le jeton de l'école 1 est intact : chaque école avance pour son compte.
      expect(
        await syncMeta.getCursor(preEnrollmentsCursorKey('school-1')),
        'WM-S1',
      );
    });

    test('le curseur hérité sous la clé plate n\'est jamais relu', () async {
      // Le parc migre avec cette ligne en base : elle doit être ignorée, pas
      // adoptée — rien ne dit à quelle école elle appartenait.
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.preEnrollmentsResource,
        cursor: 'WM-HERITE',
        syncedAt: 1,
      );
      when(() => api.pullPreEnrollments(any(), any(), any())).thenAnswer(
        (_) async =>
            httpOk(PreEnrollmentsPageDto(items: const [], page: env())),
      );

      await repo.syncPreEnrollments();

      // Rebootstrap assumé : c'est le seul comportement correct.
      verify(() => api.pullPreEnrollments(auth, null, limit)).called(1);
    });

    test(
      'aucune école courante → ni appel réseau ni écriture de curseur',
      () async {
        // `set` traite une chaîne vide comme absente : schoolId reste `null`.
        final result = await repoOfSchool('').syncPreEnrollments();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        expect(outcome.cursor, isNull);
        verifyNever(() => api.pullPreEnrollments(any(), any(), any()));
        // Surtout : aucune ligne `sync_meta`. Se rabattre sur la clé plate
        // rétablirait mot pour mot le défaut refermé ici.
        expect(await syncMeta.getCursor(preEnrollmentsCursorKey('')), isNull);
        expect(
          await syncMeta.getCursor(
            EnrollmentPullRepositoryImpl.preEnrollmentsResource,
          ),
          isNull,
        );
      },
    );
  });

  group('syncEnrollmentDelta (keyset, UPDATE-only)', () {
    setUp(() async {
      // PRÉCONDITION DU DELTA : la base a déjà été hydratée. Le curseur de
      // l'hydratant en est le témoin, et le delta refuse désormais de partir
      // sans lui — sans quoi il consommerait son backlog sur une base vide,
      // en silence (cf. le groupe « garde d'hydratation » plus bas).
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.snapshotsResource,
        cursor: 'WM-SNAP',
        syncedAt: 1000,
      );
      await db.insert('enrollments', {
        'id': 'e1',
        'student_id': 'stu-1',
        'enrollment_type': 'NEW_ENROLLMENT',
        'status': 'IN_PROGRESS',
        'academic_year_id': 'ay-1',
        'enrollment_date': '2026-07-01',
        'sync_status': 'SYNCED',
        'updated_at': 1000,
      });
    });

    test(
      'applique le delta sur une ligne SYNCED + curseur = watermark',
      () async {
        when(
          () => api.pullEnrollmentDelta(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async => httpOk(
            EnrollmentDeltaPageDto(
              items: [deltaItem()],
              page: env(nextWatermark: 'WM-DELTA'),
            ),
          ),
        );

        final result = await repo.syncEnrollmentDelta();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 1);
        expect(
          outcome.serverTimeMs,
          DateTime.parse('2026-07-08T10:00:01Z').millisecondsSinceEpoch,
        );
        final row = (await db.query('enrollments')).single;
        expect(row['status'], 'ACTIVE');
        expect(
          await syncMeta.getCursor(EnrollmentPullRepositoryImpl.deltaResource),
          'WM-DELTA',
        );
      },
    );

    test('delta sans effet local (id inconnu) → notModified', () async {
      when(
        () => api.pullEnrollmentDelta(any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          EnrollmentDeltaPageDto(
            items: [deltaItem(id: 'inconnu')],
            page: env(nextWatermark: 'WM-DELTA'),
          ),
        ),
      );

      final result = await repo.syncEnrollmentDelta();

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isTrue);
      // ADR-008 : le delta est consommé même sans effet local → curseur avancé.
      expect(
        await syncMeta.getCursor(EnrollmentPullRepositoryImpl.deltaResource),
        'WM-DELTA',
      );
    });

    test(
      'bootstrap (aucun curseur) → cursor null (jamais academicYearId)',
      () async {
        when(
          () => api.pullEnrollmentDelta(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async =>
              httpOk(EnrollmentDeltaPageDto(items: const [], page: env())),
        );

        await repo.syncEnrollmentDelta();

        verify(
          () => api.pullEnrollmentDelta(auth, null, null, limit),
        ).called(1);
      },
    );

    test('reprend depuis le curseur mémorisé', () async {
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.deltaResource,
        cursor: 'CUR-DELTA',
        syncedAt: 1,
      );
      when(
        () => api.pullEnrollmentDelta(any(), any(), any(), any()),
      ).thenAnswer(
        (_) async =>
            httpOk(EnrollmentDeltaPageDto(items: const [], page: env())),
      );

      await repo.syncEnrollmentDelta();

      verify(
        () => api.pullEnrollmentDelta(auth, 'CUR-DELTA', null, limit),
      ).called(1);
    });
  });

  // Le delta est maigre : il ne fait qu'UPDATE des lignes que seul l'hydratant
  // INSERT. Sur une base jamais hydratée il n'est donc pas seulement inutile —
  // il est DESTRUCTEUR : `_keysetPull` mémorise le jeton à chaque page sans
  // regarder `upserted`, donc le backlog serveur est consommé et le curseur
  // avancé au-delà de dossiers que plus rien ne redemandera. Et zéro ligne
  // appliquée est replié en `notModified`, exactement comme un cycle sain :
  // aucune erreur, aucun compteur, rien qui trahisse la perte.
  group('syncEnrollmentDelta — garde d\'hydratation', () {
    test('base jamais hydratée : aucun appel réseau', () async {
      final result = await repo.syncEnrollmentDelta();

      verifyNever(() => api.pullEnrollmentDelta(any(), any(), any(), any()));
      expect(result.isRight(), isTrue);
    });

    test('base jamais hydratée : le curseur du delta NE BOUGE PAS — c\'est '
        'l\'invariant du lot, tout le reste n\'est que confort', () async {
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.deltaResource,
        cursor: 'CUR-INTACT',
        syncedAt: 500,
      );

      await repo.syncEnrollmentDelta();

      expect(
        await syncMeta.getCursor(EnrollmentPullRepositoryImpl.deltaResource),
        'CUR-INTACT',
      );
      // Ni la fraîcheur : bumper `syncedAt` ferait lire « à jour » à une
      // ressource qu'on vient délibérément de ne pas demander.
      expect(
        await syncMeta.getSyncedAt(EnrollmentPullRepositoryImpl.deltaResource),
        500,
      );
    });

    test(
      'base jamais hydratée : rend notModified, jamais une erreur',
      () async {
        final result = await repo.syncEnrollmentDelta();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        expect(outcome.upserted, 0);
        // Pas d'échec : le cycle qui hydrate tourne dans la même passe, et
        // compter ceci en panne ferait virer la pastille de synchro au motif
        // d'une précondition qui se lèvera d'elle-même.
        expect(outcome.serverTimeMs, isNull);
      },
    );

    test(
      'CONTRE-ÉPREUVE — dès que l\'hydratant a posé son curseur, le delta part',
      () async {
        await syncMeta.setCursor(
          EnrollmentPullRepositoryImpl.snapshotsResource,
          cursor: 'WM-SNAP',
          syncedAt: 1000,
        );
        when(
          () => api.pullEnrollmentDelta(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async => httpOk(
            EnrollmentDeltaPageDto(
              items: const [],
              page: env(nextWatermark: 'WM-DELTA'),
            ),
          ),
        );

        await repo.syncEnrollmentDelta();

        verify(
          () => api.pullEnrollmentDelta(any(), any(), any(), any()),
        ).called(1);
      },
    );
  });

  group('syncEnrollmentSnapshots (keyset, hydratant)', () {
    test(
      'base vide → hydrate enrollment+student+parents SYNCED + watermark',
      () async {
        when(
          () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
        ).thenAnswer((_) async => httpOk(snapshotPage()));

        final result = await repo.syncEnrollmentSnapshots();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 1);
        expect(
          outcome.serverTimeMs,
          DateTime.parse('2026-07-08T10:00:01Z').millisecondsSinceEpoch,
        );
        final e = (await db.query('enrollments')).single;
        expect(e['id'], 'e-snap-1');
        expect(e['sync_status'], 'SYNCED');
        expect(e['enrollment_code'], 'ETL-2026-0001');
        final s = (await db.query('students')).single;
        expect(s['sync_status'], 'SYNCED');
        expect(s['matriculation_number'], 'KIN-2026-0001');
        expect(s['email'], 'grace@school.local');
        expect(await db.query('parents'), hasLength(1));
        final link = (await db.query('student_parent')).single;
        expect(link['relationship_type'], 'FATHER');
        expect(
          await syncMeta.getCursor(
            EnrollmentPullRepositoryImpl.snapshotsResource,
          ),
          'WM-SNAP',
        );
      },
    );

    test(
      'pagination multi-pages : suit nextCursor puis mémorise le watermark',
      () async {
        final agg1 = aggregate(enrollmentId: 'e-p1', studentId: 'stu-p1');
        final agg2 = aggregate(
          enrollmentId: 'e-p2',
          studentId: 'stu-p2',
          parents: const [],
        );
        var call = 0;
        when(
          () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
        ).thenAnswer((_) async {
          call++;
          return call == 1
              ? httpOk(
                  snapshotPage(
                    items: [agg1],
                    page: env(nextCursor: 'CUR-2', hasMore: true),
                  ),
                )
              : httpOk(
                  snapshotPage(
                    items: [agg2],
                    page: env(nextWatermark: 'WM-END'),
                  ),
                );
        });

        final result = await repo.syncEnrollmentSnapshots();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.upserted, 2); // les 2 pages appliquées
        expect(await db.query('enrollments'), hasLength(2));
        // Bootstrap (null) puis nextCursor de la page 1.
        final captured = verify(
          () => api.pullEnrollmentSnapshots(any(), captureAny(), any(), any()),
        ).captured;
        expect(captured, [null, 'CUR-2']);
        expect(
          await syncMeta.getCursor(
            EnrollmentPullRepositoryImpl.snapshotsResource,
          ),
          'WM-END', // watermark de fin de cycle
        );
      },
    );

    test(
      'interruption réseau mi-cycle : curseur de page mémorisé → reprise',
      () async {
        final agg1 = aggregate(enrollmentId: 'e-p1', studentId: 'stu-p1');
        final agg2 = aggregate(
          enrollmentId: 'e-p2',
          studentId: 'stu-p2',
          parents: const [],
        );

        // Run 1 : page 1 OK (hasMore), page 2 tombe en erreur réseau.
        var call = 0;
        when(
          () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
        ).thenAnswer((_) async {
          call++;
          if (call == 1) {
            return httpOk(
              snapshotPage(
                items: [agg1],
                page: env(nextCursor: 'CUR-2', hasMore: true),
              ),
            );
          }
          throw network();
        });

        final r1 = await repo.syncEnrollmentSnapshots();
        expect(r1.fold((f) => f, (_) => null), isA<NetworkFailure>());
        expect(await db.query('enrollments'), hasLength(1)); // page 1 appliquée
        // Curseur de progression mémorisé malgré l'échec → reprise possible.
        expect(
          await syncMeta.getCursor(
            EnrollmentPullRepositoryImpl.snapshotsResource,
          ),
          'CUR-2',
        );

        // Run 2 : reprend depuis 'CUR-2' et termine.
        when(
          () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
        ).thenAnswer(
          (_) async => httpOk(
            snapshotPage(
              items: [agg2],
              page: env(nextWatermark: 'WM-END'),
            ),
          ),
        );

        final r2 = await repo.syncEnrollmentSnapshots();
        expect(r2.isRight(), isTrue);
        expect(await db.query('enrollments'), hasLength(2));
        final captured = verify(
          () => api.pullEnrollmentSnapshots(any(), captureAny(), any(), any()),
        ).captured;
        // null (bootstrap) + CUR-2 (échec) + CUR-2 (reprise run 2).
        expect(captured, [null, 'CUR-2', 'CUR-2']);
        expect(
          await syncMeta.getCursor(
            EnrollmentPullRepositoryImpl.snapshotsResource,
          ),
          'WM-END',
        );
      },
    );

    test('n\'écrase pas une écriture locale non synchronisée (draft '
        'préservé, agrégat sauté)', () async {
      await db.insert('enrollments', {
        'id': 'e-snap-1',
        'student_id': 'stu-snap-1',
        'enrollment_type': 'NEW_ENROLLMENT',
        'status': 'DRAFTED',
        'academic_year_id': 'ay-1',
        'enrollment_date': '2026-07-01',
        'sync_status': 'DRAFT',
        'updated_at': 1,
      });
      when(
        () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
      ).thenAnswer((_) async => httpOk(snapshotPage()));

      final result = await repo.syncEnrollmentSnapshots();

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isTrue); // agrégat entièrement sauté
      final e = (await db.query('enrollments')).single;
      expect(e['sync_status'], 'DRAFT'); // préservé
      expect(e['status'], 'DRAFTED');
      expect(await db.query('students'), isEmpty); // rien d'autre écrit
      expect(await db.query('parents'), isEmpty);
    });

    test('rejeu idempotent de la même page → pas de doublon', () async {
      when(
        () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
      ).thenAnswer((_) async => httpOk(snapshotPage()));

      await repo.syncEnrollmentSnapshots();
      await repo.syncEnrollmentSnapshots();

      expect(await db.query('enrollments'), hasLength(1));
      expect(await db.query('students'), hasLength(1));
      expect(await db.query('parents'), hasLength(1));
      expect(await db.query('student_parent'), hasLength(1));
    });

    test(
      'snapshot plus ancien qu\'une ligne SYNCED locale → ignoré (LWW)',
      () async {
        await db.insert('enrollments', {
          'id': 'e-snap-1',
          'student_id': 'stu-snap-1',
          'enrollment_type': 'NEW_ENROLLMENT',
          'status': 'ACTIVE_RECENT',
          'academic_year_id': 'ay-1',
          'enrollment_date': '2026-07-01',
          'sync_status': 'SYNCED',
          'updated_at': 99999999999999, // très postérieur au snapshot
        });
        when(
          () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
        ).thenAnswer((_) async => httpOk(snapshotPage()));

        final result = await repo.syncEnrollmentSnapshots();

        final outcome = result.getOrElse(() => throw StateError('left'));
        expect(outcome.notModified, isTrue);
        final e = (await db.query('enrollments')).single;
        expect(
          e['status'],
          'ACTIVE_RECENT',
        ); // ligne locale plus récente conservée
      },
    );

    test('bootstrap (aucun curseur) → cursor null en requête', () async {
      when(
        () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(snapshotPage(items: const [], page: env())),
      );

      await repo.syncEnrollmentSnapshots();

      verify(
        () => api.pullEnrollmentSnapshots(auth, null, null, limit),
      ).called(1);
    });

    test('304 → notModified, curseur conservé', () async {
      await syncMeta.setCursor(
        EnrollmentPullRepositoryImpl.snapshotsResource,
        cursor: 'WM-304',
        syncedAt: 1,
      );
      when(
        () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
      ).thenThrow(notModified304());

      final result = await repo.syncEnrollmentSnapshots();

      final outcome = result.getOrElse(() => throw StateError('left'));
      expect(outcome.notModified, isTrue);
      expect(outcome.serverTimeMs, isNull);
      expect(
        await syncMeta.getCursor(
          EnrollmentPullRepositoryImpl.snapshotsResource,
        ),
        'WM-304',
      );
    });

    test('serveur non-avançant (hasMore + même nextCursor) → arrêt sûr', () async {
      // Le serveur renvoie toujours le même jeton avec hasMore=true : la garde
      // anti-boucle doit stopper le cycle au lieu de rejouer la page à l'infini.
      when(
        () => api.pullEnrollmentSnapshots(any(), any(), any(), any()),
      ).thenAnswer(
        (_) async => httpOk(
          snapshotPage(
            items: [aggregate()],
            page: env(nextCursor: 'STUCK', hasMore: true),
          ),
        ),
      );

      final result = await repo.syncEnrollmentSnapshots().timeout(
        const Duration(seconds: 5),
      );

      expect(result.isRight(), isTrue);
      expect(
        await syncMeta.getCursor(
          EnrollmentPullRepositoryImpl.snapshotsResource,
        ),
        'STUCK',
      );
    });
  });
}
