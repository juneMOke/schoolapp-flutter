import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v89 — la dépense **déclarée** et son visa.
///
/// La table naît ici avec le DDL de la **v88**, jamais avec le schéma
/// vivant : c'est ce qui permet au dernier test de prouver qu'une base montée
/// finit identique à une base créée à neuf.
const String _expensesV88 = '''
  CREATE TABLE expenses (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    expense_number TEXT,
    type_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    amount_in_cents INTEGER NOT NULL,
    currency TEXT NOT NULL,
    status TEXT NOT NULL,
    paid_on TEXT,
    expense_date TEXT NOT NULL,
    supplier TEXT,
    funding_source TEXT NOT NULL DEFAULT 'CASH',
    recorded_by_id TEXT,
    recorded_by_name TEXT,
    client_updated_at TEXT NOT NULL,
    deleted_at TEXT,
    server_deleted_at TEXT,
    withdrawal_pending_at TEXT,
    version INTEGER,
    server_updated_at TEXT,
    sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
    sync_error TEXT,
    sync_error_code TEXT,
    updated_at INTEGER NOT NULL DEFAULT 0,
    decided_by_id TEXT,
    decided_by_name TEXT,
    decided_at TEXT,
    decision_reason TEXT,
    reminder_count INTEGER NOT NULL DEFAULT 0,
    last_message_at TEXT,
    staff_advance TEXT
  )
''';

Future<Database> _openDb() => databaseFactoryFfi.openDatabase(
  inMemoryDatabasePath,
  options: OpenDatabaseOptions(singleInstance: false),
);

void main() {
  sqfliteFfiInit();

  late Database db;

  Future<List<String>> columnsOf(Database on, String table) async => [
    for (final row in await on.rawQuery('PRAGMA table_info($table)'))
      row['name'] as String,
  ];

  setUp(() async {
    db = await _openDb();
    await db.execute(_expensesV88);
    await db.insert('expenses', {
      'id': 'e-1',
      'school_id': 'school-A',
      'type_id': 't-elec',
      'title': 'Facture SNEL',
      'amount_in_cents': 38500000,
      'currency': 'CDF',
      'status': 'PAID',
      'paid_on': '2026-09-04',
      'expense_date': '2026-09-03',
      'client_updated_at': '2026-09-03T09:12:40.000Z',
    });
  });

  tearDown(() => db.close());

  test('une dépense existante devient une demande d’autorisation', () async {
    await migrateTenantDatabase(db, 88);

    final row = (await db.query('expenses')).single;
    expect(row['mode'], 'AUTHORIZATION');
    expect(row['visa_status'], isNull);
    expect(row['after_closure'], 0, reason: 'DEFAULT 0, jamais null');
    expect(row['voucher_id'], isNull);
    expect(row['paid_on'], '2026-09-04', reason: 'le contenu ne bouge pas');
  });

  test('rejouable : aucune colonne ajoutée deux fois', () async {
    await migrateTenantDatabase(db, 88);
    await migrateTenantDatabase(db, 88);

    final columns = await columnsOf(db, 'expenses');
    expect(columns.where((c) => c == 'mode'), hasLength(1));
    expect(await db.query('expenses'), hasLength(1));
  });

  test('une base sans registre traverse le palier sans lever', () async {
    final bare = await _openDb();
    addTearDown(bare.close);

    await expectLater(migrateTenantDatabase(bare, 88), completes);
  });

  test('une base montée et une base créée à neuf ont la même table', () async {
    await migrateTenantDatabase(db, 88);
    final migrated = await columnsOf(db, 'expenses');

    final fresh = await _openDb();
    addTearDown(fresh.close);
    final live = buildOfflineSchema().firstWhere((t) => t.name == 'expenses');
    await fresh.execute(live.createTableSql);

    expect(migrated, await columnsOf(fresh, 'expenses'));
  });

  test('le flux des dépenses repart de zéro, les autres non', () async {
    await db.execute(
      'CREATE TABLE sync_meta (resource TEXT PRIMARY KEY, cursor TEXT)',
    );
    for (final resource in ['expenses@school-A', 'expense_types', 'payments']) {
      await db.insert('sync_meta', {'resource': resource, 'cursor': 'c'});
    }

    await migrateTenantDatabase(db, 88);

    final left = [
      for (final row in await db.query('sync_meta')) row['resource'],
    ];
    expect(left, unorderedEquals(['expense_types', 'payments']));
  });
}
