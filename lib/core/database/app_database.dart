import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/table_schema.dart';

/// Ouvre (et crée/migre au besoin) la base locale chiffrée SQLCipher.
///
/// - [dbKey] : clé de chiffrement (256 bits hex) fournie par [DatabaseKeyService].
/// - [schema] : contributions de tables agrégées (`buildOfflineSchema()`).
///
/// `onCreate` matérialise tout le schéma en un batch (greenfield V1). Les bumps
/// futurs de [AppConstants.offlineDbSchemaVersion] ajoutent des étapes ordonnées
/// dans `onUpgrade`.
Future<Database> openOfflineDatabase({
  required String dbKey,
  required List<TableSchema> schema,
  String dbName = AppConstants.offlineDbName,
  int version = AppConstants.offlineDbSchemaVersion,
}) async {
  final databasesPath = await sqlcipher.getDatabasesPath();
  final path = p.join(databasesPath, dbName);

  return sqlcipher.openDatabase(
    path,
    password: dbKey,
    version: version,
    onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    },
    onCreate: (db, _) async {
      final batch = db.batch();
      for (final table in schema) {
        batch.execute(table.createTableSql);
        for (final indexSql in table.createIndexSql) {
          batch.execute(indexSql);
        }
      }
      await batch.commit(noResult: true);
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      // V1 greenfield : aucune migration incrémentale pour l'instant.
      // Les futures versions ajoutent ici des étapes idempotentes ordonnées
      // (guardées par oldVersion), sur le modèle de BootstrapLocalMigrationService.
    },
  );
}
