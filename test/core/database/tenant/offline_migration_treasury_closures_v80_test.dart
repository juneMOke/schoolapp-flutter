import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/tenant/tenant_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Palier v80 — les clôtures de caisse descendues (`treasury.closures`) : une
/// table neuve, remplie par le flux. Rien à recopier : avant ce palier, aucune
/// caisse n'était close sur la tablette.
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

  test('la table naît vide, avec ce que lit le verrou', () async {
    await migrateTenantDatabase(db, 79, newVersion: 80);

    final columns = [
      for (final row in await db.rawQuery(
        'PRAGMA table_info(treasury_closures)',
      ))
        row['name'] as String,
    ];
    expect(
      columns,
      containsAll([
        'id',
        'school_id',
        'register_id',
        'currency',
        'cash_day',
        'closed_at',
        'reopened_at',
        'synced_at',
      ]),
    );
    expect(await db.query('treasury_closures'), isEmpty);
  });

  test('rejouer le palier ne casse rien', () async {
    await migrateTenantDatabase(db, 79, newVersion: 80);
    await migrateTenantDatabase(db, 79, newVersion: 80);
    expect(await db.query('treasury_closures'), isEmpty);
  });
}
