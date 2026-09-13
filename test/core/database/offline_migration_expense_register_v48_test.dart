import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/expense/local/expense_type_local_model.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_read_dao.dart';
import 'package:school_app_flutter/features/expense/data/local/expense_type_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migration v48 — le registre des dépenses (`ref_expense_types`, `expenses`).
///
/// Palier de création pure : les tables naissent, elles servent vraiment (par
/// les DAO réels), rien d'autre n'est touché, et le palier est rejouable.
bool _ffiInitialized = false;

Future<Database> _openLegacyDb() async {
  if (!_ffiInitialized) {
    sqfliteFfiInit();
    _ffiInitialized = true;
  }
  return databaseFactoryFfi.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(singleInstance: false),
  );
}

void main() {
  late Database db;

  setUp(() async => db = await _openLegacyDb());
  tearDown(() async => db.close());

  Future<void> migrateFrom(int oldVersion) => migrateOfflineDatabase(
    db,
    oldVersion,
    buildOfflineSchema(),
    newVersion: 48,
  );

  Future<bool> hasTable(String name) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name = ?",
      [name],
    );
    return rows.isNotEmpty;
  }

  Future<List<String>> columnsOf(String table) async => [
    for (final row in await db.rawQuery('PRAGMA table_info($table)'))
      row['name'] as String,
  ];

  test('une base v47 reçoit les deux tables, et elles servent', () async {
    expect(await hasTable('expenses'), isFalse);

    await migrateFrom(47);

    final types = ExpenseTypeDao(db);
    await types.replaceForSchool([
      const ExpenseTypeLocalModel(
        id: 't-elec',
        schoolId: 'school-A',
        code: 'ELECTRICITE',
        label: 'Électricité & eau',
        shortLabel: 'Électricité',
        icon: 'power',
        color: '#D9A24E',
        softColor: '#FBF3E3',
        defaultCurrency: 'CDF',
      ),
    ], schoolId: 'school-A');
    expect((await types.typesForSchool('school-A')).single.code, 'ELECTRICITE');

    await db.insert('expenses', {
      'id': 'e-1',
      'school_id': 'school-A',
      'type_id': 't-elec',
      'title': 'Facture SNEL',
      'amount_in_cents': 38500000,
      'currency': 'CDF',
      'status': 'PAID',
      'expense_date': '2026-09-03',
      'client_updated_at': '2026-09-03T09:12:40.000Z',
    });
    final row = (await ExpenseReadDao(db).find('e-1'))!;
    expect(row.syncStatus, 'PENDING_SYNC', reason: 'défaut de colonne');
    expect(row.fundingSource, 'CASH');
  });

  test('les colonnes du palier sont celles du schéma vivant', () async {
    await migrateFrom(47);
    final migrated = await columnsOf('expenses');

    final fresh = await _openLegacyDb();
    addTearDown(fresh.close);
    final live = buildOfflineSchema().firstWhere((t) => t.name == 'expenses');
    await fresh.execute(live.createTableSql);
    final created = [
      for (final row in await fresh.rawQuery('PRAGMA table_info(expenses)'))
        row['name'] as String,
    ];

    // Une base montée et une base créée à neuf doivent avoir la même table :
    // sinon une colonne ajoutée à l'une manquerait à l'autre en production.
    expect(migrated, created);
  });

  test('le palier ne touche à rien d\'autre', () async {
    await db.execute(
      'CREATE TABLE payments (id TEXT PRIMARY KEY, amount INTEGER)',
    );
    await db.insert('payments', {'id': 'p-1', 'amount': 10});

    await migrateFrom(47);

    expect(await db.query('payments'), hasLength(1));
  });

  test('rejouable sur une base déjà en v48, sans rien perdre', () async {
    await migrateFrom(47);
    await db.insert('expenses', {
      'id': 'e-1',
      'school_id': 'school-A',
      'type_id': 't',
      'title': 'x',
      'amount_in_cents': 1,
      'currency': 'USD',
      'status': 'UNPAID',
      'expense_date': '2026-09-03',
      'client_updated_at': '2026-09-03T09:12:40.000Z',
    });

    await migrateFrom(48);

    expect(await db.query('expenses'), hasLength(1));
  });
}
