import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:school_app_flutter/core/database/table_schema.dart';

/// Ouvre (et crée ou migre au besoin) un fichier de base local.
///
/// Un seam, pour une seule raison : le vrai ouvreur est chiffré (SQLCipher,
/// canal de plateforme) et ne s'ouvre pas en test. Les tests passent un ouvreur
/// ffi sur de VRAIS fichiers, et exercent ainsi l'éclatement, le renommage et
/// l'adoption tels qu'ils se passent sur une tablette.
typedef OfflineDatabaseOpener =
    Future<Database> Function(
      String path, {
      required String key,
      required int version,
      required OnDatabaseCreateFn onCreate,
      required OnDatabaseVersionChangeFn onUpgrade,
    });

/// L'ouvreur de production : SQLCipher, clés étrangères actives.
Future<Database> openSqlCipherDatabase(
  String path, {
  required String key,
  required int version,
  required OnDatabaseCreateFn onCreate,
  required OnDatabaseVersionChangeFn onUpgrade,
}) => sqlcipher.openDatabase(
  path,
  password: key,
  version: version,
  onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
  onCreate: onCreate,
  onUpgrade: onUpgrade,
);

/// Matérialise [schema] en un batch : le `onCreate` de tout fichier neuf.
Future<void> createOfflineSchema(Database db, List<TableSchema> schema) async {
  final batch = db.batch();
  for (final table in schema) {
    batch.execute(table.createTableSql);
    for (final indexSql in table.createIndexSql) {
      batch.execute(indexSql);
    }
  }
  await batch.commit(noResult: true);
}
