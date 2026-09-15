import 'package:school_app_flutter/core/database/schema/academics_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/auth_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/boutique_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/classroom_attendance_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/configuration_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/editique_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/enrollment_finance_offline_schema.dart';
import 'package:school_app_flutter/core/database/schema/expense_offline_schema.dart';
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
      cursor TEXT,
      synced_at INTEGER
    )
  ''',
);

/// Tables du socle offline (indépendantes des modules métier).
const List<TableSchema> coreOfflineTables = [outboxTable, syncMetaTable];

/// Table `device_meta` — état propre à l'APPAREIL, en clé/valeur
/// (MULTI_ECOLE_PLAN.md, lot 2) : ce que l'éclatement par école a décidé de la
/// base héritée, et au nom de quelle école.
const TableSchema deviceMetaTable = TableSchema(
  name: 'device_meta',
  createTableSql: '''
    CREATE TABLE device_meta (
      key TEXT PRIMARY KEY,
      value TEXT
    )
  ''',
);

/// Tables qui vivent au niveau de l'APPAREIL (`device.db`) et non dans le
/// fichier d'une école. Voir `DeviceDatabase` pour la raison de chacune.
///
/// Une liste d'EXCLUSION, et c'est délibéré : une table de module neuve atterrit
/// d'office dans le fichier de l'école, sans que personne ait à y penser. Seul
/// ce qui appartient réellement au poste a besoin d'être nommé ici.
const Set<String> kDeviceLevelTables = {
  'auth_local_user',
  'auth_local_session',
  'editique_cache_entries',
};

/// Schéma d'un fichier d'école (`school_<id>.db`) : tout, sauf l'appareil.
///
/// `outbox` et `sync_meta` compris — l'écriture métier et son entrée d'outbox
/// restent ainsi dans UNE transaction, sur UN fichier.
List<TableSchema> buildTenantSchema() => buildOfflineSchema()
    .where((t) => !kDeviceLevelTables.contains(t.name))
    .toList(growable: false);

/// Schéma de `device.db`. `sync_meta` y figure aussi : les curseurs du
/// catalogue éditique vivent avec son index.
List<TableSchema> buildDeviceSchema() => [
  deviceMetaTable,
  syncMetaTable,
  ...buildOfflineSchema().where((t) => kDeviceLevelTables.contains(t.name)),
];

/// Schéma COMPLET — appareil et école réunis, sans `device_meta`.
///
/// C'est le schéma de la base unique d'avant l'éclatement par école : il sert
/// l'escalier de migration hérité (qui monte ce fichier jusqu'à la v48 avant
/// qu'une école l'adopte) et les bases de test mono-fichier. Aucun fichier de
/// production n'est plus créé avec lui.
///
/// Point d'extension additif des branches offline : chaque branche insère la
/// liste de ses tables ici (`...enrollmentFinanceOfflineTables`,
/// `...classroomAttendanceOfflineTables`). C'est le SEUL endroit du socle que
/// les branches éditent pour le schéma — conflit de merge réduit à cette liste.
List<TableSchema> buildOfflineSchema() => [
  ...coreOfflineTables,
  // ── branches offline : ajouter les tables de module ci-dessous ──
  ...authOfflineTables, // session offline (ADR-010 : user/verifier/session/clock)
  ...enrollmentFinanceOfflineTables, // branche A (Inscription + Facturation)
  ...classroomAttendanceOfflineTables, // branche B (Classe + Présence/Discipline)
  ...academicsOfflineTables, // Notes / Cours (academics + schedule, ADR-006)
  ...editiqueOfflineTables, // Éditique — index du cache de restitution (ADR-012)
  ...configurationOfflineTables, // Configuration — brouillon de mise en service
  ...boutiqueOfflineTables, // Boutique — caisse point-de-vente (ADR-020)
  ...expenseOfflineTables, // Dépenses — registre des frais de fonctionnement
];
