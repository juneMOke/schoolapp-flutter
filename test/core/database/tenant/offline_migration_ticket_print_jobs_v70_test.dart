import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v70 — les tickets à imprimer (continuité des tickets RC) : une table
/// neuve, rien à recopier. Les versements d'avant ne doivent aucun ticket.
void main() {
  sqfliteFfiInit();

  late Database db;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
  });
  tearDown(() => db.close());

  test('la table naît vide, unique par versement et par type', () async {
    await migrateTenantDatabase(db, 69, newVersion: 70);

    final columns = [
      for (final row in await db.rawQuery(
        'PRAGMA table_info(ticket_print_jobs)',
      ))
        row['name'] as String,
    ];
    expect(
      columns,
      containsAll([
        'id',
        'payment_id',
        'kind',
        'correction_id',
        'created_at',
        'printed_at',
        'last_problem',
      ]),
    );
    expect(await db.query('ticket_print_jobs'), isEmpty);

    await db.insert('ticket_print_jobs', {
      'id': 'j-1',
      'payment_id': 'p-1',
      'kind': 'receipt',
      'created_at': 1,
    });
    await expectLater(
      db.insert('ticket_print_jobs', {
        'id': 'j-2',
        'payment_id': 'p-1',
        'kind': 'receipt',
        'created_at': 2,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('un type inconnu est refusé', () async {
    await migrateTenantDatabase(db, 69, newVersion: 70);

    await expectLater(
      db.insert('ticket_print_jobs', {
        'id': 'j-1',
        'payment_id': 'p-1',
        'kind': 'invoice',
        'created_at': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('une base déjà en v70 ne la recrée pas', () async {
    await migrateTenantDatabase(db, 69, newVersion: 70);
    await db.insert('ticket_print_jobs', {
      'id': 'j-1',
      'payment_id': 'p-1',
      'kind': 'receipt',
      'created_at': 1,
    });

    await migrateTenantDatabase(db, 70, newVersion: 70);

    expect(await db.query('ticket_print_jobs'), hasLength(1));
  });
}
