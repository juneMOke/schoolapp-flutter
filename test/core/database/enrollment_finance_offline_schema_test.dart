import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/database/schema/enrollment_finance_offline_schema.dart';

import '../../features/offline_full_db.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openFullOfflineDb();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Set<String>> tableNames() async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    return rows.map((r) => r['name'] as String).toSet();
  }

  test('toutes les tables de la branche + le socle sont créées', () async {
    final names = await tableNames();
    // Socle
    expect(names, containsAll(['outbox', 'sync_meta']));
    // Branche A
    expect(
      names,
      containsAll([
        'students',
        'parents',
        'student_parent',
        'enrollments',
        // Inscription — tables de référence (pull, lecture seule)
        'ref_school',
        'ref_academic_years',
        'ref_school_level_groups',
        'ref_school_levels',
        'ref_previous_year_students',
        'ref_pre_enrollments',
        'ref_fee_tariffs',
        'student_charges',
        'payments',
        'payment_allocations',
        'payment_anomalies',
        'generated_documents',
      ]),
    );
  });

  test('la liste exportée contient exactement 17 tables', () {
    // +1 en v33 : `ref_previous_year_student_balances`, les arriérés N-1 sortis
    // de la ligne de l'élève pour porter une entrée PAR DEVISE.
    expect(enrollmentFinanceOfflineTables, hasLength(17));
  });

  test(
    'index F2/FF1 présents (sync_status, client_uuid, phones tuteur…)',
    () async {
      final rows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );
      final indexes = rows.map((r) => r['name'] as String).toSet();
      expect(
        indexes,
        containsAll([
          'idx_enrollments_sync_status',
          'idx_parents_phone',
          'idx_parents_names',
          'idx_student_charges_student_fee',
          'idx_payments_client_uuid',
          // Tables de référence Inscription (RE/PRE)
          'idx_ref_previous_year_students_matricule',
          'idx_ref_pre_enrollments_phone',
        ]),
      );
      // `idx_students_phone` a été retiré en v27 : il indexait une colonne
      // qu'aucune requête n'interrogeait — du coût d'écriture pur à chaque élève.
      // L'absence est affirmée, pas seulement non-testée : un index n'emporte
      // aucune donnée, mais son retour signalerait qu'une écriture a été
      // rebranchée — personne n'indexe une colonne toujours NULL.
      expect(indexes, isNot(contains('idx_students_phone')));
      // Les téléphones TUTEUR restent indexés : eux servent, ce sont les clés
      // d'unicité applicative du rapprochement RE/PRE.
      expect(
        indexes,
        containsAll(['idx_parents_phone', 'idx_ref_pre_enrollments_phone']),
      );
    },
  );

  test(
    'cohorte RE : ref_previous_year_students round-trip (student_id)',
    () async {
      await db.insert('ref_previous_year_students', {
        'student_id': 'stu-N1',
        'matriculation_number': 'ETL-2024-0042',
        'first_name': 'Awa',
        'last_name': 'Kone',
        'surname': 'M',
        'gender': 'FEMALE',
        'date_of_birth': '2013-05-02',
        'previous_school_level_id': 'lvl-6e',
        'synced_at': 0,
      });
      final rows = await db.query(
        'ref_previous_year_students',
        where: 'student_id = ?',
        whereArgs: ['stu-N1'],
      );
      expect(rows, hasLength(1));
      // student_id est la clé canonique réutilisée par le nouvel enrollment (RE).
      expect(rows.first['student_id'], 'stu-N1');
      expect(rows.first['matriculation_number'], 'ETL-2024-0042');
    },
  );

  test('les arriérés N-1 portent UNE LIGNE PAR DEVISE', () async {
    // La colonne scalaire étiquetait la somme de tous les postes avec la devise
    // du premier : 425,00 $ et 90 000 FC s'annonçaient « 90 425,00 $ ».
    for (final row in const [
      {'student_id': 'stu-N1', 'currency': 'USD', 'amount_in_cents': 42500},
      {'student_id': 'stu-N1', 'currency': 'CDF', 'amount_in_cents': 9000000},
    ]) {
      await db.insert('ref_previous_year_student_balances', row);
    }

    final rows = await db.query(
      'ref_previous_year_student_balances',
      where: 'student_id = ?',
      whereArgs: ['stu-N1'],
      orderBy: 'currency',
    );

    expect(rows, hasLength(2));
    expect(rows.first['currency'], 'CDF');
    // Argent en INTEGER centimes (jamais de flottant).
    expect(rows.first['amount_in_cents'], isA<int>());
    expect(rows.last['amount_in_cents'], 42500);
  });

  test('une devise ne peut figurer deux fois pour le même élève', () async {
    await db.insert('ref_previous_year_student_balances', {
      'student_id': 'stu-N1',
      'currency': 'USD',
      'amount_in_cents': 42500,
    });

    expect(
      () => db.insert('ref_previous_year_student_balances', {
        'student_id': 'stu-N1',
        'currency': 'USD',
        'amount_in_cents': 999,
      }),
      throwsA(anything),
    );
  });

  test('montants en INTEGER centimes : round-trip sans flottant', () async {
    await db.insert('ref_fee_tariffs', {
      'id': 't1',
      'fee_code': 'TUITION',
      'label': 'Scolarité',
      'amount_in_cents': 1500000,
      'currency': 'USD',
      'school_level_id': 'lvl-1',
    });
    final rows = await db.query(
      'ref_fee_tariffs',
      where: 'id = ?',
      whereArgs: ['t1'],
    );
    expect(rows.first['amount_in_cents'], isA<int>());
    expect(rows.first['amount_in_cents'], 1500000);
  });
}
