import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_dao.dart';
import 'package:school_app_flutter/core/offline/tombstone/tombstone_models.dart';

import '../offline_full_test_db.dart';

/// Ce que fait — et surtout ce que ne fait PAS — un retrait venu du serveur.
void main() {
  late Database db;
  late TombstoneDao dao;

  setUp(() async {
    db = await openFullOfflineDb();
    dao = TombstoneDao(db, SyncMetaDao(db));
  });

  tearDown(() async => db.close());

  Future<void> givenPayment(String id, {String status = 'SYNCED'}) async {
    await db.insert('payments', {
      'id': id,
      'client_uuid': id,
      'student_id': 'eleve-1',
      'paid_at': '2026-09-01T08:00:00Z',
      'sync_status': status,
      'updated_at': 0,
    });
    await db.insert('payment_allocations', {
      'id': 'alloc-$id',
      'client_uuid': 'alloc-$id',
      'payment_id': id,
      'fee_code': 'MINERVAL',
      'student_charge_label': 'Minerval',
      'amount_in_cents': 5000,
      'currency': 'USD',
    });
  }

  Future<int> countIn(String table) async =>
      ((await db.rawQuery('SELECT COUNT(*) AS n FROM $table')).first['n']
          as int?) ??
      0;

  group('Suppression', () {
    test('efface la ligne et ses filles', () async {
      await givenPayment('pay-1');

      final result = await dao.apply(const [
        TombstoneDto(
          resource: 'finance_payments',
          entityId: 'pay-1',
          reason: TombstoneReason.deleted,
        ),
      ]);

      expect(result.removed, 1);
      expect(await countIn('payments'), 0);
      // sqflite n'a pas de cascade : sans la purge explicite des imputations, la
      // caisse continuerait de les compter alors que leur versement n'existe plus.
      expect(await countIn('payment_allocations'), 0);
    });

    test(
      'DIFFÈRE le retrait d\'une ligne portant une écriture locale non poussée',
      () async {
        await givenPayment('pay-2', status: 'PENDING_SYNC');

        final result = await dao.apply(const [
          TombstoneDto(
            resource: 'finance_payments',
            entityId: 'pay-2',
            reason: TombstoneReason.deleted,
          ),
        ]);

        // L'effacer ferait disparaître un encaissement que personne n'a jamais
        // vu ailleurs. La pierre tombale est conservée par le serveur le temps
        // de la rétention : elle repassera.
        expect(result.deferred, 1);
        expect(result.removed, 0);
        expect(await countIn('payments'), 1);
      },
    );

    test(
      'une ressource inconnue de cette version est ignorée sans erreur',
      () async {
        final result = await dao.apply(const [
          TombstoneDto(
            resource: 'flux_du_futur',
            entityId: 'x',
            reason: TombstoneReason.deleted,
          ),
        ]);

        expect(result.removed, 0);
        expect(result.deferred, 0);
      },
    );

    test('un motif que ce client ne sait pas lire n\'efface rien', () async {
      await givenPayment('pay-3');

      final result = await dao.apply(const [
        TombstoneDto(
          resource: 'finance_payments',
          entityId: 'pay-3',
          reason: TombstoneReason.unknown,
        ),
      ]);

      expect(result.removed, 0);
      expect(await countIn('payments'), 1);
    });
  });

  group('Sortie de portée', () {
    Future<void> givenCours(String id, String teacherId) async {
      await db.insert('ref_cours', {
        'id': id,
        'classroom_id': 'classe-1',
        'ligne_bareme_id': 'bareme-1',
        'teacher_id': teacherId,
        'synced_at': 0,
      });
      await db.insert('evaluation', {
        'id': 'eval-$id',
        'cours_id': id,
        'type': 'INTERRO',
        'eval_date': 0,
        'max_points': 10.0,
        'poids': 1,
        'sync_status': 'SYNCED',
        'updated_at': 0,
      });
      await db.insert('note_evaluation', {
        'id': 'note-$id',
        'evaluation_id': 'eval-$id',
        'student_id': 'eleve-1',
        'statut': 'SAISIE',
        'sync_status': 'SYNCED',
        'updated_at': 0,
      });
    }

    test(
      'retire chez l\'ANCIEN porteur, et emporte évaluations et notes',
      () async {
        await givenCours('cours-1', 'prof-A');
        await SyncMetaDao(
          db,
        ).setCursor('academics_notes:cours-1', cursor: 'jeton', syncedAt: 1);

        final result = await dao.apply(const [
          TombstoneDto(
            resource: 'academics_cours',
            entityId: 'cours-1',
            scopeKey: 'prof-A',
            reason: TombstoneReason.outOfScope,
          ),
        ]);

        expect(result.removed, 1);
        expect(await countIn('ref_cours'), 0);
        expect(await countIn('evaluation'), 0);
        expect(await countIn('note_evaluation'), 0);
        // Sans cette purge, une réaffectation en retour reprendrait un curseur
        // périmé au lieu de rebootstraper.
        expect(
          await SyncMetaDao(db).getCursor('academics_notes:cours-1'),
          isNull,
        );
      },
    );

    test('n\'efface RIEN chez le nouveau porteur', () async {
      // Le cours est déjà redescendu chez B quand le retrait destiné à A arrive.
      await givenCours('cours-2', 'prof-B');

      final result = await dao.apply(const [
        TombstoneDto(
          resource: 'academics_cours',
          entityId: 'cours-2',
          scopeKey: 'prof-A',
          reason: TombstoneReason.outOfScope,
        ),
      ]);

      // C'est tout l'objet de l'appariement de portée : sans lui, le poste de B
      // effacerait le cours qu'il vient légitimement de recevoir.
      expect(result.removed, 0);
      expect(await countIn('ref_cours'), 1);
      expect(await countIn('evaluation'), 1);
    });

    test('un retrait conditionnel sans portée ne s\'applique pas', () async {
      await givenCours('cours-3', 'prof-A');

      final result = await dao.apply(const [
        TombstoneDto(
          resource: 'academics_cours',
          entityId: 'cours-3',
          reason: TombstoneReason.outOfScope,
        ),
      ]);

      expect(result.removed, 0);
      expect(await countIn('ref_cours'), 1);
    });
  });

  group('Portée implicite', () {
    test(
      'une préinscription convertie quitte le vivier, sans colonne à comparer',
      () async {
        await db.insert('ref_pre_enrollments', {
          'id': 'pre-1',
          'first_name': 'Amani',
          'last_name': 'Bora',
          'updated_at': 0,
          'synced_at': 0,
        });

        final result = await dao.apply(const [
          TombstoneDto(
            resource: 'enrollment_pre_enrollments',
            entityId: 'pre-1',
            scopeKey: 'PRE_ENROLLMENT',
            reason: TombstoneReason.outOfScope,
          ),
        ]);

        // La table n'accueille QUE des préinscriptions : la condition est déjà
        // vraie du seul fait d'y être. Exiger une colonne à comparer aurait fait
        // ignorer le seul événement pour lequel ce flux existe.
        expect(result.removed, 1);
        expect(await countIn('ref_pre_enrollments'), 0);
      },
    );
  });

  group('Réduction accordée', () {
    test(
      'le couple (inscription, code) désigne la ligne — les autres restent',
      () async {
        await db.insert('enrollment_reductions', {
          'enrollment_id': 'insc-1',
          'reduction_code': 'FRATRIE',
          'updated_at': 0,
        });
        await db.insert('enrollment_reductions', {
          'enrollment_id': 'insc-1',
          'reduction_code': 'PERSONNEL',
          'updated_at': 0,
        });

        final result = await dao.apply(const [
          TombstoneDto(
            resource: 'enrollment_reductions',
            entityId: 'insc-1',
            scopeKey: 'FRATRIE',
            reason: TombstoneReason.deleted,
          ),
        ]);

        // La table locale n'a pas la clé de substitution du serveur : sans le
        // couple, le retrait ne trouverait aucune cible — ou les emporterait toutes.
        expect(result.removed, 1);
        final left = await db.query('enrollment_reductions');
        expect(left, hasLength(1));
        expect(left.first['reduction_code'], 'PERSONNEL');
      },
    );
  });

  group('Lien parental', () {
    test(
      'le couple identifie le lien — les autres tuteurs sont conservés',
      () async {
        await db.insert('student_parent', {
          'student_id': 'eleve-1',
          'parent_id': 'parent-mere',
        });
        await db.insert('student_parent', {
          'student_id': 'eleve-1',
          'parent_id': 'parent-pere',
        });

        final result = await dao.apply(const [
          TombstoneDto(
            resource: 'student_parent',
            entityId: 'eleve-1',
            scopeKey: 'parent-mere',
            reason: TombstoneReason.deleted,
          ),
        ]);

        expect(result.removed, 1);
        // Effacer par le seul élève aurait emporté le second tuteur.
        final left = await db.query('student_parent');
        expect(left, hasLength(1));
        expect(left.first['parent_id'], 'parent-pere');
      },
    );
  });
}
