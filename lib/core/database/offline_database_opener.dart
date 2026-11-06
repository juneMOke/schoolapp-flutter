import 'dart:io';

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

/// Existence d'un fichier de base. Un seam pour le navigateur, où une base
/// n'est pas un fichier et où `File.exists` lève.
typedef DatabaseExistsFn = Future<bool> Function(String path);

/// Existence sur disque : tablette et poste de bureau.
Future<bool> databaseFileExists(String path) => File(path).exists();

/// L'ouvreur de production : SQLCipher, clés étrangères actives.
///
/// Refuse d'ouvrir si le moteur lié n'est pas SQLCipher : voir
/// [ensureSqlCipherBuild].
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
  onConfigure: (db) async {
    await ensureSqlCipherBuild(db);
    await db.execute('PRAGMA foreign_keys = ON');
  },
  onCreate: onCreate,
  onUpgrade: onUpgrade,
);

/// Refuse d'ouvrir sur un SQLite ordinaire — le pendant mobile de la garde
/// `sqlite3mc_version()` du poste de bureau.
///
/// Le hook de `package:sqlite3` embarque SQLite3MultipleCiphers dans TOUS les
/// builds, tablette comprise, à côté du SQLCipher de `sqflite_sqlcipher`. Si
/// l'édition de liens résolvait les symboles `sqlite3_*` vers une autre
/// bibliothèque que SQLCipher (risque documenté par `sqflite_sqlcipher` sur
/// iOS), la clé serait ignorée SANS erreur et la base — grand-livre compris —
/// s'écrirait en clair.
///
/// `PRAGMA cipher_version` ne rend une valeur que sous SQLCipher ; tout autre
/// moteur ignore un pragma inconnu et ne rend aucune ligne. Le pragma ne lit
/// aucune page : une MAUVAISE clé n'est pas masquée ici, elle lève plus loin,
/// à la lecture de `user_version`, comme avant.
Future<void> ensureSqlCipherBuild(DatabaseExecutor db) async {
  final rows = await db.rawQuery('PRAGMA cipher_version');
  final version = rows.isEmpty ? null : rows.first.values.firstOrNull;
  if (version is String && version.trim().isNotEmpty) return;
  throw StateError(
    'SQLCipher absent : base non chiffrée (cipher_version vide)',
  );
}

/// Répertoire des bases de production.
Future<String> offlineDatabasesDirectory() => sqlcipher.getDatabasesPath();

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
