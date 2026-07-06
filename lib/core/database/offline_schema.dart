import 'package:school_app_flutter/core/database/table_schema.dart';

/// Table `outbox` — file d'écriture différée idempotente (socle).
const TableSchema outboxTable = TableSchema(
  name: 'outbox',
  createTableSql: '''
    CREATE TABLE outbox (
      id TEXT PRIMARY KEY,
      aggregate_type TEXT NOT NULL,
      aggregate_id TEXT NOT NULL,
      operation TEXT NOT NULL,
      payload TEXT NOT NULL,
      school_id TEXT,
      status TEXT NOT NULL DEFAULT 'PENDING',
      attempts INTEGER NOT NULL DEFAULT 0,
      created_at INTEGER NOT NULL,
      next_attempt_at INTEGER NOT NULL DEFAULT 0,
      last_error TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_outbox_status_created ON outbox(status, created_at)',
    'CREATE INDEX idx_outbox_aggregate ON outbox(aggregate_type, aggregate_id)',
  ],
);

/// Table `sync_meta` — curseurs de pull + fraîcheur par ressource (socle).
const TableSchema syncMetaTable = TableSchema(
  name: 'sync_meta',
  createTableSql: '''
    CREATE TABLE sync_meta (
      resource TEXT PRIMARY KEY,
      cursor INTEGER,
      synced_at INTEGER
    )
  ''',
);

/// Tables du socle offline (indépendantes des modules métier).
const List<TableSchema> coreOfflineTables = [outboxTable, syncMetaTable];

/// Schéma complet de la base locale, consommé par [openOfflineDatabase].
///
/// Point d'extension additif des branches offline : chaque branche insère la
/// liste de ses tables ici (`...enrollmentFinanceOfflineTables`,
/// `...classroomAttendanceOfflineTables`). C'est le SEUL endroit du socle que
/// les branches éditent pour le schéma — conflit de merge réduit à cette liste.
List<TableSchema> buildOfflineSchema() => [
  ...coreOfflineTables,
  // ── branches offline : ajouter les tables de module ci-dessous ──
];
