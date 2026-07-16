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
    onUpgrade: (db, oldVersion, newVersion) =>
        migrateOfflineDatabase(db, oldVersion, schema),
  );
}

/// Étapes de migration idempotentes ordonnées, guardées par [oldVersion].
/// Extraite de `onUpgrade` pour être exerçable hors SQLCipher (tests ffi) :
/// le vrai opener est chiffré et non ouvrable en test.
Future<void> migrateOfflineDatabase(
  DatabaseExecutor db,
  int oldVersion,
  List<TableSchema> schema,
) async {
  if (oldVersion < 2) {
    // v2 — Inscription : ajout des tables de référence (cohorte RE,
    // préinscriptions, socle référentiel). On rejoue tout le schéma en
    // `IF NOT EXISTS` : les tables déjà présentes sont ignorées, seules les
    // nouvelles sont créées (aucune donnée existante n'est touchée).
    for (final table in schema) {
      await db.execute(_asIfNotExists(table.createTableSql));
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }
  if (oldVersion < 3) {
    // v3 — Inscription : `source_ref` sur `enrollments` (référence d'origine
    // du dossier, contrat agrégat : matricule RE / id de préinscription PRE).
    // Les bases v1/v2 ont déjà la table → ALTER.
    await db.execute('ALTER TABLE enrollments ADD COLUMN source_ref TEXT');
  }
}

/// Rend un `CREATE TABLE …` idempotent (`IF NOT EXISTS`) pour les migrations.
String _asIfNotExists(String createTableSql) =>
    createTableSql.replaceFirst('CREATE TABLE ', 'CREATE TABLE IF NOT EXISTS ');

/// Rend un `CREATE INDEX …` idempotent (`IF NOT EXISTS`) pour les migrations.
String _indexAsIfNotExists(String createIndexSql) =>
    createIndexSql.replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS ');
