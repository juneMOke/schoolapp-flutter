import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_database_opener.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Set<String>> _tables(Database db) async => {
  for (final row in await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  ))
    row['name']! as String,
};

/// Le palier v49 d'une base héritée adoptée : elle rend à l'appareil ses
/// tables, et garde tout le reste.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('PRAGMA foreign_keys = ON');
    await createOfflineSchema(db, buildOfflineSchema());

    await db.insert('auth_local_user', {
      'user_id': 'uid-a',
      'email': 'a@x.cd',
      'first_name': 'A',
      'last_name': 'A',
      'role': 'CASHIER',
      'school_id': 'A',
      'password_verifier': 'v',
      'verifier_salt': 's',
      'user_version': 1,
      'first_online_login_at': 1,
      'last_server_seen_at': 1,
    });
    await db.insert('auth_local_session', {
      'id': 1,
      'user_id': 'uid-a',
      'refresh_expires_at': 99,
      'last_evaluated_at': 1,
    });
    await db.insert('editique_cache_entries', {
      'id': 'e1',
      'document_id': 'doc-1',
      'doc_type': 'RC',
      'school_id': 'A',
      'size_bytes': 10,
      'created_at': 1,
      'last_accessed_at': 1,
    });
    for (final resource in [
      'editique_documents@A',
      'editique_cache_school',
      'enrollments',
    ]) {
      await db.insert('sync_meta', {'resource': resource, 'cursor': 'c'});
    }
    await db.insert('outbox', {
      'id': 'o1',
      'aggregate_type': 'PAYMENT',
      'aggregate_id': 'p1',
      'operation': 'create',
      'payload': '{}',
      'created_at': 1,
    });
  });

  tearDown(() => db.close());

  test('retire les tables de l appareil, session d abord malgré la clé '
      'étrangère', () async {
    await migrateTenantDatabase(db, 48);

    final tables = await _tables(db);
    expect(tables, isNot(contains('auth_local_user')));
    expect(tables, isNot(contains('auth_local_session')));
    expect(tables, isNot(contains('editique_cache_entries')));
  });

  test('les curseurs éditique partent avec l index ; ceux de l école '
      'restent', () async {
    await migrateTenantDatabase(db, 48);

    final resources = (await db.query(
      'sync_meta',
    )).map((r) => r['resource']).toList();
    expect(resources, ['enrollments']);
  });

  test('l outbox reste : ce sont les écritures de cette école', () async {
    await migrateTenantDatabase(db, 48);

    expect(await db.query('outbox'), hasLength(1));
  });

  test('rejouable sans dommage', () async {
    await migrateTenantDatabase(db, 48);
    await migrateTenantDatabase(db, 48);

    expect(await db.query('outbox'), hasLength(1));
  });

  group('v50 — le téléphone de la caisse', () {
    /// Une `ref_school` d'AVANT la v50 : le schéma vivant porte déjà la
    /// colonne, il faut donc la retirer pour exercer le palier.
    Future<void> seedSansColonne() async {
      await db.execute('DROP TABLE ref_school');
      await db.execute('''
        CREATE TABLE ref_school (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          phone TEXT,
          synced_at INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.insert('ref_school', {
        'id': 'A',
        'name': 'EP Kimbanguiste',
        'phone': '+243 000 000 000',
      });
    }

    Future<Set<String>> colonnes() async => {
      for (final r in await db.rawQuery('PRAGMA table_info(ref_school)'))
        r['name']! as String,
    };

    test('la colonne arrive, et la ligne existante survit', () async {
      await seedSansColonne();

      await migrateTenantDatabase(db, 49);

      expect(await colonnes(), contains('till_phone'));
      final row = (await db.query('ref_school')).single;
      expect(row['name'], 'EP Kimbanguiste');
      expect(row['phone'], '+243 000 000 000');
      // Aucune reprise : le référentiel est renvoyé en ENTIER à chaque pull,
      // donc la colonne se remplit d'elle-même au prochain cycle.
      expect(row['till_phone'], isNull);
    });

    /// SQLite refuse un `ADD COLUMN` sur une colonne existante, et une base
    /// héritée adoptée repasse par cet escalier.
    test('rejouable : la colonne déjà là ne fait pas lever', () async {
      await seedSansColonne();

      await migrateTenantDatabase(db, 49);
      await migrateTenantDatabase(db, 49);

      expect(await colonnes(), contains('till_phone'));
    });

    test('une base déjà en v50 n est pas touchée', () async {
      await db.insert('ref_school', {
        'id': 'A',
        'name': 'EP Kimbanguiste',
        'till_phone': '+243 811 111 111',
      });

      await migrateTenantDatabase(db, 50);

      final row = (await db.query('ref_school')).single;
      expect(row['till_phone'], '+243 811 111 111');
    });
  });

  group('v55 — le fichier du personnel', () {
    const tables = [
      'ref_staff_document_types',
      'staff_members',
      'staff_contracts',
      'staff_documents',
    ];

    Future<void> seedAvant() async {
      for (final table in tables) {
        await db.execute('DROP TABLE $table');
      }
    }

    test('les quatre tables arrivent, vides', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 54);

      expect(await _tables(db), containsAll(tables));
      for (final table in tables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
    });

    test('rejouable sans lever', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 54);
      await expectLater(migrateTenantDatabase(db, 54), completes);
    });

    test('une base montée et une base neuve ont les mêmes colonnes, '
        'dans le même ordre, et les mêmes index', () async {
      await seedAvant();
      await migrateTenantDatabase(db, 54);

      final fresh = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(fresh.close);
      await createOfflineSchema(fresh, buildOfflineSchema());

      Future<List<String>> of(Database d, String table) async => [
        for (final r in await d.rawQuery('PRAGMA table_info($table)'))
          r['name']! as String,
      ];
      for (final table in tables) {
        expect(await of(db, table), await of(fresh, table), reason: table);
      }

      Future<Set<String>> indexes(Database d) async => {
        for (final r in await d.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_staff%' AND name NOT LIKE 'idx_staff_attendance%'",
        ))
          r['name']! as String,
      };
      expect(await indexes(db), await indexes(fresh));
      expect(await indexes(db), hasLength(4));
    });
  });

  group('v58 — présences des élèves v2', () {
    Future<Set<String>> columns(String table) async => {
      for (final row in await db.rawQuery('PRAGMA table_info($table)'))
        row['name']! as String,
    };

    Future<void> seedAvant() async {
      for (final table in [
        'attendance_records',
        'attendance_sessions',
        'attendance_draft_marks',
        'attendance_month_closures',
      ]) {
        await db.execute('DROP TABLE $table');
      }
      // La forme d'avant la v58 : ni retard, ni réouverture.
      await db.execute('''
        CREATE TABLE attendance_sessions (
          id TEXT PRIMARY KEY, classroom_id TEXT NOT NULL,
          attendance_date TEXT NOT NULL, academic_year_id TEXT NOT NULL,
          expected_count INTEGER, taken_at INTEGER, taken_by TEXT,
          updated_at INTEGER NOT NULL, server_updated_at TEXT, version INTEGER,
          sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC', synced_at INTEGER,
          UNIQUE (classroom_id, attendance_date, academic_year_id))
      ''');
      await db.execute('''
        CREATE TABLE attendance_records (
          id TEXT PRIMARY KEY, session_id TEXT, student_id TEXT NOT NULL,
          student_first_name TEXT NOT NULL, student_last_name TEXT NOT NULL,
          student_middle_name TEXT,
          student_gender TEXT NOT NULL DEFAULT 'OTHER',
          classroom_id TEXT NOT NULL, attendance_date TEXT NOT NULL,
          academic_year_id TEXT NOT NULL,
          present INTEGER NOT NULL DEFAULT 1, absence_reason TEXT,
          absence_reason_note TEXT, version INTEGER,
          updated_at INTEGER NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC', synced_at INTEGER,
          UNIQUE (student_id, attendance_date, academic_year_id))
      ''');
      await db.insert('attendance_records', {
        'id': 'r-1',
        'student_id': 'st-1',
        'student_first_name': 'Grâce',
        'student_last_name': 'Mbuyi',
        'classroom_id': 'c-1',
        'attendance_date': '2026-09-29',
        'academic_year_id': 'y-1',
        'present': 0,
        'absence_reason': 'SICKNESS',
        'updated_at': 1,
      });
    }

    test(
      'les colonnes et les deux tables arrivent, sans toucher aux lignes',
      () async {
        await seedAvant();

        await migrateTenantDatabase(db, 57);
        await expectLater(migrateTenantDatabase(db, 57), completes);

        expect(
          await columns('attendance_records'),
          containsAll(['status', 'arrival_time', 'late_minutes']),
        );
        expect(await columns('attendance_sessions'), contains('reopened_at'));
        expect(
          await _tables(db),
          containsAll(['attendance_draft_marks', 'attendance_month_closures']),
        );
        final row = (await db.query('attendance_records')).single;
        expect(row['present'], 0);
        expect(row['status'], isNull);
        expect(row['absence_reason'], 'SICKNESS');
      },
    );

    test('une classe n a qu une clôture par mois', () async {
      Map<String, Object?> row(String id) => {
        'gesture_id': id,
        'classroom_id': 'c-1',
        'academic_year_id': 'y-1',
        'month': '2026-09',
      };
      await db.insert('attendance_month_closures', row('g-1'));

      await expectLater(
        db.insert('attendance_month_closures', row('g-2')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('v57 — la Paie du personnel', () {
    const tables = [
      'ref_payroll_settings',
      'staff_pay_profiles',
      'payrolls',
      'payroll_variables',
      'payroll_gestures',
      'payroll_lines',
      'staff_attendance_summaries',
      'salary_advances',
      'payroll_disbursements',
      'payroll_share_traces',
    ];

    Future<void> seedAvant() async {
      for (final table in tables) {
        await db.execute('DROP TABLE $table');
      }
    }

    test('les dix tables arrivent, vides, et le palier se rejoue', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 56);
      await expectLater(migrateTenantDatabase(db, 56), completes);

      expect(await _tables(db), containsAll(tables));
      for (final table in tables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
    });

    test('une école n a qu une paie par mois', () async {
      Map<String, Object?> row(String id) => {
        'id': id,
        'school_id': 's-1',
        'month': '2026-10',
        'status': 'DRAFT',
      };
      await db.insert('payrolls', row('p-1'));

      await expectLater(
        db.insert('payrolls', row('p-2')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('v56 — le Pointage du personnel', () {
    const tables = [
      'staff_attendance_records',
      'staff_attendance_locks',
      'staff_attendance_gestures',
      'ref_staff_attendance_settings',
    ];

    Future<void> seedAvant() async {
      for (final table in tables) {
        await db.execute('DROP TABLE $table');
      }
    }

    test('les quatre tables et leurs index arrivent, vides', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 55);

      expect(await _tables(db), containsAll(tables));
      for (final table in tables) {
        expect(await db.query(table), isEmpty, reason: table);
      }
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name LIKE 'idx_staff_attendance%'",
      );
      expect(indexes, hasLength(3));
    });

    test('rejouable sans lever, index unique compris', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 55);
      await expectLater(migrateTenantDatabase(db, 55), completes);
    });

    test('un agent n a qu un pointage par jour', () async {
      Map<String, Object?> row(String id) => {
        'id': id,
        'school_id': 's-1',
        'staff_member_id': 'm-1',
        'work_date': '2026-09-29',
        'status': 'PRESENT',
        'client_updated_at': '2026-09-29T08:00:00Z',
      };
      await db.insert('staff_attendance_records', row('r-1'));

      await expectLater(
        db.insert('staff_attendance_records', row('r-2')),
        throwsA(isA<DatabaseException>()),
      );
    });
  });

  group('v54 — la correction d un versement', () {
    Future<Set<String>> colonnes(String table) async => {
      for (final r in await db.rawQuery('PRAGMA table_info($table)'))
        r['name']! as String,
    };

    /// Une base d'AVANT la v54 : sans la table des corrections, et avec des
    /// `payments` sans le lien de remplacement.
    Future<void> seedAvant() async {
      await db.execute('DROP TABLE payment_corrections');
      await db.execute('DROP TABLE payments');
      await db.execute('''
        CREATE TABLE payments (
          id TEXT PRIMARY KEY,
          client_uuid TEXT NOT NULL,
          student_id TEXT NOT NULL,
          paid_at TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
          cancelled_at INTEGER
        )
      ''');
      await db.insert('payments', {
        'id': 'p-1',
        'client_uuid': 'p-1',
        'student_id': 's-1',
        'paid_at': '2026-09-25T13:11:41Z',
        'sync_status': 'SYNCED',
      });
    }

    test('la table et la colonne arrivent, le versement survit', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 53);

      expect(await _tables(db), contains('payment_corrections'));
      expect(
        await colonnes('payments'),
        containsAll([
          'replaces_payment_id',
          'cancelled_by_name',
          'cancellation_reason',
          'cancellation_reason_code',
          'cancellation_cash_moved',
        ]),
      );
      final row = (await db.query('payments')).single;
      expect(row['id'], 'p-1');
      // Aucune reprise : le lien se remplit par le geste ou par le pull.
      expect(row['replaces_payment_id'], isNull);
    });

    test('rejouable sans lever', () async {
      await seedAvant();

      await migrateTenantDatabase(db, 53);
      await migrateTenantDatabase(db, 53);

      expect(await colonnes('payments'), contains('replaces_payment_id'));
    });

    test('une base sans versements traverse le palier sans lever', () async {
      await db.execute('DROP TABLE payment_corrections');
      await db.execute('DROP TABLE payments');

      await expectLater(migrateTenantDatabase(db, 53), completes);
      expect(await _tables(db), contains('payment_corrections'));
    });

    test('une base montée et une base neuve ont les mêmes tables', () async {
      await seedAvant();
      await migrateTenantDatabase(db, 53);

      final fresh = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(fresh.close);
      await createOfflineSchema(fresh, buildOfflineSchema());

      Future<Set<String>> of(Database d, String table) async => {
        for (final r in await d.rawQuery('PRAGMA table_info($table)'))
          r['name']! as String,
      };
      expect(
        await of(db, 'payment_corrections'),
        await of(fresh, 'payment_corrections'),
      );
      // La table `payments` de départ est réduite : seules les colonnes du
      // palier se comparent.
      const added = {
        'replaces_payment_id',
        'cancelled_by_name',
        'cancellation_reason',
        'cancellation_reason_code',
        'cancellation_cash_moved',
      };
      expect(
        (await of(db, 'payments')).intersection(added),
        (await of(fresh, 'payments')).intersection(added),
      );
      expect((await of(fresh, 'payments')).containsAll(added), isTrue);

      Future<Set<String>> indexes(Database d) async => {
        for (final r in await d.rawQuery(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_payment%'",
        ))
          r['name']! as String,
      };
      expect(
        await indexes(db),
        containsAll([
          'idx_payment_corrections_payment',
          'idx_payment_corrections_replacement',
          'idx_payment_corrections_student',
          'idx_payments_replaces',
        ]),
      );
    });
  });

  group('v53 — les exemplaires par ticket', () {
    Future<Set<String>> colonnes() async => {
      for (final r in await db.rawQuery('PRAGMA table_info(ref_school)'))
        r['name']! as String,
    };

    /// Une `ref_school` d'AVANT la v53 : le schéma vivant porte déjà la
    /// colonne, il faut donc la retirer pour exercer le palier.
    Future<void> seedSansColonne() async {
      await db.execute('DROP TABLE ref_school');
      await db.execute('''
        CREATE TABLE ref_school (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          till_phone TEXT,
          synced_at INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.insert('ref_school', {
        'id': 'A',
        'name': 'EP Kimbanguiste',
        'till_phone': '+243 811 111 111',
      });
    }

    test('la colonne arrive, et la ligne existante survit', () async {
      await seedSansColonne();

      await migrateTenantDatabase(db, 52);

      expect(await colonnes(), contains('ticket_copies'));
      final row = (await db.query('ref_school')).single;
      expect(row['till_phone'], '+243 811 111 111');
      // Aucune reprise : le prochain pull la remplit.
      expect(row['ticket_copies'], isNull);
    });

    test('rejouable : la colonne déjà là ne fait pas lever', () async {
      await seedSansColonne();

      await migrateTenantDatabase(db, 52);
      await migrateTenantDatabase(db, 52);

      expect(await colonnes(), contains('ticket_copies'));
    });

    test('une base sans référentiel traverse le palier sans lever', () async {
      await db.execute('DROP TABLE ref_school');

      await expectLater(migrateTenantDatabase(db, 52), completes);
    });

    test(
      'une base montée et une base créée à neuf ont la même table',
      () async {
        await seedSansColonne();
        await migrateTenantDatabase(db, 52);

        // Le schéma vivant, lui, naît avec la colonne : les deux chemins
        // doivent aboutir au même endroit.
        final fresh = await databaseFactoryFfi.openDatabase(
          inMemoryDatabasePath,
          options: OpenDatabaseOptions(singleInstance: false),
        );
        addTearDown(fresh.close);
        await createOfflineSchema(fresh, buildOfflineSchema());
        final freshColumns = {
          for (final r in await fresh.rawQuery('PRAGMA table_info(ref_school)'))
            r['name']! as String,
        };
        expect(freshColumns, contains('ticket_copies'));
      },
    );
  });

  group('v51 — le matricule annuel', () {
    /// Une `enrollments` d'AVANT la v51 : le schéma vivant porte déjà la
    /// colonne, il faut donc la retirer pour exercer le palier.
    Future<void> seedSansColonne() async {
      await db.execute('DROP TABLE enrollments');
      await db.execute('''
        CREATE TABLE enrollments (
          id TEXT PRIMARY KEY,
          student_id TEXT NOT NULL,
          enrollment_type TEXT NOT NULL,
          status TEXT NOT NULL,
          academic_year_id TEXT NOT NULL,
          enrollment_date TEXT NOT NULL,
          sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
          updated_at INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.insert('enrollments', {
        'id': 'e1',
        'student_id': 'stu-1',
        'enrollment_type': 'NEW_ENROLLMENT',
        'status': 'COMPLETED',
        'academic_year_id': 'ay-1',
        'enrollment_date': '2026-07-01',
      });
    }

    Future<Set<String>> colonnes() async => {
      for (final r in await db.rawQuery('PRAGMA table_info(enrollments)'))
        r['name']! as String,
    };

    test('la colonne arrive, et la ligne existante survit', () async {
      await seedSansColonne();

      await migrateTenantDatabase(db, 50);

      expect(await colonnes(), contains('annual_matriculation_number'));
      final row = (await db.query('enrollments')).single;
      expect(row['student_id'], 'stu-1');
      // Aucune reprise : le champ se remplit par le pull, au fil des
      // inscriptions modifiées.
      expect(row['annual_matriculation_number'], isNull);
    });

    test('rejouable : la colonne déjà là ne fait pas lever', () async {
      await seedSansColonne();

      await migrateTenantDatabase(db, 50);
      await migrateTenantDatabase(db, 50);

      expect(await colonnes(), contains('annual_matriculation_number'));
    });

    test('une base déjà en v51 n est pas touchée', () async {
      await db.insert('enrollments', {
        'id': 'e1',
        'student_id': 'stu-1',
        'enrollment_type': 'NEW_ENROLLMENT',
        'status': 'COMPLETED',
        'academic_year_id': 'ay-1',
        'enrollment_date': '2026-07-01',
        'annual_matriculation_number': 'CF-P4-000018',
      });

      await migrateTenantDatabase(db, 51);

      final row = (await db.query('enrollments')).single;
      expect(row['annual_matriculation_number'], 'CF-P4-000018');
    });

    /// 🔴 Aucun index sur ce champ, délibérément : ce n'est pas une clé (la
    /// séquence repart à 1 chaque année), et en poser un inviterait à s'en
    /// servir pour chercher ou dédoublonner.
    test('aucun index ne le désigne', () async {
      final index = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type = 'index' "
        "AND tbl_name = 'enrollments'",
      );
      for (final r in index) {
        expect(
          (r['sql'] as String? ?? '').contains('annual_matriculation_number'),
          isFalse,
        );
      }
    });
  });
}
