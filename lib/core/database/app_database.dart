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
  if (oldVersion < 4) {
    // v4 — Présence : passage au modèle SESSION-agrégat (contrat 1.2.0). La
    // racine d'agrégat `attendance_sessions` lève l'ambiguïté des 3 états, et
    // `attendance_records` gagne un lien logique `session_id`.
    await migrateAttendanceToSessionModel(db, schema);
  }
  if (oldVersion < 5) {
    // v5 — Classe : événement de transfert d'élève offline (régime A). Table
    // neuve, aucun backfill (aucun transfert passé n'était tracé — l'ancien
    // reassign online écrasait le miroir sans historique).
    final transfersTable = schema.firstWhere(
      (t) => t.name == 'classroom_transfers',
    );
    await db.execute(_asIfNotExists(transfersTable.createTableSql));
    for (final indexSql in transfersTable.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
  }
  if (oldVersion < 6) {
    // v6 — Discipline : agrégat {case, comments[]} (contrat 1.1.0). Table
    // `disciplinary_case_comments` append-only (régime A, uuid honoré) — table
    // neuve, aucun backfill (aucun commentaire passé n'était tracé). Colonne
    // `server_updated_at` sur `disciplinary_cases` : temps de visibilité serveur
    // (base du pull keyset, ADR-008) ; nullable, posée au pull/ACK.
    final commentsTable = schema.firstWhere(
      (t) => t.name == 'disciplinary_case_comments',
    );
    await db.execute(_asIfNotExists(commentsTable.createTableSql));
    for (final indexSql in commentsTable.createIndexSql) {
      await db.execute(_indexAsIfNotExists(indexSql));
    }
    if (await _hasTable(db, 'disciplinary_cases') &&
        !await _hasColumn(db, 'disciplinary_cases', 'server_updated_at')) {
      await db.execute(
        'ALTER TABLE disciplinary_cases ADD COLUMN server_updated_at INTEGER',
      );
    }
  }
  if (oldVersion < 7) {
    // v7 — Auth/session offline (ADR-010) : tables `auth_local_user` et
    // `auth_local_session`. Tables neuves, aucun backfill (aucune session
    // offline n'existait avant V1). Rejeu `IF NOT EXISTS` des contributions de
    // `authOfflineTables`.
    for (final name in const ['auth_local_user', 'auth_local_session']) {
      final table = schema.firstWhere((t) => t.name == name);
      await db.execute(_asIfNotExists(table.createTableSql));
      for (final indexSql in table.createIndexSql) {
        await db.execute(_indexAsIfNotExists(indexSql));
      }
    }
  }
}

/// Migration v4 (Présence) : matérialise `attendance_sessions` + `session_id`,
/// puis **backfille une session rétroactive** par appel legacy déjà en base.
///
/// Sans ce backfill, les `attendance_records` créés en v1..v3 deviendraient des
/// exceptions orphelines, invisibles au modèle des 3 états (« pas de session »
/// serait lu « appel non fait » alors qu'un appel a bien eu lieu). Les sessions
/// backfillées sont marquées `SYNCED` (l'appel a déjà eu lieu, la resync le
/// réalignera par clé naturelle) et leur `id` est un uuid v4 **généré en SQL**
/// (aucune dépendance Dart → migration exerçable en ffi hors SQLCipher).
///
/// Enfin, les entrées d'outbox `ATTENDANCE` au format full-write obsolète sont
/// purgées : leur payload n'est plus décodable par le handler agrégat (A3), les
/// laisser en ferait des poison-entries. La donnée reste dans `attendance_records`.
Future<void> migrateAttendanceToSessionModel(
  DatabaseExecutor db,
  List<TableSchema> schema,
) async {
  // Base antérieure à la Présence (aucun appel local) : rien à migrer. Les
  // tables seront matérialisées par `onCreate` / le rejeu de schéma `<2`.
  if (!await _hasTable(db, 'attendance_records')) return;

  final sessionsTable = schema.firstWhere(
    (t) => t.name == 'attendance_sessions',
  );
  await db.execute(_asIfNotExists(sessionsTable.createTableSql));
  for (final indexSql in sessionsTable.createIndexSql) {
    await db.execute(_indexAsIfNotExists(indexSql));
  }

  // `attendance_records` existe déjà (v1) → ajout de la colonne + son index.
  if (!await _hasColumn(db, 'attendance_records', 'session_id')) {
    await db.execute(
      'ALTER TABLE attendance_records ADD COLUMN session_id TEXT',
    );
  }
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_attendance_session '
    'ON attendance_records(session_id)',
  );

  // Backfill : une session SYNCED par (classe, date, année) distinct des records.
  // uuid v4 forgé en SQL pur (RFC 4122 : version 4, variant 8/9/a/b).
  await db.execute('''
    INSERT INTO attendance_sessions
      (id, classroom_id, attendance_date, academic_year_id,
       updated_at, sync_status, synced_at)
    SELECT
      lower(
        hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' ||
        substr(hex(randomblob(2)), 2) || '-' ||
        substr('89ab', abs(random()) % 4 + 1, 1) ||
        substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))
      ),
      classroom_id, attendance_date, academic_year_id,
      MAX(updated_at), 'SYNCED', MAX(updated_at)
    FROM attendance_records
    WHERE session_id IS NULL
    GROUP BY classroom_id, attendance_date, academic_year_id
  ''');
  await db.execute('''
    UPDATE attendance_records
    SET session_id = (
      SELECT s.id FROM attendance_sessions s
      WHERE s.classroom_id = attendance_records.classroom_id
        AND s.attendance_date = attendance_records.attendance_date
        AND s.academic_year_id = attendance_records.academic_year_id
    )
    WHERE session_id IS NULL
  ''');

  // Purge des poison-entries d'outbox au format full-write (pré-1.2.0).
  await db.delete('outbox', where: "aggregate_type = 'ATTENDANCE'");
}

/// Vrai si [column] existe déjà sur [table] (via `PRAGMA table_info`). Rend le
/// `ALTER … ADD COLUMN` idempotent (SQLite le refuse si la colonne est présente).
Future<bool> _hasColumn(
  DatabaseExecutor db,
  String table,
  String column,
) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  return info.any((row) => row['name'] == column);
}

/// Vrai si [table] existe dans la base (via `sqlite_master`).
Future<bool> _hasTable(DatabaseExecutor db, String table) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
    [table],
  );
  return rows.isNotEmpty;
}

/// Rend un `CREATE TABLE …` idempotent (`IF NOT EXISTS`) pour les migrations.
String _asIfNotExists(String createTableSql) =>
    createTableSql.replaceFirst('CREATE TABLE ', 'CREATE TABLE IF NOT EXISTS ');

/// Rend un `CREATE INDEX …` idempotent (`IF NOT EXISTS`) pour les migrations.
String _indexAsIfNotExists(String createIndexSql) =>
    createIndexSql.replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS ');
