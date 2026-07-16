import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/models/enrollment_local_models.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_models.dart';

import '../../offline_full_db.dart';

void main() {
  late Database db;
  late EnrollmentReadDao readDao;
  late EnrollmentDraftDao draftDao;
  late EnrollmentAckDao ackDao;

  setUp(() async {
    db = await openFullOfflineDb();
    readDao = EnrollmentReadDao(db);
    draftDao = EnrollmentDraftDao(db);
    ackDao = EnrollmentAckDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  StudentLocalModel student({String id = 's1', String phone = '+243900'}) =>
      StudentLocalModel(
        id: id,
        firstName: 'Amina',
        lastName: 'Moke',
        surname: 'Junior',
        gender: 'FEMALE',
        dateOfBirth: '2015-04-02',
        birthPlace: 'Kinshasa',
        nationality: 'CD',
        phoneNumber: phone,
        updatedAt: 100,
      );

  EnrollmentLocalModel enrollment({
    String id = 'e1',
    String studentId = 's1',
  }) => EnrollmentLocalModel(
    id: id,
    studentId: studentId,
    enrollmentType: 'NEW_ENROLLMENT',
    status: 'IN_PROGRESS',
    academicYearId: 'ay-2026',
    schoolLevelId: 'lvl-1',
    enrollmentDate: '2026-07-06',
    updatedAt: 100,
  );

  ParentDraft parent({
    String id = 'p1',
    String phone = '+243111',
    String rel = 'MOTHER',
  }) => ParentDraft(
    parent: ParentLocalModel(
      id: id,
      firstName: 'Sarah',
      lastName: 'Moke',
      phoneNumber: phone,
      updatedAt: 100,
    ),
    relationshipType: rel,
  );

  GeneratedDocumentLocalModel doc({String enrollmentId = 'e1'}) =>
      GeneratedDocumentLocalModel(
        id: 'd1',
        docDomain: 'ENROLLMENT',
        enrollmentId: enrollmentId,
        studentId: 's1',
        docType: 'AI',
        number: 'PROV-ABCDEF12',
        createdAt: 100,
      );

  /// Fixture d'un dossier **PENDING_SYNC** via le VRAI chemin de production
  /// (draft-par-étape → finalize) : remplace l'ancien one-shot
  /// `EnrollmentCommitDao.confirmEnrollment` (retiré à l'étape c). Produit
  /// élève + inscription + tuteurs (dédup par téléphone) + doc provisoire +
  /// entrée outbox agrégat, tous en PENDING_SYNC.
  Future<void> seedPendingEnrollment({
    StudentLocalModel? withStudent,
    EnrollmentLocalModel? withEnrollment,
    List<ParentDraft> parents = const [],
    GeneratedDocumentLocalModel? document,
    String? schoolId,
    int nowMs = 1000,
  }) async {
    final st = withStudent ?? student();
    final en = withEnrollment ?? enrollment();
    await draftDao.insertDraftStudent(st);
    await draftDao.insertDraftEnrollment(en);
    if (parents.isNotEmpty) {
      await draftDao.replaceDraftParents(st.id, parents, nowMs: nowMs);
    }
    await draftDao.finalizeDraft(
      en.id,
      document: document,
      emitDocument: document != null,
      schoolId: schoolId,
      nowMs: nowMs,
    );
  }

  group('finalize (fixture PENDING_SYNC) — dédup parent fratrie', () {
    test(
      'deux dossiers, même téléphone tuteur : un seul parent dédupliqué',
      () async {
        await seedPendingEnrollment(
          withStudent: student(id: 's1', phone: '+243900'),
          withEnrollment: enrollment(id: 'e1', studentId: 's1'),
          parents: [parent(id: 'p1', phone: '+243111')],
          nowMs: 1000,
        );
        // Second dossier (fratrie), même téléphone mais id provisoire différent.
        await seedPendingEnrollment(
          withStudent: student(id: 's2', phone: '+243901'),
          withEnrollment: enrollment(id: 'e2', studentId: 's2'),
          parents: [parent(id: 'p2', phone: '+243111')],
          nowMs: 2000,
        );

        final parents = await db.query('parents');
        expect(parents, hasLength(1), reason: 'un seul parent dédupliqué');
        expect(parents.first['id'], 'p1');

        final links = await db.query('student_parent');
        expect(links, hasLength(2));
        expect(
          links.every((l) => l['parent_id'] == 'p1'),
          isTrue,
          reason: 'les deux liens pointent le parent dédupliqué',
        );
      },
    );
  });

  group('applyEnrollmentAck (F4 remap)', () {
    test('COMMITTED : matricule/email, parent provisoire→canonique (parents ET '
        'student_parent), doc DEFINITIVE, SYNCED', () async {
      await seedPendingEnrollment(
        parents: [parent(id: 'p-prov')],
        document: doc(),
      );

      await ackDao.applyEnrollmentAck(
        const EnrollmentAggregateResponse(
          enrollment: ResponseEnrollment(
            id: 'e1',
            status: 'ADMIN_COMPLETED',
            enrollmentCode: 'ETL-2026-001',
          ),
          student: ResponseStudent(
            id: 's1',
            matriculationNumber: 'MAT-0001',
            email: 'amina@school.cd',
          ),
          parents: [ParentRemap(providedId: 'p-prov', canonicalId: 'p-canon')],
          documents: [
            GeneratedDocumentDto(
              type: 'ENROLLMENT_CERTIFICATE',
              documentNumber: 'ETL-AI-0001',
              status: 'DEFINITIVE',
            ),
          ],
        ),
        enrollmentId: 'e1',
        nowMs: 5000,
      );

      final s = (await db.query('students')).first;
      expect(s['matriculation_number'], 'MAT-0001');
      expect(s['email'], 'amina@school.cd');
      expect(s['sync_status'], SyncState.synced.dbValue);

      final parents = await db.query('parents');
      expect(parents, hasLength(1));
      expect(parents.first['id'], 'p-canon');

      final link = (await db.query('student_parent')).first;
      expect(link['parent_id'], 'p-canon');

      final d = (await db.query('generated_documents')).first;
      expect(d['status'], 'DEFINITIVE');
      expect(d['number'], 'ETL-AI-0001');

      final e = (await db.query('enrollments')).first;
      expect(e['sync_status'], SyncState.synced.dbValue);
      expect(e['enrollment_code'], 'ETL-2026-001');
      expect(e['status'], 'ADMIN_COMPLETED');
    });

    test(
      'markEnrollmentSyncError (422) : SYNC_ERROR + message sur enrollment et '
      'student',
      () async {
        await seedPendingEnrollment(parents: [parent()]);

        await ackDao.markEnrollmentSyncError(
          'e1',
          'Date invalide',
          nowMs: 5000,
        );

        final e = (await db.query('enrollments')).first;
        expect(e['sync_status'], SyncState.syncError.dbValue);
        expect(e['sync_error'], 'Date invalide');
        final s = (await db.query('students')).first;
        expect(s['sync_status'], SyncState.syncError.dbValue);
      },
    );
  });

  group('lectures', () {
    setUp(() async {
      await seedPendingEnrollment(parents: [parent()], document: doc());
    });

    test('getEnrollments + filtre par statut', () async {
      expect(await readDao.getEnrollments(), hasLength(1));
      expect(await readDao.getEnrollments(status: 'IN_PROGRESS'), hasLength(1));
      expect(await readDao.getEnrollments(status: 'COMPLETED'), isEmpty);
    });

    test('getEnrollments + filtre par type d\'inscription', () async {
      // Le dossier seedé est NEW_ENROLLMENT : un filtre PRE/RE l'exclut.
      expect(
        await readDao.getEnrollments(enrollmentType: 'NEW_ENROLLMENT'),
        hasLength(1),
      );
      expect(
        await readDao.getEnrollments(enrollmentType: 'PRE_ENROLLMENT'),
        isEmpty,
      );
    });

    test('getEnrollments + filtre par année scolaire', () async {
      expect(
        await readDao.getEnrollments(academicYearId: 'ay-2026'),
        hasLength(1),
      );
      expect(await readDao.getEnrollments(academicYearId: 'ay-1999'), isEmpty);
      // Combinaison statut + année.
      expect(
        await readDao.getEnrollments(
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
        ),
        hasLength(1),
      );
    });

    test(
      'findLocalDossierRefForStudentYear : id + syncState par élève+année',
      () async {
        final ref = await readDao.findLocalDossierRefForStudentYear(
          studentId: 's1',
          academicYearId: 'ay-2026',
        );
        expect(ref, isNotNull);
        expect(ref!.enrollmentId, 'e1');
        expect(ref.syncState, SyncState.pendingSync);
      },
    );

    test(
      'findLocalDossierRefForStudentYear : autre année → null (jamais le N-1)',
      () async {
        expect(
          await readDao.findLocalDossierRefForStudentYear(
            studentId: 's1',
            academicYearId: 'ay-2025',
          ),
          isNull,
        );
      },
    );

    test('searchByAcademicInfo filtre sur l\'inscription', () async {
      expect(
        await readDao.searchByAcademicInfo(academicYearId: 'ay-2026'),
        hasLength(1),
      );
      expect(
        await readDao.searchByAcademicInfo(schoolLevelId: 'other'),
        isEmpty,
      );
    });

    test('getDetail assemble élève + tuteurs + documents', () async {
      final detail = await readDao.getDetail('e1');
      expect(detail, isNotNull);
      expect(detail!.student.firstName, 'Amina');
      expect(detail.parents, hasLength(1));
      expect(detail.documents, hasLength(1));
    });
  });

  group('getEnrollments — filtre par type (anti-confusion pré-inscription / '
      'réinscription)', () {
    setUp(() async {
      // Le cœur du bug : DEUX brouillons AU MÊME statut métier PRE_REGISTERED
      // mais de TYPES différents — une vraie pré-inscription et une
      // réinscription. Sans filtre par type, la page Pré-inscriptions (qui
      // filtre par statut) afficherait aussi la réinscription.
      await draftDao.insertDraftStudent(student(id: 's-pre', phone: '+243001'));
      await draftDao.insertDraftStudent(student(id: 's-re', phone: '+243002'));
      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e-pre',
          studentId: 's-pre',
          enrollmentType: 'PRE_ENROLLMENT',
          status: 'PRE_REGISTERED',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-06',
          updatedAt: 100,
        ),
      );
      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e-re',
          studentId: 's-re',
          enrollmentType: 'RE_ENROLLMENT',
          status: 'PRE_REGISTERED',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-06',
          updatedAt: 100,
        ),
      );
    });

    test('statut PRE_REGISTERED + type PRE_ENROLLMENT → exclut la '
        'réinscription', () async {
      final preOnly = await readDao.getEnrollments(
        status: 'PRE_REGISTERED',
        enrollmentType: 'PRE_ENROLLMENT',
      );
      expect(preOnly, hasLength(1));
      expect(preOnly.single.enrollmentId, 'e-pre');
    });

    test('sans filtre de type, les deux dossiers PRE_REGISTERED remontent '
        '(comportement historique préservé)', () async {
      expect(
        await readDao.getEnrollments(status: 'PRE_REGISTERED'),
        hasLength(2),
      );
    });

    test('filtre RE_ENROLLMENT → ne renvoie que la réinscription', () async {
      final reOnly = await readDao.getEnrollments(
        enrollmentType: 'RE_ENROLLMENT',
      );
      expect(reOnly, hasLength(1));
      expect(reOnly.single.enrollmentId, 'e-re');
    });
  });

  group('isStudentEnrollmentSynced (FIFO gate)', () {
    test('faux tant que PENDING, vrai une fois SYNCED, vrai si aucune '
        'inscription locale', () async {
      await seedPendingEnrollment(parents: [parent()]);
      expect(await readDao.isStudentEnrollmentSynced('s1'), isFalse);

      await ackDao.applyEnrollmentAck(
        const EnrollmentAggregateResponse(
          enrollment: ResponseEnrollment(id: 'e1'),
          student: ResponseStudent(id: 's1', matriculationNumber: 'MAT-1'),
        ),
        enrollmentId: 'e1',
        nowMs: 2000,
      );
      expect(await readDao.isStudentEnrollmentSynced('s1'), isTrue);
      // Élève préexistant (aucune inscription locale).
      expect(await readDao.isStudentEnrollmentSynced('unknown'), isTrue);
    });
  });

  group('DRAFT incrémental (refonte offline-first wizard)', () {
    test('insertDraft* écrit en DRAFT et remonte dans les listes (repris '
        'depuis le listing)', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(enrollment());

      expect(
        (await db.query('students')).first['sync_status'],
        SyncState.draft.dbValue,
      );
      expect(
        (await db.query('enrollments')).first['sync_status'],
        SyncState.draft.dbValue,
      );
      // Le brouillon (DRAFT, statut métier IN_PROGRESS) remonte désormais dans
      // les listes/recherches pour être repris depuis le listing (il reste
      // exclu du PUSH tant qu'il n'est pas finalisé).
      final listed = await readDao.getEnrollments();
      expect(listed, hasLength(1));
      expect(listed.first.syncState, SyncState.draft);
      expect(
        await readDao.searchByAcademicInfo(academicYearId: 'ay-2026'),
        hasLength(1),
      );
    });

    test('updateDraftStudentColumns : partiel, n\'écrase pas les autres '
        'colonnes, reste DRAFT', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.updateDraftStudentColumns('s1', {
        'city': 'Goma',
      }, nowMs: 200);

      final s = (await db.query('students')).first;
      expect(s['city'], 'Goma');
      expect(s['first_name'], 'Amina'); // inchangé
      expect(s['sync_status'], SyncState.draft.dbValue);
    });

    test(
      'updateDraftStudentColumns ne touche pas un dossier non-DRAFT',
      () async {
        await seedPendingEnrollment(parents: [parent()]); // PENDING_SYNC
        await draftDao.updateDraftStudentColumns('s1', {
          'city': 'Goma',
        }, nowMs: 200);
        expect((await db.query('students')).first['city'], isNull);
      },
    );

    test('replaceDraftParents lie en DRAFT et remplace au ré-appel', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.replaceDraftParents('s1', [
        parent(id: 'p1', phone: '+243111'),
      ], nowMs: 200);
      expect(await db.query('student_parent'), hasLength(1));
      expect(
        (await db.query('parents')).first['sync_status'],
        SyncState.draft.dbValue,
      );

      await draftDao.replaceDraftParents('s1', [
        parent(id: 'p2', phone: '+243222', rel: 'FATHER'),
      ], nowMs: 300);
      final links = await db.query('student_parent');
      expect(links, hasLength(1));
      expect(links.first['relationship_type'], 'FATHER');
    });

    test(
      'finalizeDraft : DRAFT→PENDING_SYNC (élève+inscription+tuteurs), 1 '
      'outbox à id déterministe, apparaît dans les listes, idempotent',
      () async {
        await draftDao.insertDraftStudent(student());
        await draftDao.insertDraftEnrollment(enrollment());
        await draftDao.replaceDraftParents('s1', [parent()], nowMs: 200);
        // Le brouillon est listé (repris depuis le listing) même avant flush.
        expect(await readDao.getEnrollments(), hasLength(1));

        final ok = await draftDao.finalizeDraft(
          'e1',
          document: doc(),
          schoolId: 'school-1',
          nowMs: 1000,
        );
        expect(ok, isTrue);
        expect(
          (await db.query('students')).first['sync_status'],
          SyncState.pendingSync.dbValue,
        );
        expect(
          (await db.query('enrollments')).first['sync_status'],
          SyncState.pendingSync.dbValue,
        );
        expect(
          (await db.query('parents')).first['sync_status'],
          SyncState.pendingSync.dbValue,
        );

        final ob = await db.query('outbox');
        expect(ob, hasLength(1));
        expect(ob.first['id'], 'outbox-enr-e1');
        expect(ob.first['aggregate_id'], 'e1');
        expect(ob.first['school_id'], 'school-1');
        final payload =
            jsonDecode(ob.first['payload'] as String) as Map<String, dynamic>;
        expect(payload['parents'], hasLength(1));

        // Le dossier confirmé apparaît désormais dans les listes.
        expect(await readDao.getEnrollments(), hasLength(1));

        // Re-confirmation : no-op idempotent, pas de doublon outbox.
        final again = await draftDao.finalizeDraft(
          'e1',
          document: doc(),
          nowMs: 2000,
        );
        expect(again, isFalse);
        expect(await db.query('outbox'), hasLength(1));
      },
    );

    test('finalizeDraft renvoie false si l\'inscription est absente', () async {
      expect(await draftDao.finalizeDraft('ghost', nowMs: 1000), isFalse);
    });
  });

  group('seedDraft (photo de départ RE/PRE)', () {
    StudentLocalModel seededStudent() => const StudentLocalModel(
      id: 's1',
      firstName: 'Amina',
      lastName: 'Moke',
      surname: 'Junior',
      gender: 'FEMALE',
      dateOfBirth: '2015-04-02',
      birthPlace: 'Kinshasa',
      nationality: 'CD',
      city: 'Kinshasa',
      matriculationNumber: 'KIN-2025-0001',
      updatedAt: 100,
    );

    EnrollmentLocalModel seededEnrollment() => const EnrollmentLocalModel(
      id: 'e1',
      studentId: 's1',
      enrollmentType: 'RE_ENROLLMENT',
      status: 'PRE_REGISTERED',
      academicYearId: 'ay-2026',
      schoolLevelId: 'lvl-2',
      enrollmentDate: '2026-07-08',
      sourceRef: 'KIN-2025-0001',
      previousSchoolName: 'EP Les Aiglons',
      updatedAt: 100,
    );

    test('écrit l\'agrégat complet en DRAFT (élève+inscription+tuteurs) '
        'en une passe', () async {
      final ok = await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: [parent()],
        nowMs: 100,
      );

      expect(ok, isTrue);
      final s = (await db.query('students')).single;
      expect(s['sync_status'], SyncState.draft.dbValue);
      expect(s['matriculation_number'], 'KIN-2025-0001');
      final e = (await db.query('enrollments')).single;
      expect(e['sync_status'], SyncState.draft.dbValue);
      expect(e['source_ref'], 'KIN-2025-0001');
      expect(e['enrollment_type'], 'RE_ENROLLMENT');
      expect(await db.query('student_parent'), hasLength(1));
      // Un brouillon seedé (RE/PRE) est listé comme les autres brouillons,
      // pour être repris depuis le listing.
      final listed = await readDao.getEnrollments();
      expect(listed, hasLength(1));
      expect(listed.first.syncState, SyncState.draft);
    });

    test('re-save identité APRÈS seed : adresse, matricule, antécédents et '
        'source_ref conservés (sémantique préservante)', () async {
      await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: const [],
        nowMs: 100,
      );

      // L'étape Identité re-sauve avec ses seuls champs (matricule null,
      // niveau null) — elle ne doit rien écraser d'autre.
      await draftDao.insertDraftStudent(
        const StudentLocalModel(
          id: 's1',
          firstName: 'Amina-Grâce',
          lastName: 'Moke',
          surname: 'Junior',
          gender: 'FEMALE',
          dateOfBirth: '2015-04-02',
          birthPlace: 'Kinshasa',
          nationality: 'CD',
          updatedAt: 200,
        ),
      );
      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e1',
          studentId: 's1',
          enrollmentType: 'RE_ENROLLMENT',
          status: 'PRE_REGISTERED',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-08',
          updatedAt: 200,
        ),
      );

      final s = (await db.query('students')).single;
      expect(s['first_name'], 'Amina-Grâce'); // identité mise à jour
      expect(s['city'], 'Kinshasa'); // adresse conservée
      expect(s['matriculation_number'], 'KIN-2025-0001'); // conservé
      final e = (await db.query('enrollments')).single;
      expect(e['source_ref'], 'KIN-2025-0001'); // conservé
      expect(e['school_level_id'], 'lvl-2'); // niveau conservé (null ignoré)
      expect(e['previous_school_name'], 'EP Les Aiglons'); // conservé
    });

    test('refuse de re-seeder un dossier local déjà confirmé', () async {
      await seedPendingEnrollment(nowMs: 100); // e1 → PENDING_SYNC

      final ok = await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: const [],
        nowMs: 200,
      );

      expect(ok, isFalse);
      expect(
        (await db.query('enrollments')).single['sync_status'],
        SyncState.pendingSync.dbValue,
      );
    });

    test('ne rétrograde jamais un élève déjà synchronisé', () async {
      await db.insert(
        'students',
        student().toMap()..['sync_status'] = SyncState.synced.dbValue,
      );

      final ok = await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: const [],
        nowMs: 200,
      );

      expect(ok, isTrue);
      final s = (await db.query('students')).single;
      expect(s['sync_status'], SyncState.synced.dbValue); // jamais rétrogradé
      expect(s['city'], 'Kinshasa'); // identité rafraîchie malgré tout
      expect(
        (await db.query('enrollments')).single['sync_status'],
        SyncState.draft.dbValue,
      );
    });

    test('finalize après seed : le payload outbox porte sourceRef', () async {
      await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: [parent()],
        nowMs: 100,
      );

      final ok = await draftDao.finalizeDraft('e1', nowMs: 1000);

      expect(ok, isTrue);
      final payload =
          jsonDecode((await db.query('outbox')).single['payload'] as String)
              as Map<String, dynamic>;
      expect(
        (payload['enrollment'] as Map<String, dynamic>)['sourceRef'],
        'KIN-2025-0001',
      );
    });
  });
}
