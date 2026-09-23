import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v50 — la dépense devient une **demande** soumise à décision.
///
/// Un palier d'ajout de colonnes : elles naissent, la ligne existante les
/// porte, le renommage défensif des deux statuts de la V1 s'applique, et le
/// palier se rejoue sans dommage.
///
/// La table est créée ici avec le DDL de la **v49**, pas avec le schéma
/// vivant : une base montée doit finir identique à une base créée à neuf, et
/// c'est précisément ce que le dernier test vérifie.
const String _expensesV49 = '''
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
    updated_at INTEGER NOT NULL DEFAULT 0
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

  Future<void> seed(String id, String status, {String? paidOn}) =>
      db.insert('expenses', {
        'id': id,
        'school_id': 'school-A',
        'type_id': 't-elec',
        'title': 'Facture SNEL',
        'amount_in_cents': 38500000,
        'currency': 'CDF',
        'status': status,
        'paid_on': paidOn,
        'expense_date': '2026-09-03',
        'client_updated_at': '2026-09-03T09:12:40.000Z',
      });

  setUp(() async {
    db = await _openDb();
    await db.execute(_expensesV49);
  });

  tearDown(() => db.close());

  test('les six colonnes du circuit naissent, et la ligne les porte', () async {
    await seed('e-1', 'PAID', paidOn: '2026-09-04');

    await migrateTenantDatabase(db, 49);

    expect(
      await columnsOf(db, 'expenses'),
      containsAll([
        'decided_by_id',
        'decided_by_name',
        'decided_at',
        'decision_reason',
        'reminder_count',
        'last_message_at',
      ]),
    );
    final row = (await db.query('expenses')).single;
    expect(row['reminder_count'], 0, reason: 'DEFAULT 0, jamais null');
    expect(row['decided_at'], isNull);
    expect(row['paid_on'], '2026-09-04', reason: 'le contenu ne bouge pas');
  });

  test(
    'renommage défensif : UNPAID devient APPROVED, PAID ne bouge pas',
    () async {
      await seed('e-paid', 'PAID', paidOn: '2026-09-04');
      await seed('e-unpaid', 'UNPAID');

      await migrateTenantDatabase(db, 49);

      final byId = {
        for (final row in await db.query('expenses'))
          row['id'] as String: row['status'],
      };
      // `UNPAID` valait « engagée, reste à payer » : c'est l'approbation. La
      // verser en attente fabriquerait une file de retards qui n'ont pas eu lieu.
      expect(byId['e-unpaid'], 'APPROVED');
      expect(byId['e-paid'], 'PAID');
    },
  );

  test('rejouable sur une base déjà en v50, sans rien perdre', () async {
    await seed('e-1', 'UNPAID');

    await migrateTenantDatabase(db, 49);
    await migrateTenantDatabase(db, 49);

    expect(await db.query('expenses'), hasLength(1));
    final columns = await columnsOf(db, 'expenses');
    expect(
      columns.where((c) => c == 'reminder_count'),
      hasLength(1),
      reason: 'aucune colonne ajoutée deux fois',
    );
  });

  test(
    'une base sans registre des dépenses traverse le palier sans lever',
    () async {
      final bare = await _openDb();
      addTearDown(bare.close);

      await expectLater(migrateTenantDatabase(bare, 49), completes);
    },
  );

  test('une base montée et une base créée à neuf ont la même table', () async {
    await migrateTenantDatabase(db, 49);
    final migrated = await columnsOf(db, 'expenses');

    final fresh = await _openDb();
    addTearDown(fresh.close);
    final live = buildOfflineSchema().firstWhere((t) => t.name == 'expenses');
    await fresh.execute(live.createTableSql);

    // Sinon une colonne ajoutée à l'une manquerait à l'autre en production.
    expect(migrated, await columnsOf(fresh, 'expenses'));
  });
}
