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
