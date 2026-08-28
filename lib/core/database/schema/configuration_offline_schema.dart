import 'package:school_app_flutter/core/database/table_schema.dart';

/// Brouillon de mise en service — module Configuration.
///
/// **Ce n'est pas de la synchronisation, c'est de la reprise de saisie.** Le
/// module est 100 % en ligne : aucune outbox, aucun curseur de pull. Les étapes
/// 2 à 4 construisent un `ProvisioningRequest` que le serveur ne voit qu'en
/// simulation, et qu'une seule écriture — l'activation — transforme en données.
/// Entre deux ouvertures de l'application, ce brouillon doit survivre : sans
/// lui, un processus tué par Android effacerait le travail d'une demi-heure.
///
/// **Scopé `(school_id, user_id)`, et ce n'est pas décoratif.** La conception
/// « une tablette, une école » a déjà produit dix flux à curseur nu. Un
/// brouillon non scopé ferait reprendre l'assistant de l'école A dans la session
/// de l'école B — sur un objet dont l'aboutissement est une écriture
/// irréversible.
const TableSchema provisioningDraftTable = TableSchema(
  name: 'provisioning_drafts',
  createTableSql: '''
    CREATE TABLE provisioning_drafts (
      school_id TEXT NOT NULL,
      user_id TEXT NOT NULL,
      payload TEXT NOT NULL,
      step INTEGER NOT NULL DEFAULT 0,
      max_step INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (school_id, user_id)
    )
  ''',
);

/// Tables du module Configuration.
const List<TableSchema> configurationOfflineTables = [provisioningDraftTable];
