import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';
import 'package:school_app_flutter/core/database/table_schema.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Set<String> _names(List<TableSchema> schema) =>
    schema.map((t) => t.name).toSet();

/// Le partage appareil / école (MULTI_ECOLE_PLAN.md, option C). Ce que ces
/// tests tiennent n'est écrit nulle part ailleurs : une table rangée du mauvais
/// côté ne lèverait rien, elle ferait simplement coexister — ou séparer — ce
/// qui ne devait pas l'être.
void main() {
  sqfliteFfiInit();

  final full = buildOfflineSchema();
  final tenant = buildTenantSchema();
  final device = buildDeviceSchema();

  test('chaque table vit d un côté et d un seul — sync_meta excepté', () {
    final tenantNames = _names(tenant);
    final deviceNames = _names(device);

    expect(tenantNames.intersection(deviceNames), {'sync_meta'});
    expect(tenantNames.union(deviceNames), _names(full).union({'device_meta'}));
  });

  test('l outbox et les curseurs sont dans le fichier de l école : l écriture '
      'métier et son enfilage restent dans UNE transaction', () {
    expect(_names(tenant), containsAll(['outbox', 'sync_meta']));
    expect(_names(device), isNot(contains('outbox')));
  });

  test(
    'les comptes, la session et l index éditique vivent avec l appareil',
    () {
      expect(
        _names(device),
        containsAll([
          'auth_local_user',
          'auth_local_session',
          'editique_cache_entries',
          'device_meta',
        ]),
      );
      expect(_names(tenant), isNot(contains('auth_local_user')));
      expect(_names(tenant), isNot(contains('editique_cache_entries')));
    },
  );

  test('chaque table d appareil existe réellement : un renommage rendrait '
      'l exclusion muette et l enverrait chez l école', () {
    expect(_names(full), containsAll(kDeviceLevelTables));
  });

  test('aucune clé étrangère ne traverse la coupure', () {
    final reference = RegExp(
      r'REFERENCES\s+([a-z_0-9]+)',
      caseSensitive: false,
    );
    Set<String> referenced(List<TableSchema> schema) => {
      for (final t in schema)
        for (final m in reference.allMatches(t.createTableSql)) m.group(1)!,
    };

    expect(_names(tenant), containsAll(referenced(tenant)));
    expect(_names(device), containsAll(referenced(device)));
  });

  for (final entry in {'école': tenant, 'appareil': device}.entries) {
    test('le schéma ${entry.key} se matérialise sans erreur', () async {
      final db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(singleInstance: false),
      );
      addTearDown(db.close);
      await db.execute('PRAGMA foreign_keys = ON');
      for (final table in entry.value) {
        await db.execute(table.createTableSql);
        for (final indexSql in table.createIndexSql) {
          await db.execute(indexSql);
        }
      }
    });
  }
}
