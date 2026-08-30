import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/outbox_dependency_gate.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_dao_support.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
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

  StudentLocalModel student({String id = 's1'}) => StudentLocalModel(
    id: id,
    firstName: 'Amina',
    lastName: 'Moke',
    surname: 'Junior',
    gender: 'FEMALE',
    dateOfBirth: '2015-04-02',
    birthPlace: 'Kinshasa',
    nationality: 'CD',
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
          withStudent: student(id: 's1'),
          withEnrollment: enrollment(id: 'e1', studentId: 's1'),
          parents: [parent(id: 'p1', phone: '+243111')],
          nowMs: 1000,
        );
        // Second dossier (fratrie), même téléphone mais id provisoire différent.
        await seedPendingEnrollment(
          withStudent: student(id: 's2'),
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

  group('contact d\'urgence — le lien (élève, tuteur)', () {
    ParentDraft designating(
      bool? designation, {
      String id = 'p1',
      String phone = '+243111',
    }) => ParentDraft(
      parent: ParentLocalModel(
        id: id,
        firstName: 'Sarah',
        lastName: 'Moke',
        phoneNumber: phone,
        updatedAt: 100,
      ),
      relationshipType: 'MOTHER',
      emergencyContact: designation,
    );

    Future<Object?> designationOf(String parentId) async {
      final rows = await db.query(
        'student_parent',
        columns: const ['emergency_contact'],
        where: 'student_id = ? AND parent_id = ?',
        whereArgs: ['s1', parentId],
      );
      return rows.single['emergency_contact'];
    }

    setUp(() async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(enrollment());
    });

    test('la désignation s\'écrit sur le lien, pas sur le tuteur', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(true),
      ], nowMs: 1000);

      expect(await designationOf('p1'), 1);
      // La fiche du tuteur ne porte rien : un même adulte peut être le contact
      // d'urgence d'un enfant et pas de son frère.
      final parentColumns = await db.rawQuery('PRAGMA table_info(parents)');
      expect(
        parentColumns.map((c) => c['name']),
        isNot(contains('emergency_contact')),
      );
    });

    /// Le remplacement des tuteurs purge tous les liens de l'élève avant de les
    /// réécrire. Sans la photo prise avant la purge, chaque passage sur l'étape
    /// Tuteurs — pour corriger un numéro, ajouter un oncle — effacerait la
    /// désignation en place. « Ne rien dire » n'est pas « non ».
    test('un draft MUET conserve la désignation en place', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(true),
      ], nowMs: 1000);

      await draftDao.replaceDraftParents('s1', [
        designating(null),
      ], nowMs: 2000);

      expect(await designationOf('p1'), 1);
    });

    test('un draft à `false` retire la désignation', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(true),
      ], nowMs: 1000);

      await draftDao.replaceDraftParents('s1', [
        designating(false),
      ], nowMs: 2000);

      expect(await designationOf('p1'), 0);
    });

    test('un tuteur ajouté sans rien dire ne déloge personne', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(true, id: 'p1', phone: '+243111'),
      ], nowMs: 1000);

      await draftDao.replaceDraftParents('s1', [
        designating(null, id: 'p1', phone: '+243111'),
        designating(null, id: 'p2', phone: '+243222'),
      ], nowMs: 2000);

      expect(await designationOf('p1'), 1);
      expect(await designationOf('p2'), 0);
    });

    /// Refusé AVANT toute écriture, et pas laissé à l'index unique partiel :
    /// les liens s'écrivent en `INSERT OR REPLACE`, sous lequel SQLite
    /// SUPPRIME la ligne en conflit au lieu de lever. Le filet deviendrait un
    /// destructeur silencieux — le tuteur désigné en premier disparaîtrait du
    /// dossier, drapeau ET lien.
    test(
      'deux désignations dans le même dossier : refusé avant écriture',
      () async {
        await expectLater(
          draftDao.replaceDraftParents('s1', [
            designating(true, id: 'p1', phone: '+243111'),
            designating(true, id: 'p2', phone: '+243222'),
          ], nowMs: 1000),
          throwsA(isA<AmbiguousEmergencyContactException>()),
        );

        // Rien n'a bougé : ni lien créé, ni lien détruit.
        expect(await db.query('student_parent'), isEmpty);
      },
    );

    /// Le refus ne doit pas non plus détruire ce qui existait déjà : la garde
    /// précède la purge des liens, pas l'inverse.
    test('un refus laisse le dossier intact', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(true, id: 'p1', phone: '+243111'),
      ], nowMs: 1000);

      await expectLater(
        draftDao.replaceDraftParents('s1', [
          designating(true, id: 'p1', phone: '+243111'),
          designating(true, id: 'p2', phone: '+243222'),
        ], nowMs: 2000),
        throwsA(isA<AmbiguousEmergencyContactException>()),
      );

      expect(await db.query('student_parent'), hasLength(1));
      expect(await designationOf('p1'), 1);
    });

    /// Sur le fil : `true` sur le désigné, `false` sur les autres.
    ///
    /// **Ce test attendait l'inverse** — `true` ou rien — au motif qu'un
    /// `false` projeté écraserait une désignation faite ailleurs. Le
    /// raisonnement tenait pour un tuteur pris isolément ; il oubliait que la
    /// base ne distingue pas « jamais désigné » de « retiré ». Le retrait
    /// mourait donc au dernier saut : case décochée, lien local à 0, clé
    /// absente du fil, serveur inchangé, et le pull suivant qui remet tout
    /// comme avant. L'agrégat portant la liste COMPLÈTE des tuteurs, il n'y a
    /// rien à préserver qu'il ne dise déjà.
    test('le payload poussé dit la désignation ET le retrait', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(true, id: 'p1', phone: '+243111'),
        designating(null, id: 'p2', phone: '+243222'),
      ], nowMs: 1000);
      await draftDao.finalizeDraft('e1', emitDocument: false, nowMs: 2000);

      final entries = await db.query('outbox');
      final command =
          jsonDecode(entries.single['payload'] as String)
              as Map<String, dynamic>;
      final parents = (command['parents'] as List).cast<Map<String, dynamic>>();

      final designated = parents.firstWhere((p) => p['clientId'] == 'p1');
      final ordinary = parents.firstWhere((p) => p['clientId'] == 'p2');
      expect(designated['emergencyContact'], isTrue);
      expect(ordinary['emergencyContact'], isFalse);
    });

    /// Le cas qui donne son sens au `false` : un dossier où plus personne
    /// n'est désigné doit le DIRE, sinon le serveur garde son désigné et le
    /// pull suivant le réaffiche.
    test('un dossier sans désignation pousse `false` partout', () async {
      await draftDao.replaceDraftParents('s1', [
        designating(null, id: 'p1', phone: '+243111'),
        designating(null, id: 'p2', phone: '+243222'),
      ], nowMs: 1000);
      await draftDao.finalizeDraft('e1', emitDocument: false, nowMs: 2000);

      final entries = await db.query('outbox');
      final command =
          jsonDecode(entries.single['payload'] as String)
              as Map<String, dynamic>;
      final parents = (command['parents'] as List).cast<Map<String, dynamic>>();

      expect(parents.map((p) => p['emergencyContact']), everyElement(isFalse));
    });

    test(
      'la fiche santé et « ancien élève » partent avec l\'agrégat',
      () async {
        await db.update(
          'enrollments',
          {'former_student': 1, 'medical_notes': 'Asthme.'},
          where: 'id = ?',
          whereArgs: ['e1'],
        );

        await draftDao.finalizeDraft('e1', emitDocument: false, nowMs: 2000);

        final entries = await db.query('outbox');
        final command =
            jsonDecode(entries.single['payload'] as String)
                as Map<String, dynamic>;
        final enrollmentJson = command['enrollment'] as Map<String, dynamic>;
        expect(enrollmentJson['formerStudent'], isTrue);
        expect(enrollmentJson['medicalNotes'], 'Asthme.');
      },
    );
  });

  /// La fiche santé suit la sémantique du serveur : omise elle est conservée,
  /// vide elle est effacée. C'est ce qui la protège d'un appelant qui ne la
  /// saisit pas — le seed lui-même, ou un chemin d'écriture qui l'ignore.
  group('fiche santé — omise conservée, vide effacée', () {
    setUp(() async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e1',
          studentId: 's1',
          enrollmentType: 'NEW_ENROLLMENT',
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-06',
          medicalNotes: 'Allergie aux arachides.',
          updatedAt: 100,
        ),
      );
    });

    Future<Object?> noteOf() async {
      final rows = await db.query(
        'enrollments',
        columns: const ['medical_notes'],
        where: 'id = ?',
        whereArgs: ['e1'],
      );
      return rows.single['medical_notes'];
    }

    test('un re-save qui ne dit rien conserve la note', () async {
      await draftDao.insertDraftEnrollment(
        enrollment(), // pas de medicalNotes
      );

      expect(await noteOf(), 'Allergie aux arachides.');
    });

    test('une chaîne vide efface la note — mais il faut le dire', () async {
      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e1',
          studentId: 's1',
          enrollmentType: 'NEW_ENROLLMENT',
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-06',
          medicalNotes: '',
          updatedAt: 200,
        ),
      );

      expect(await noteOf(), isNull);
    });

    /// Une chaîne blanche vaut « vide », pas « renseignée avec des espaces » —
    /// sans quoi la colonne porterait un texte qui se lirait comme une fiche
    /// remplie sur l'écran d'à côté.
    test('des espaces seuls valent une fiche vide', () async {
      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e1',
          studentId: 's1',
          enrollmentType: 'NEW_ENROLLMENT',
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-06',
          medicalNotes: '   ',
          updatedAt: 200,
        ),
      );

      expect(await noteOf(), isNull);
    });
  });

  /// Reflet local d'une désignation déjà acquittée par le serveur (INT-7).
  /// L'écran de consultation est 100 % local : sans lui, il garderait l'ancien
  /// contact jusqu'au prochain pull.
  group('applyEmergencyContactDesignation (reflet d\'un 204)', () {
    late EnrollmentReconciliationDao reconciliationDao;

    setUp(() async {
      reconciliationDao = EnrollmentReconciliationDao(db);
      await draftDao.insertDraftStudent(student());
      for (final id in ['p1', 'p2']) {
        await db.insert('parents', {
          'id': id,
          'first_name': 'T',
          'last_name': id,
          'phone_number': '+24390$id',
          'updated_at': 0,
        });
        await db.insert('student_parent', {
          'student_id': 's1',
          'parent_id': id,
          'relationship_type': 'OTHER',
        });
      }
    });

    Future<Map<String, Object?>> designations() async {
      final rows = await db.query(
        'student_parent',
        where: 'student_id = ?',
        whereArgs: ['s1'],
      );
      return {
        for (final row in rows)
          row['parent_id'] as String: row['emergency_contact'],
      };
    }

    test('désigne, et démote dans la même transaction', () async {
      await reconciliationDao.applyEmergencyContactDesignation(
        studentId: 's1',
        parentId: 'p1',
      );
      expect(await designations(), {'p1': 1, 'p2': 0});

      // Désigner p2 doit démoter p1 : l'index unique partiel n'admet qu'une
      // ligne à 1 par élève, et promouvoir sans démoter le violerait.
      await reconciliationDao.applyEmergencyContactDesignation(
        studentId: 's1',
        parentId: 'p2',
      );
      expect(await designations(), {'p1': 0, 'p2': 1});
    });

    test(
      'parentId null retire la désignation sans en poser d\'autre',
      () async {
        await reconciliationDao.applyEmergencyContactDesignation(
          studentId: 's1',
          parentId: 'p1',
        );

        await reconciliationDao.applyEmergencyContactDesignation(
          studentId: 's1',
          parentId: null,
        );

        expect(await designations(), {'p1': 0, 'p2': 0});
      },
    );

    /// Le drapeau décrit le couple (élève, tuteur) : désigner un adulte pour
    /// un enfant ne dit rien de ses frères et sœurs.
    test('ne touche pas aux autres élèves', () async {
      await db.insert('student_parent', {
        'student_id': 's2',
        'parent_id': 'p1',
        'relationship_type': 'OTHER',
        'emergency_contact': 1,
      });

      await reconciliationDao.applyEmergencyContactDesignation(
        studentId: 's1',
        parentId: null,
      );

      final other = await db.query(
        'student_parent',
        where: 'student_id = ?',
        whereArgs: ['s2'],
      );
      expect(other.single['emergency_contact'], 1);
    });
  });

  group('applyEnrollmentAck (F4 remap)', () {
    test('COMMITTED : matricule, parent provisoire→canonique (parents ET '
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
          student: ResponseStudent(id: 's1', matriculationNumber: 'MAT-0001'),
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
      // L'e-mail arrive dans la réponse et n'est PLUS recopié (ADR-015 F8) :
      // personne ne le relisait. L'attente s'inverse volontairement — la
      // colonne doit rester NULL alors même que le serveur a envoyé une valeur.
      expect(s['email'], isNull);
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

    test(
      'searchByAcademicInfo + filtre par statut (Première inscription)',
      () async {
        expect(
          await readDao.searchByAcademicInfo(status: 'IN_PROGRESS'),
          hasLength(1),
        );
        expect(
          await readDao.searchByAcademicInfo(status: 'COMPLETED'),
          isEmpty,
        );
      },
    );

    test('searchByAcademicInfo + filtre par type d\'inscription', () async {
      expect(
        await readDao.searchByAcademicInfo(enrollmentType: 'NEW_ENROLLMENT'),
        hasLength(1),
      );
      expect(
        await readDao.searchByAcademicInfo(enrollmentType: 'PRE_ENROLLMENT'),
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

  group('searchEnrolledByAcademicInfo (Facturation : élèves facturables)', () {
    // Force le `sync_status` d'un dossier existant (dossier remonté / en échec).
    Future<void> setSyncStatus(String enrollmentId, SyncState state) =>
        db.update(
          'enrollments',
          {'sync_status': state.dbValue},
          where: 'id = ?',
          whereArgs: [enrollmentId],
        );

    setUp(() async {
      // s1/e1 : dossier finalisé PENDING_SYNC (ay-2026, lvl-1).
      await seedPendingEnrollment(
        withStudent: student(id: 's1'),
        withEnrollment: enrollment(id: 'e1', studentId: 's1'),
      );
      // s3/e3 : dossier SYNCED (ay-2026, lvl-1).
      await draftDao.insertDraftStudent(student(id: 's3'));
      await draftDao.insertDraftEnrollment(
        enrollment(id: 'e3', studentId: 's3'),
      );
      await setSyncStatus('e3', SyncState.synced);
      // s4/e4 : dossier finalisé mais push en échec technique (SYNC_ERROR) —
      // reste facturable (repassera PENDING_SYNC au prochain envoi).
      await draftDao.insertDraftStudent(student(id: 's4'));
      await draftDao.insertDraftEnrollment(
        enrollment(id: 'e4', studentId: 's4'),
      );
      await setSyncStatus('e4', SyncState.syncError);
      // s2/e2 : brouillon DRAFT (ay-2026, lvl-1) — inscription NON finalisée.
      await draftDao.insertDraftStudent(student(id: 's2'));
      await draftDao.insertDraftEnrollment(
        enrollment(id: 'e2', studentId: 's2'),
      );
    });

    test('remonte les dossiers finalisés (SYNCED|PENDING_SYNC|SYNC_ERROR), '
        'exclut les DRAFT', () async {
      final rows = await readDao.searchEnrolledByAcademicInfo(
        academicYearId: 'ay-2026',
      );
      expect(
        rows.map((r) => r.studentId).toSet(),
        {'s1', 's3', 's4'},
        reason: 'SYNC_ERROR inclus (s4) ; brouillon DRAFT s2 exclu',
      );
    });

    test('scopé à l\'année demandée', () async {
      expect(
        await readDao.searchEnrolledByAcademicInfo(academicYearId: 'ay-1999'),
        isEmpty,
      );
    });

    test('borné au niveau quand fourni', () async {
      expect(
        await readDao.searchEnrolledByAcademicInfo(
          academicYearId: 'ay-2026',
          schoolLevelId: 'lvl-1',
        ),
        hasLength(3),
      );
      expect(
        await readDao.searchEnrolledByAcademicInfo(
          academicYearId: 'ay-2026',
          schoolLevelId: 'other',
        ),
        isEmpty,
      );
    });
  });

  group('niveau porté par la LIGNE (projection commune des listes)', () {
    Future<void> seedReferential() async {
      await db.insert('ref_school_level_groups', {
        'id': 'grp-1',
        'name': 'Primaire',
        'code': 'PRIM',
        'academic_year_id': 'ay-2026',
      });
      await db.insert('ref_school_levels', {
        'id': 'lvl-1',
        'name': '5ème année',
        'code': 'P5',
        'level_group_id': 'grp-1',
      });
    }

    test(
      'projette les ids ET les libellés résolus sur le référentiel',
      () async {
        await seedReferential();
        await seedPendingEnrollment(
          withEnrollment: const EnrollmentLocalModel(
            id: 'e1',
            studentId: 's1',
            enrollmentType: 'NEW_ENROLLMENT',
            status: 'IN_PROGRESS',
            academicYearId: 'ay-2026',
            schoolLevelId: 'lvl-1',
            schoolLevelGroupId: 'grp-1',
            enrollmentDate: '2026-07-06',
            updatedAt: 100,
          ),
        );

        final row = (await readDao.getEnrollments()).single;
        expect(row.schoolLevelId, 'lvl-1');
        expect(row.schoolLevelGroupId, 'grp-1');
        expect(row.schoolLevelName, '5ème année');
        expect(row.schoolLevelGroupName, 'Primaire');
      },
    );

    test(
      'référentiel pas encore descendu : la ligne SURVIT, id gardé, libellés null',
      () async {
        // Aucun `seedReferential()` : c'est l'état d'une tablette dont le pull
        // du référentiel n'a pas encore abouti. Une jointure interne ferait
        // disparaître le dossier de toutes les listes.
        await seedPendingEnrollment();

        final row = (await readDao.getEnrollments()).single;
        expect(row.schoolLevelId, 'lvl-1');
        expect(row.schoolLevelName, isNull);
        expect(
          row.schoolLevelGroupName,
          isNull,
          reason: 'un libellé absent ne vaut pas un niveau absent',
        );
      },
    );

    test(
      'inscription sans niveau (brouillon) : la ligne survit aussi',
      () async {
        await seedReferential();
        await draftDao.insertDraftStudent(student(id: 's9'));
        await draftDao.insertDraftEnrollment(
          const EnrollmentLocalModel(
            id: 'e9',
            studentId: 's9',
            enrollmentType: 'NEW_ENROLLMENT',
            status: 'IN_PROGRESS',
            academicYearId: 'ay-2026',
            enrollmentDate: '2026-07-06',
            updatedAt: 100,
          ),
        );

        final row = (await readDao.getEnrollments()).single;
        expect(row.enrollmentId, 'e9');
        expect(row.schoolLevelId, isNull);
        expect(row.schoolLevelName, isNull);
      },
    );

    test('la recherche Facturation porte le niveau elle aussi', () async {
      await seedReferential();
      await seedPendingEnrollment(
        withEnrollment: const EnrollmentLocalModel(
          id: 'e1',
          studentId: 's1',
          enrollmentType: 'NEW_ENROLLMENT',
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
          schoolLevelId: 'lvl-1',
          schoolLevelGroupId: 'grp-1',
          enrollmentDate: '2026-07-06',
          updatedAt: 100,
        ),
      );

      // Sans niveau dans les critères — le cas exact d'une recherche par
      // identité : la ligne doit quand même savoir dire son niveau.
      final rows = await readDao.searchEnrolledByAcademicInfo(
        academicYearId: 'ay-2026',
      );
      expect(rows.single.schoolLevelName, '5ème année');
    });
  });

  group('getEnrollments — filtre par type (anti-confusion pré-inscription / '
      'réinscription)', () {
    setUp(() async {
      // Le cœur du bug : DEUX brouillons AU MÊME statut métier PRE_REGISTERED
      // mais de TYPES différents — une vraie pré-inscription et une
      // réinscription. Sans filtre par type, la page Pré-inscriptions (qui
      // filtre par statut) afficherait aussi la réinscription.
      await draftDao.insertDraftStudent(student(id: 's-pre'));
      await draftDao.insertDraftStudent(student(id: 's-re'));
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

  group('studentEnrollmentDependency (gate 3-états, scopé année)', () {
    // ay-2026 = année par défaut du helper enrollment().
    const year = 'ay-2026';

    Future<void> setSyncStatus(String enrollmentId, SyncState state) =>
        db.update(
          'enrollments',
          {'sync_status': state.dbValue},
          where: 'id = ?',
          whereArgs: [enrollmentId],
        );

    Future<void> setYear(String enrollmentId, String academicYearId) =>
        db.update(
          'enrollments',
          {'academic_year_id': academicYearId},
          where: 'id = ?',
          whereArgs: [enrollmentId],
        );

    test('aucune inscription locale sur l\'année → ready', () async {
      expect(
        await readDao.studentEnrollmentDependency('unknown', year),
        OutboxDependencyState.ready,
      );
    });

    test('inscription PENDING_SYNC → waiting (attente propre)', () async {
      await seedPendingEnrollment(parents: [parent()]); // e1/s1 PENDING_SYNC
      expect(
        await readDao.studentEnrollmentDependency('s1', year),
        OutboxDependencyState.waiting,
      );
    });

    test('inscription DRAFT (wizard non finalisé) → waiting', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(enrollment()); // reste DRAFT
      expect(
        await readDao.studentEnrollmentDependency('s1', year),
        OutboxDependencyState.waiting,
      );
    });

    test('inscription SYNCED → ready', () async {
      await seedPendingEnrollment(parents: [parent()]);
      await ackDao.applyEnrollmentAck(
        const EnrollmentAggregateResponse(
          enrollment: ResponseEnrollment(id: 'e1'),
          student: ResponseStudent(id: 's1', matriculationNumber: 'MAT-1'),
        ),
        enrollmentId: 'e1',
        nowMs: 2000,
      );
      expect(
        await readDao.studentEnrollmentDependency('s1', year),
        OutboxDependencyState.ready,
      );
    });

    test('inscription SYNC_ERROR (même année) → parentFailed', () async {
      await seedPendingEnrollment(parents: [parent()]);
      await setSyncStatus('e1', SyncState.syncError);
      expect(
        await readDao.studentEnrollmentDependency('s1', year),
        OutboxDependencyState.parentFailed,
      );
    });

    test('SCOPE ANNÉE : une inscription d\'une AUTRE année en échec ne '
        'contamine pas l\'année courante', () async {
      // e1 ay-2026 SYNCED ; e2 ay-2027 SYNC_ERROR — même élève s1.
      await seedPendingEnrollment(parents: [parent()]);
      await setSyncStatus('e1', SyncState.synced);
      await draftDao.insertDraftEnrollment(
        enrollment(id: 'e2', studentId: 's1'),
      );
      await setYear('e2', 'ay-2027');
      await setSyncStatus('e2', SyncState.syncError);

      // Année courante isolée : le paiement 2026 part.
      expect(
        await readDao.studentEnrollmentDependency('s1', 'ay-2026'),
        OutboxDependencyState.ready,
      );
      // L'année réellement en échec, elle, bloque.
      expect(
        await readDao.studentEnrollmentDependency('s1', 'ay-2027'),
        OutboxDependencyState.parentFailed,
      );
      // Repli année nulle = niveau-élève (non scopé) : voit l'échec N+1.
      expect(
        await readDao.studentEnrollmentDependency('s1', null),
        OutboxDependencyState.parentFailed,
      );
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
      // Le filtre `status` (Première inscription, recherche par niveau visé)
      // ne doit JAMAIS exclure les brouillons DRAFT : c'est le statut MÉTIER
      // (IN_PROGRESS) qui est filtré, pas le `sync_status` technique.
      final draftByStatus = await readDao.searchByAcademicInfo(
        status: 'IN_PROGRESS',
        academicYearId: 'ay-2026',
      );
      expect(draftByStatus, hasLength(1));
      expect(draftByStatus.first.syncState, SyncState.draft);
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

    group(
      'replaceDraftParents avec enforcePhoneUniqueness (étape Tuteurs)',
      () {
        test(
          'téléphone en conflit avec un AUTRE parent (élève différent, saisie '
          'non liée) → ParentPhoneConflictException, transaction annulée',
          () async {
            await draftDao.insertDraftStudent(student(id: 's1'));
            await draftDao.replaceDraftParents(
              's1',
              [parent(id: 'p1', phone: '+243111')],
              nowMs: 200,
              enforcePhoneUniqueness: true,
            );

            await draftDao.insertDraftStudent(student(id: 's2'));
            await expectLater(
              () => draftDao.replaceDraftParents(
                's2',
                [
                  parent(
                    id: 'p2',
                    phone: '+243111',
                  ), // même téléphone, id différent
                ],
                nowMs: 300,
                enforcePhoneUniqueness: true,
              ),
              throwsA(isA<ParentPhoneConflictException>()),
            );

            // Rollback : aucun lien créé pour s2, aucune 2e ligne `parents`.
            expect(
              await db.query(
                'student_parent',
                where: 'student_id = ?',
                whereArgs: ['s2'],
              ),
              isEmpty,
            );
            expect(await db.query('parents'), hasLength(1));
          },
        );

        test('linkedToExisting: true réutilise la fiche existante sans la '
            'réécrire (rattachement explicite via la recherche)', () async {
          await draftDao.insertDraftStudent(student(id: 's1'));
          await draftDao.replaceDraftParents(
            's1',
            [parent(id: 'p1', phone: '+243111')],
            nowMs: 200,
            enforcePhoneUniqueness: true,
          );

          await draftDao.insertDraftStudent(student(id: 's2'));
          await draftDao.replaceDraftParents(
            's2',
            [
              const ParentDraft(
                parent: ParentLocalModel(
                  id: 'p1',
                  firstName: 'Nom local non transmis',
                  lastName: 'Ignoré',
                  phoneNumber: '+243111',
                  updatedAt: 300,
                ),
                relationshipType: 'FATHER',
                linkedToExisting: true,
              ),
            ],
            nowMs: 300,
            enforcePhoneUniqueness: true,
          );

          final p = await db.query(
            'parents',
            where: 'id = ?',
            whereArgs: ['p1'],
          );
          expect(p.single['first_name'], 'Sarah'); // fiche existante inchangée
          expect(await db.query('student_parent'), hasLength(2));
        });

        test(
          're-sauvegarde de la même ligne UI (même id, même téléphone) : pas '
          'de conflit, upsert par id',
          () async {
            await draftDao.insertDraftStudent(student(id: 's1'));
            await draftDao.replaceDraftParents(
              's1',
              [parent(id: 'p1', phone: '+243111')],
              nowMs: 200,
              enforcePhoneUniqueness: true,
            );

            await draftDao.replaceDraftParents(
              's1',
              [
                const ParentDraft(
                  parent: ParentLocalModel(
                    id: 'p1',
                    firstName: 'Sarah2',
                    lastName: 'Moke',
                    phoneNumber: '+243111',
                    updatedAt: 300,
                  ),
                  relationshipType: 'MOTHER',
                ),
              ],
              nowMs: 300,
              enforcePhoneUniqueness: true,
            );

            final p = await db.query('parents');
            expect(p, hasLength(1));
            expect(p.single['first_name'], 'Sarah2');
          },
        );

        test(
          'linkedToExisting: true MAIS la fiche a disparu (remap/suppression '
          'concurrente) → auto-guérison : recrée la fiche au lieu de laisser '
          'un lien orphelin silencieux',
          () async {
            await draftDao.insertDraftStudent(student(id: 's1'));
            // AUCUNE fiche 'p1' en base (simule une disparition entre la
            // sélection dans la popin et cette écriture — ex. remap d'ACK).
            await draftDao.replaceDraftParents(
              's1',
              [
                const ParentDraft(
                  parent: ParentLocalModel(
                    id: 'p1',
                    firstName: 'Sarah',
                    lastName: 'Moke',
                    phoneNumber: '+243111',
                    updatedAt: 300,
                  ),
                  relationshipType: 'MOTHER',
                  linkedToExisting: true,
                ),
              ],
              nowMs: 300,
              enforcePhoneUniqueness: true,
            );

            // La fiche est recréée (pas de perte silencieuse du tuteur) et le
            // lien student_parent est bien posé.
            final p = await db.query(
              'parents',
              where: 'id = ?',
              whereArgs: ['p1'],
            );
            expect(p, hasLength(1));
            expect(p.single['first_name'], 'Sarah');
            expect(await db.query('student_parent'), hasLength(1));
          },
        );

        test(
          'comparaison de téléphone normalisée : espaces/tirets/parenthèses '
          'ignorés (même numéro sous une autre mise en forme → conflit)',
          () async {
            await draftDao.insertDraftStudent(student(id: 's1'));
            await draftDao.replaceDraftParents(
              's1',
              [parent(id: 'p1', phone: '+243 111 222 333')],
              nowMs: 200,
              enforcePhoneUniqueness: true,
            );

            await draftDao.insertDraftStudent(student(id: 's2'));
            await expectLater(
              () => draftDao.replaceDraftParents(
                's2',
                [
                  parent(
                    id: 'p2',
                    phone: '+243-111-222-333',
                  ), // même numéro, mise en forme différente
                ],
                nowMs: 300,
                enforcePhoneUniqueness: true,
              ),
              throwsA(isA<ParentPhoneConflictException>()),
            );

            expect(await db.query('parents'), hasLength(1));
          },
        );

        test(
          'conflit INTRA-formulaire : deux tuteurs du MÊME appel partageant le '
          'même téléphone → le second lève ParentPhoneConflictException '
          '(lecture des propres écritures de la transaction)',
          () async {
            await draftDao.insertDraftStudent(student(id: 's1'));

            await expectLater(
              () => draftDao.replaceDraftParents(
                's1',
                [
                  parent(id: 'p1', phone: '+243111'),
                  parent(id: 'p2', phone: '+243111'), // même téléphone que p1
                ],
                nowMs: 200,
                enforcePhoneUniqueness: true,
              ),
              throwsA(isA<ParentPhoneConflictException>()),
            );

            // Transaction annulée : aucun des deux tuteurs n'est persisté.
            expect(await db.query('parents'), isEmpty);
            expect(await db.query('student_parent'), isEmpty);
          },
        );
      },
    );

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

    test('finalizeDraft avec finalStatus non-null écrit aussi la colonne '
        '`status`, ET le payload outbox porte le statut À JOUR (pas la valeur '
        'périmée lue avant la bascule)', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(enrollment()); // status IN_PROGRESS
      final ok = await draftDao.finalizeDraft(
        'e1',
        finalStatus: 'COMPLETED',
        nowMs: 1000,
      );
      expect(ok, isTrue);
      expect((await db.query('enrollments')).first['status'], 'COMPLETED');

      final ob = await db.query('outbox');
      final payload =
          jsonDecode(ob.first['payload'] as String) as Map<String, dynamic>;
      expect(
        (payload['enrollment'] as Map<String, dynamic>)['status'],
        'COMPLETED',
      );
    });

    test('finalizeDraft avec finalStatus null (défaut) ne touche pas `status` '
        '— non-régression NEW/RE', () async {
      await draftDao.insertDraftStudent(student());
      await draftDao.insertDraftEnrollment(enrollment()); // status IN_PROGRESS
      await draftDao.finalizeDraft('e1', nowMs: 1000);
      expect((await db.query('enrollments')).first['status'], 'IN_PROGRESS');
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
      status: 'IN_PROGRESS',
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

    test(
      'NON affecté par la garde d\'unicité de l\'étape Tuteurs : deux seeds '
      '(fratrie) partageant le même téléphone tuteur restent fusionnés '
      'silencieusement (upsertParentByPhone, comportement historique)',
      () async {
        await draftDao.seedDraft(
          student: seededStudent(),
          enrollment: seededEnrollment(),
          parents: [parent(id: 'p1', phone: '+243111')],
          nowMs: 100,
        );
        await draftDao.seedDraft(
          student: const StudentLocalModel(
            id: 's2',
            firstName: 'Awa',
            lastName: 'Moke',
            surname: 'Cadette',
            gender: 'FEMALE',
            dateOfBirth: '2017-04-02',
            birthPlace: 'Kinshasa',
            nationality: 'CD',
            city: 'Kinshasa',
            matriculationNumber: 'KIN-2025-0002',
            updatedAt: 100,
          ),
          enrollment: const EnrollmentLocalModel(
            id: 'e2',
            studentId: 's2',
            enrollmentType: 'RE_ENROLLMENT',
            status: 'IN_PROGRESS',
            academicYearId: 'ay-2026',
            schoolLevelId: 'lvl-1',
            enrollmentDate: '2026-07-08',
            sourceRef: 'KIN-2025-0002',
            updatedAt: 100,
          ),
          parents: [parent(id: 'p2', phone: '+243111')], // même téléphone
          nowMs: 200,
        );

        // Un seul parent en base : dédup fratrie silencieuse, aucune exception.
        expect(await db.query('parents'), hasLength(1));
        expect(await db.query('student_parent'), hasLength(2));
      },
    );

    test('dédup fratrie insensible au format : une fiche héritée '
        '("0816939060") et la saisie E.164 du jour ("+243816939060") sont le '
        'MÊME tuteur, pas un doublon', () async {
      await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: [parent(id: 'p1', phone: '0816939060')],
        nowMs: 100,
      );
      await draftDao.seedDraft(
        student: const StudentLocalModel(
          id: 's2',
          firstName: 'Awa',
          lastName: 'Moke',
          surname: 'Cadette',
          gender: 'FEMALE',
          dateOfBirth: '2017-04-02',
          birthPlace: 'Kinshasa',
          nationality: 'CD',
          city: 'Kinshasa',
          matriculationNumber: 'KIN-2025-0002',
          updatedAt: 100,
        ),
        enrollment: const EnrollmentLocalModel(
          id: 'e2',
          studentId: 's2',
          enrollmentType: 'RE_ENROLLMENT',
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
          schoolLevelId: 'lvl-1',
          enrollmentDate: '2026-07-08',
          sourceRef: 'KIN-2025-0002',
          updatedAt: 100,
        ),
        parents: [parent(id: 'p2', phone: '+243816939060')],
        nowMs: 200,
      );

      expect(await db.query('parents'), hasLength(1));
      expect(await db.query('student_parent'), hasLength(2));
    });

    test('deux pays voisins aux mêmes derniers chiffres restent DEUX tuteurs '
        '(+242 Brazzaville vs +243 Kinshasa)', () async {
      await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(),
        parents: [parent(id: 'p1', phone: '+243816939060')],
        nowMs: 100,
      );
      await draftDao.seedDraft(
        student: const StudentLocalModel(
          id: 's2',
          firstName: 'Awa',
          lastName: 'Ndala',
          surname: 'Cadette',
          gender: 'FEMALE',
          dateOfBirth: '2017-04-02',
          birthPlace: 'Kinshasa',
          nationality: 'CD',
          city: 'Kinshasa',
          matriculationNumber: 'KIN-2025-0002',
          updatedAt: 100,
        ),
        enrollment: const EnrollmentLocalModel(
          id: 'e2',
          studentId: 's2',
          enrollmentType: 'RE_ENROLLMENT',
          status: 'IN_PROGRESS',
          academicYearId: 'ay-2026',
          schoolLevelId: 'lvl-1',
          enrollmentDate: '2026-07-08',
          sourceRef: 'KIN-2025-0002',
          updatedAt: 100,
        ),
        parents: [parent(id: 'p2', phone: '+242816939060')],
        nowMs: 200,
      );

      // Fusionner les deux rattacherait un élève au parent d'un autre.
      expect(await db.query('parents'), hasLength(2));
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
          status: 'IN_PROGRESS',
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

    test('insertDraftEnrollment écrase enrollment_type/status SANS condition '
        '(pas de COALESCE, contrairement à school_level_id) — c\'est à '
        'l\'appelant de transmettre la bonne valeur', () async {
      await draftDao.seedDraft(
        student: seededStudent(),
        enrollment: seededEnrollment(), // RE_ENROLLMENT/IN_PROGRESS
        parents: const [],
        nowMs: 100,
      );

      await draftDao.insertDraftEnrollment(
        const EnrollmentLocalModel(
          id: 'e1',
          studentId: 's1',
          enrollmentType: 'PRE_ENROLLMENT',
          status: 'PRE_REGISTERED',
          academicYearId: 'ay-2026',
          enrollmentDate: '2026-07-08',
          updatedAt: 200,
        ),
      );

      final e = (await db.query('enrollments')).single;
      expect(e['enrollment_type'], 'PRE_ENROLLMENT');
      expect(e['status'], 'PRE_REGISTERED');
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
