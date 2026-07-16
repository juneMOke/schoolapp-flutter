import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ref_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_models.dart';

import '../../offline_full_db.dart';

void main() {
  late Database db;
  late EnrollmentRefDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = EnrollmentRefDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  ReferentialBundleDto bundle({
    List<RefAcademicYearDto>? years,
    List<RefSchoolLevelGroupDto>? groups,
    List<RefSchoolLevelDto>? levels,
  }) => ReferentialBundleDto(
    academicYears:
        years ??
        const [RefAcademicYearDto(id: 'ay-1', name: '2026', isCurrent: true)],
    schoolLevelGroups:
        groups ??
        const [
          RefSchoolLevelGroupDto(
            id: 'grp-1',
            name: 'Primaire',
            code: 'PRIM',
            academicYearId: 'ay-1',
            displayOrder: 1,
          ),
        ],
    schoolLevels:
        levels ??
        const [
          RefSchoolLevelDto(
            id: 'lvl-1',
            name: '1ère Primaire',
            code: 'P1',
            levelGroupId: 'grp-1',
            displayOrder: 1,
            splitIntoClassrooms: true,
          ),
        ],
    feeTariffs: const [],
    serverTime: '2026-07-08T10:00:00Z',
  );

  ReenrollmentCandidateDto candidate({
    String studentId = 'stu-1',
    String? previousSchoolLevelId = 'lvl-0',
  }) => ReenrollmentCandidateDto(
    studentId: studentId,
    matriculationNumber: 'KIN-2025-0001',
    firstName: 'Amina',
    lastName: 'Moke',
    surname: 'Junior',
    gender: 'FEMALE',
    dateOfBirth: '2015-04-02',
    birthPlace: 'Kinshasa',
    previousSchoolLevelId: previousSchoolLevelId,
    previousBalanceInCents: 12500,
    currency: 'USD',
  );

  PreEnrollmentDto preEnrollment({
    String id = 'pre-1',
    String updatedAt = '2026-07-08T09:30:00Z',
    String firstName = 'Beni',
  }) => PreEnrollmentDto(
    id: id,
    firstName: firstName,
    lastName: 'Kabila',
    surname: 'Divin',
    guardianPhone: '+243900000001',
    updatedAt: updatedAt,
  );

  /// Sème une inscription locale minimale (colonnes NOT NULL) pour le delta.
  Future<void> seedEnrollment({
    String id = 'e1',
    String syncStatus = 'SYNCED',
    int updatedAt = 1000,
    String status = 'IN_PROGRESS',
    String? schoolLevelId = 'lvl-1',
    String? schoolLevelGroupId = 'grp-1',
  }) => db.insert('enrollments', {
    'id': id,
    'student_id': 'stu-1',
    'enrollment_type': 'NEW_ENROLLMENT',
    'status': status,
    'academic_year_id': 'ay-1',
    'school_level_id': schoolLevelId,
    'school_level_group_id': schoolLevelGroupId,
    'enrollment_date': '2026-07-01',
    'sync_status': syncStatus,
    'updated_at': updatedAt,
  });

  /// Sème l'élève du dossier (pour la répercussion du matricule).
  Future<void> seedStudent({String id = 'stu-1', String? matricule}) =>
      db.insert('students', {
        'id': id,
        'first_name': 'Amina',
        'last_name': 'Moke',
        'gender': 'FEMALE',
        'date_of_birth': '2015-04-02',
        'matriculation_number': matricule,
        'sync_status': 'SYNCED',
        'updated_at': 100,
      });

  EnrollmentDeltaDto delta({
    String id = 'e1',
    String status = 'ACTIVE',
    String? schoolLevelId = 'lvl-2',
    String updatedAt = '2026-07-08T10:00:00Z',
  }) => EnrollmentDeltaDto(
    id: id,
    studentId: 'stu-1',
    schoolLevelId: schoolLevelId,
    academicYearId: 'ay-1',
    status: status,
    updatedAt: updatedAt,
    serverUpdatedAt: updatedAt,
  );

  group('upsertReferential', () {
    test('insère années/cycles/niveaux et renvoie le compte', () async {
      final count = await dao.upsertReferential(bundle(), syncedAt: 500);

      expect(count, 3);
      final year = (await db.query('ref_academic_years')).single;
      expect(year['name'], '2026');
      expect(year['is_current'], 1);
      expect(year['synced_at'], 500);
      final group = (await db.query('ref_school_level_groups')).single;
      expect(group['code'], 'PRIM');
      final level = (await db.query('ref_school_levels')).single;
      expect(level['split_into_classrooms'], 1);
      expect(level['level_group_id'], 'grp-1');
    });

    test('est idempotent — rejouer remplace sans dupliquer', () async {
      await dao.upsertReferential(bundle(), syncedAt: 500);
      await dao.upsertReferential(
        bundle(
          years: const [
            RefAcademicYearDto(id: 'ay-1', name: '2026-2027', isCurrent: true),
          ],
        ),
        syncedAt: 600,
      );

      final rows = await db.query('ref_academic_years');
      expect(rows, hasLength(1));
      expect(rows.single['name'], '2026-2027');
      expect(rows.single['synced_at'], 600);
    });

    test('remet is_current à zéro : jamais deux années courantes', () async {
      await dao.upsertReferential(bundle(), syncedAt: 500);
      await dao.upsertReferential(
        bundle(
          years: const [
            RefAcademicYearDto(id: 'ay-2', name: '2027', isCurrent: true),
          ],
        ),
        syncedAt: 600,
      );

      final current = await db.query(
        'ref_academic_years',
        where: 'is_current = 1',
      );
      expect(current, hasLength(1));
      expect(current.single['id'], 'ay-2');
    });

    test(
      'un bundle sans années ne touche ni is_current ni les tables',
      () async {
        await dao.upsertReferential(bundle(), syncedAt: 500);
        final count = await dao.upsertReferential(
          bundle(years: const [], groups: const [], levels: const []),
          syncedAt: 600,
        );

        expect(count, 0);
        final year = (await db.query('ref_academic_years')).single;
        expect(year['is_current'], 1);
        expect(await db.query('ref_school_levels'), hasLength(1));
      },
    );

    test('purge les cycles/niveaux disparus du snapshot (scopé année)', () async {
      await dao.upsertReferential(
        bundle(
          groups: const [
            RefSchoolLevelGroupDto(
              id: 'grp-1',
              name: 'Primaire',
              code: 'PRIM',
              academicYearId: 'ay-1',
              displayOrder: 1,
            ),
            RefSchoolLevelGroupDto(
              id: 'grp-2',
              name: 'Secondaire',
              code: 'SEC',
              academicYearId: 'ay-1',
              displayOrder: 2,
            ),
          ],
          levels: const [
            RefSchoolLevelDto(
              id: 'lvl-1',
              name: '1ère Primaire',
              code: 'P1',
              levelGroupId: 'grp-1',
              displayOrder: 1,
              splitIntoClassrooms: true,
            ),
            RefSchoolLevelDto(
              id: 'lvl-2',
              name: '7ème Secondaire',
              code: 'S7',
              levelGroupId: 'grp-2',
              displayOrder: 1,
              splitIntoClassrooms: false,
            ),
          ],
        ),
        syncedAt: 500,
      );

      // Nouveau snapshot de la même année SANS grp-2/lvl-2 (supprimés serveur).
      await dao.upsertReferential(bundle(), syncedAt: 600);

      expect((await db.query('ref_school_level_groups')).map((r) => r['id']), [
        'grp-1',
      ]);
      expect((await db.query('ref_school_levels')).map((r) => r['id']), [
        'lvl-1',
      ]);
    });

    test('la purge ne sort pas du périmètre : l\'année N-1 survit', () async {
      // Référentiel N-1 hors bundle (année, cycle, niveau).
      await db.insert('ref_academic_years', {
        'id': 'ay-0',
        'name': '2025',
        'is_current': 0,
        'synced_at': 1,
      });
      await db.insert('ref_school_level_groups', {
        'id': 'grp-0',
        'name': 'Primaire 2025',
        'code': 'PRIM',
        'academic_year_id': 'ay-0',
        'display_order': 1,
        'synced_at': 1,
      });
      await db.insert('ref_school_levels', {
        'id': 'lvl-0',
        'name': '1ère Primaire 2025',
        'code': 'P1',
        'level_group_id': 'grp-0',
        'display_order': 1,
        'split_into_classrooms': 0,
        'synced_at': 1,
      });

      await dao.upsertReferential(bundle(), syncedAt: 600);

      expect(await db.query('ref_academic_years'), hasLength(2));
      expect(
        await db.query(
          'ref_school_level_groups',
          where: 'id = ?',
          whereArgs: ['grp-0'],
        ),
        hasLength(1),
      );
      expect(
        await db.query(
          'ref_school_levels',
          where: 'id = ?',
          whereArgs: ['lvl-0'],
        ),
        hasLength(1),
      );
    });
  });

  group('replaceReenrollmentCohort', () {
    test(
      'remplace intégralement le snapshot (les radiés disparaissent)',
      () async {
        await dao.replaceReenrollmentCohort([
          candidate(studentId: 'stu-1'),
          candidate(studentId: 'stu-2'),
        ], syncedAt: 500);
        final count = await dao.replaceReenrollmentCohort([
          candidate(studentId: 'stu-2'),
        ], syncedAt: 600);

        expect(count, 1);
        final rows = await db.query('ref_previous_year_students');
        expect(rows, hasLength(1));
        expect(rows.single['student_id'], 'stu-2');
        expect(rows.single['previous_balance_in_cents'], 12500);
        expect(rows.single['matriculation_number'], 'KIN-2025-0001');
        expect(rows.single['synced_at'], 600);
      },
    );

    test(
      'un snapshot vide VIDE la table et compte les lignes purgées',
      () async {
        await dao.replaceReenrollmentCohort([
          candidate(studentId: 'stu-1'),
          candidate(studentId: 'stu-2'),
        ], syncedAt: 500);

        final affected = await dao.replaceReenrollmentCohort(
          const [],
          syncedAt: 600,
        );

        expect(affected, 2); // wipe = vrai changement local, pas un notModified
        expect(await db.query('ref_previous_year_students'), isEmpty);
      },
    );
  });

  group('searchReenrollmentCandidates', () {
    setUp(() async {
      // Deux candidats à des niveaux différents, dans deux groupes différents.
      await dao.replaceReenrollmentCohort([
        candidate(studentId: 'stu-A', previousSchoolLevelId: 'lvl-A'),
        candidate(studentId: 'stu-B', previousSchoolLevelId: 'lvl-B'),
      ], syncedAt: 1);
      await db.insert('ref_school_levels', {
        'id': 'lvl-A',
        'name': 'Niveau A',
        'code': 'A',
        'level_group_id': 'grp-1',
        'display_order': 1,
        'split_into_classrooms': 0,
        'synced_at': 1,
      });
      await db.insert('ref_school_levels', {
        'id': 'lvl-B',
        'name': 'Niveau B',
        'code': 'B',
        'level_group_id': 'grp-2',
        'display_order': 1,
        'split_into_classrooms': 0,
        'synced_at': 1,
      });
    });

    test('filtre par niveau (previous_school_level_id)', () async {
      final result = await dao.searchReenrollmentCandidates(
        schoolLevelId: 'lvl-A',
      );
      expect(result.map((c) => c.studentId), ['stu-A']);
    });

    test(
      'filtre par groupe → niveaux du groupe (sous-select ref_school_levels)',
      () async {
        final result = await dao.searchReenrollmentCandidates(
          schoolLevelGroupId: 'grp-2',
        );
        expect(result.map((c) => c.studentId), ['stu-B']);
      },
    );

    test('sans filtre → tout le vivier (trié par nom)', () async {
      final result = await dao.searchReenrollmentCandidates();
      expect(result.map((c) => c.studentId).toSet(), {'stu-A', 'stu-B'});
    });

    test('niveau sans candidat → vide', () async {
      final result = await dao.searchReenrollmentCandidates(
        schoolLevelId: 'lvl-inconnu',
      );
      expect(result, isEmpty);
    });
  });

  group('upsertPreEnrollments', () {
    test('upsert + updated_at ISO converti en epoch ms', () async {
      final count = await dao.upsertPreEnrollments([
        preEnrollment(),
      ], syncedAt: 500);

      expect(count, 1);
      final row = (await db.query('ref_pre_enrollments')).single;
      expect(row['first_name'], 'Beni');
      expect(
        row['updated_at'],
        DateTime.parse('2026-07-08T09:30:00Z').millisecondsSinceEpoch,
      );
    });

    test('rejouer le même id remplace la ligne (delta idempotent)', () async {
      await dao.upsertPreEnrollments([preEnrollment()], syncedAt: 500);
      await dao.upsertPreEnrollments([
        preEnrollment(firstName: 'Benjamin', updatedAt: '2026-07-08T11:00:00Z'),
      ], syncedAt: 600);

      final rows = await db.query('ref_pre_enrollments');
      expect(rows, hasLength(1));
      expect(rows.single['first_name'], 'Benjamin');
    });

    test('updatedAt illisible → repli sur syncedAt, jamais de FormatException '
        '(anti poison-page, #21)', () async {
      // Une valeur non-ISO ne doit PAS lever : sinon l'apply de toute la page
      // échouerait et le curseur ne bougerait jamais → ressource figée en boucle.
      final count = await dao.upsertPreEnrollments([
        preEnrollment(updatedAt: 'pas-une-date'),
      ], syncedAt: 500);

      expect(count, 1);
      final row = (await db.query('ref_pre_enrollments')).single;
      expect(row['first_name'], 'Beni');
      expect(row['updated_at'], 500); // repli = syncedAt
    });
  });

  group('applyEnrollmentDelta', () {
    test('met à jour une ligne SYNCED plus ancienne (LWW)', () async {
      await seedEnrollment();
      final applied = await dao.applyEnrollmentDelta([delta()], syncedAt: 999);

      expect(applied, 1);
      final row = (await db.query('enrollments')).single;
      expect(row['status'], 'ACTIVE');
      expect(row['school_level_id'], 'lvl-2');
      expect(row['synced_at'], 999);
      expect(
        row['updated_at'],
        DateTime.parse('2026-07-08T10:00:00Z').millisecondsSinceEpoch,
      );
    });

    test('ne touche jamais un brouillon ou une écriture en attente', () async {
      await seedEnrollment(id: 'e1', syncStatus: SyncState.draft.dbValue);
      await seedEnrollment(id: 'e2', syncStatus: SyncState.pendingSync.dbValue);

      final applied = await dao.applyEnrollmentDelta([
        delta(id: 'e1'),
        delta(id: 'e2'),
      ], syncedAt: 999);

      expect(applied, 0);
      final statuses = (await db.query(
        'enrollments',
      )).map((r) => r['status']).toSet();
      expect(statuses, {'IN_PROGRESS'});
    });

    test('ignore un delta plus ancien que la ligne locale (LWW)', () async {
      final localMs = DateTime.parse(
        '2026-07-08T12:00:00Z',
      ).millisecondsSinceEpoch;
      await seedEnrollment(updatedAt: localMs);

      final applied = await dao.applyEnrollmentDelta([
        delta(updatedAt: '2026-07-08T10:00:00Z'),
      ], syncedAt: 999);

      expect(applied, 0);
    });

    test(
      'applique un delta d\'heure métier ÉGALE (LWW inclusif : <=)',
      () async {
        final ms = DateTime.parse(
          '2026-07-08T10:00:00Z',
        ).millisecondsSinceEpoch;
        await seedEnrollment(updatedAt: ms);

        final applied = await dao.applyEnrollmentDelta([
          delta(updatedAt: '2026-07-08T10:00:00Z'),
        ], syncedAt: 999);

        expect(applied, 1);
      },
    );

    test('répercute le matricule du delta sur l\'élève (ligne appliquée '
        'seulement)', () async {
      await seedStudent(matricule: 'ANCIEN-0001');
      await seedEnrollment();

      await dao.applyEnrollmentDelta([
        const EnrollmentDeltaDto(
          id: 'e1',
          studentId: 'stu-1',
          matriculationNumber: 'KIN-2026-0042',
          academicYearId: 'ay-1',
          status: 'ACTIVE',
          updatedAt: '2026-07-08T10:00:00Z',
          serverUpdatedAt: '2026-07-08T10:00:00Z',
        ),
      ], syncedAt: 999);

      final student = (await db.query('students')).single;
      expect(student['matriculation_number'], 'KIN-2026-0042');
    });

    test('ne répercute PAS le matricule quand la ligne est protégée', () async {
      await seedStudent(matricule: 'ANCIEN-0001');
      await seedEnrollment(syncStatus: SyncState.pendingSync.dbValue);

      await dao.applyEnrollmentDelta([
        const EnrollmentDeltaDto(
          id: 'e1',
          studentId: 'stu-1',
          matriculationNumber: 'KIN-2026-0042',
          academicYearId: 'ay-1',
          status: 'ACTIVE',
          updatedAt: '2026-07-08T10:00:00Z',
          serverUpdatedAt: '2026-07-08T10:00:00Z',
        ),
      ], syncedAt: 999);

      final student = (await db.query('students')).single;
      expect(student['matriculation_number'], 'ANCIEN-0001');
    });

    test(
      'réaligne le cycle sur le niveau reçu via ref_school_levels',
      () async {
        await db.insert('ref_school_levels', {
          'id': 'lvl-2',
          'name': '7ème',
          'code': 'S7',
          'level_group_id': 'grp-2',
          'display_order': 1,
          'split_into_classrooms': 0,
          'synced_at': 1,
        });
        await seedEnrollment(); // niveau lvl-1, cycle grp-1

        await dao.applyEnrollmentDelta([
          delta(schoolLevelId: 'lvl-2'),
        ], syncedAt: 999);

        final row = (await db.query('enrollments')).single;
        expect(row['school_level_id'], 'lvl-2');
        expect(row['school_level_group_id'], 'grp-2');
      },
    );

    test('niveau inconnu du référentiel local → cycle conservé '
        '(best-effort)', () async {
      await seedEnrollment(); // ref_school_levels vide

      await dao.applyEnrollmentDelta([
        delta(schoolLevelId: 'lvl-9'),
      ], syncedAt: 999);

      final row = (await db.query('enrollments')).single;
      expect(row['school_level_id'], 'lvl-9');
      expect(row['school_level_group_id'], 'grp-1');
    });

    test('academicYearId absent du delta → conserve l\'année locale', () async {
      await seedEnrollment();

      await dao.applyEnrollmentDelta([
        const EnrollmentDeltaDto(
          id: 'e1',
          studentId: 'stu-1',
          status: 'ACTIVE',
          updatedAt: '2026-07-08T10:00:00Z',
          serverUpdatedAt: '2026-07-08T10:00:00Z',
        ),
      ], syncedAt: 999);

      final row = (await db.query('enrollments')).single;
      expect(row['academic_year_id'], 'ay-1');
      expect(row['status'], 'ACTIVE');
    });

    test('ignore un id inconnu (dossier d\'une autre tablette — V1)', () async {
      final applied = await dao.applyEnrollmentDelta([
        delta(id: 'inconnu'),
      ], syncedAt: 999);

      expect(applied, 0);
      expect(await db.query('enrollments'), isEmpty);
    });

    test(
      'schoolLevelId absent → conserve le niveau local (COALESCE)',
      () async {
        await seedEnrollment();
        await dao.applyEnrollmentDelta([
          delta(schoolLevelId: null),
        ], syncedAt: 999);

        final row = (await db.query('enrollments')).single;
        expect(row['school_level_id'], 'lvl-1');
        expect(row['status'], 'ACTIVE');
      },
    );

    test('updatedAt illisible → repli syncedAt, dossier réconcilié sans '
        'FormatException (anti poison-page, #21)', () async {
      await seedEnrollment(updatedAt: 1000);

      final applied = await dao.applyEnrollmentDelta([
        delta(updatedAt: 'pas-une-date'),
      ], syncedAt: 5000);

      expect(applied, 1);
      final row = (await db.query('enrollments')).single;
      expect(row['status'], 'ACTIVE');
      expect(row['updated_at'], 5000); // repli = syncedAt (LWW passe)
    });
  });

  group('lectures seed local (findReenrollmentCandidateByStudentId)', () {
    test(
      'candidat présent → entité mappée (matricule, identité, solde)',
      () async {
        await dao.replaceReenrollmentCohort([candidate()], syncedAt: 1);

        final found = await dao.findReenrollmentCandidateByStudentId('stu-1');

        expect(found, isNotNull);
        expect(found!.studentId, 'stu-1');
        expect(found.matriculationNumber, 'KIN-2025-0001');
        expect(found.firstName, 'Amina');
        expect(found.gender, 'FEMALE');
        expect(found.previousBalanceInCents, 12500);
      },
    );

    test('cohorte vide / élève absent → null', () async {
      expect(await dao.findReenrollmentCandidateByStudentId('inconnu'), isNull);
    });
  });

  group('lectures seed local (findPreEnrollmentById)', () {
    test('préinscription présente → entité mappée', () async {
      await dao.upsertPreEnrollments([preEnrollment()], syncedAt: 1);

      final found = await dao.findPreEnrollmentById('pre-1');

      expect(found, isNotNull);
      expect(found!.id, 'pre-1');
      expect(found.firstName, 'Beni');
      expect(found.guardianPhone, '+243900000001');
    });

    test('snapshot vide / id absent → null', () async {
      expect(await dao.findPreEnrollmentById('inconnu'), isNull);
    });
  });

  group('findCurrentAcademicYearId', () {
    test('renvoie l\'id de l\'année is_current=1', () async {
      await db.insert('ref_academic_years', {
        'id': 'ay-old',
        'name': '2024-2025',
        'is_current': 0,
      });
      await db.insert('ref_academic_years', {
        'id': 'ay-cur',
        'name': '2025-2026',
        'is_current': 1,
      });

      expect(await dao.findCurrentAcademicYearId(), 'ay-cur');
    });

    test('aucune année courante (référentiel non pullé) → null', () async {
      expect(await dao.findCurrentAcademicYearId(), isNull);
    });
  });

  group('upsertEnrollmentSnapshots (hydratation)', () {
    EnrollmentAggregateSnapshotDto aggregate({
      String enrollmentId = 'e-snap-1',
      String studentId = 'stu-snap-1',
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
        status: 'IN_PROGRESS',
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
      ),
      parents: parents,
      serverUpdatedAt: serverUpdatedAt,
    );

    test('updatedAt ET serverUpdatedAt illisibles → repli syncedAt, agrégat '
        'hydraté sans FormatException (anti poison-page, #21)', () async {
      final applied = await dao.upsertEnrollmentSnapshots([
        aggregate(updatedAt: 'pas-une-date', serverUpdatedAt: 'non-plus'),
      ], syncedAt: 1234);

      expect(applied, 1);
      final row = (await db.query('enrollments')).single;
      expect(row['id'], 'e-snap-1');
      expect(row['updated_at'], 1234); // repli = syncedAt
    });

    test(
      'base vide → dossier visible via EnrollmentReadDao.getEnrollments',
      () async {
        final applied = await dao.upsertEnrollmentSnapshots([
          aggregate(),
        ], syncedAt: 1000);

        expect(applied, 1);
        final list = await EnrollmentReadDao(
          db,
        ).getEnrollments(status: 'IN_PROGRESS', academicYearId: 'ay-1');
        expect(list, hasLength(1));
        expect(list.single.enrollmentId, 'e-snap-1');
        expect(list.single.firstName, 'Grace');
        expect(list.single.matriculationNumber, 'KIN-2026-0001');
        expect(list.single.syncState, SyncState.synced);
      },
    );

    test('gros payload (> taille de lot) : tout appliqué à travers plusieurs '
        'transactions (verrou relâché entre lots)', () async {
      // 150 > _pullApplyBatchSize (100) → au moins 2 transactions ; le test
      // garantit qu'aucun dossier n'est perdu à la frontière des lots.
      const count = 150;
      final items = [
        for (var i = 0; i < count; i++)
          aggregate(
            enrollmentId: 'e-batch-$i',
            studentId: 'stu-batch-$i',
            parents: [
              ParentSnapshotDto(
                id: 'par-batch-$i',
                firstName: 'Tuteur',
                lastName: '$i',
                phoneNumber: '+24390$i',
                relationshipType: 'FATHER',
              ),
            ],
          ),
      ];

      final applied = await dao.upsertEnrollmentSnapshots(
        items,
        syncedAt: 1000,
      );

      expect(applied, count);
      expect(await db.query('enrollments'), hasLength(count));
      expect(
        await EnrollmentReadDao(
          db,
        ).getEnrollments(status: 'IN_PROGRESS', academicYearId: 'ay-1'),
        hasLength(count),
      );
    });

    test('tuteur local existant (même téléphone) réutilisé pour le lien, '
        'jamais rétrogradé', () async {
      // Tuteur provisoire créé localement (PENDING_SYNC), id différent, même tél.
      await db.insert('parents', {
        'id': 'par-local',
        'first_name': 'Jo',
        'last_name': 'Ilunga',
        'phone_number': '+243900000001',
        'sync_status': SyncState.pendingSync.dbValue,
        'updated_at': 5,
      });

      await dao.upsertEnrollmentSnapshots([aggregate()], syncedAt: 1000);

      // Pas de doublon : un seul parent (le local), non rétrogradé en SYNCED.
      final parents = await db.query('parents');
      expect(parents, hasLength(1));
      expect(parents.single['id'], 'par-local');
      expect(parents.single['sync_status'], SyncState.pendingSync.dbValue);
      // Le lien pointe le parent local résolu par téléphone.
      final link = (await db.query('student_parent')).single;
      expect(link['parent_id'], 'par-local');
      expect(link['relationship_type'], 'FATHER');
    });

    test('téléphone canonique corrigé côté serveur → rafraîchi par id (pas de '
        'doublon)', () async {
      await dao.upsertEnrollmentSnapshots([aggregate()], syncedAt: 1000);

      // Pull #2 : MÊME id canonique, téléphone corrigé.
      await dao.upsertEnrollmentSnapshots([
        aggregate(
          parents: const [
            ParentSnapshotDto(
              id: 'par-snap-1',
              firstName: 'Joseph',
              lastName: 'Ilunga',
              phoneNumber: '+243999999999',
              relationshipType: 'FATHER',
            ),
          ],
        ),
      ], syncedAt: 2000);

      final parents = await db.query('parents');
      expect(parents, hasLength(1)); // résolu par id, pas de doublon
      expect(parents.single['phone_number'], '+243999999999'); // rafraîchi
    });

    test('deux tuteurs distincts au même téléphone → non fusionnés (résolution '
        'par id)', () async {
      await dao.upsertEnrollmentSnapshots([
        aggregate(
          parents: const [
            ParentSnapshotDto(
              id: 'par-pere',
              firstName: 'Joseph',
              lastName: 'Ilunga',
              phoneNumber: '+243900000001',
              relationshipType: 'FATHER',
            ),
            ParentSnapshotDto(
              id: 'par-mere',
              firstName: 'Marie',
              lastName: 'Ilunga',
              phoneNumber: '+243900000001', // même ligne fixe du foyer
              relationshipType: 'MOTHER',
            ),
          ],
        ),
      ], syncedAt: 1000);

      expect(await db.query('parents'), hasLength(2));
      expect(await db.query('student_parent'), hasLength(2));
    });

    test('tuteur retiré du dossier serveur → lien SYNCED purgé', () async {
      await dao.upsertEnrollmentSnapshots([
        aggregate(
          parents: const [
            ParentSnapshotDto(
              id: 'par-A',
              firstName: 'Joseph',
              lastName: 'Ilunga',
              phoneNumber: '+243900000001',
              relationshipType: 'FATHER',
            ),
            ParentSnapshotDto(
              id: 'par-B',
              firstName: 'Marie',
              lastName: 'Ilunga',
              phoneNumber: '+243900000002',
              relationshipType: 'MOTHER',
            ),
          ],
        ),
      ], syncedAt: 1000);
      expect(await db.query('student_parent'), hasLength(2));

      // Pull #2 : la mère (par-B) a été retirée du dossier serveur.
      await dao.upsertEnrollmentSnapshots([
        aggregate(
          parents: const [
            ParentSnapshotDto(
              id: 'par-A',
              firstName: 'Joseph',
              lastName: 'Ilunga',
              phoneNumber: '+243900000001',
              relationshipType: 'FATHER',
            ),
          ],
        ),
      ], syncedAt: 2000);

      final links = await db.query('student_parent');
      expect(links, hasLength(1));
      expect(links.single['parent_id'], 'par-A');
    });
  });
}
