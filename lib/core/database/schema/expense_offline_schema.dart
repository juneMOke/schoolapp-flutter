/// Tables du registre des dépenses (module Dépenses, plan `DEPENSES_PLAN.md`).
///
/// Deux familles : les **types**, référentiel de l'école remplacé à chaque
/// socle, et les **dépenses**, écrites sur le poste, poussées par l'outbox et
/// redescendues par un delta keyset — retraits compris.
///
/// **Aucune jointure vers Finances.** La source de fonds est enregistrée mais
/// ne débite aucune caisse en V1 : ces tables ne référencent ni `payments` ni
/// les tables de caisse, et rien ne les lit hors du module.
library;

import 'package:school_app_flutter/core/database/table_schema.dart';

/// `ref_expense_types` — les types de dépense de l'école (section
/// `expenseTypes` du socle), **masqués compris** : un type désactivé nomme
/// encore ses dépenses.
///
/// Présentation en données (libellés, icône, couleurs) : le poste ne code
/// aucune couleur de type en dur.
const TableSchema refExpenseTypesTable = TableSchema(
  name: 'ref_expense_types',
  createTableSql: '''
    CREATE TABLE ref_expense_types (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      code TEXT NOT NULL,
      label TEXT NOT NULL,
      short_label TEXT NOT NULL,
      icon TEXT NOT NULL,
      color TEXT NOT NULL,
      soft_color TEXT NOT NULL,
      default_currency TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      active INTEGER NOT NULL DEFAULT 1,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_expense_types_school '
        'ON ref_expense_types(school_id, sort_order)',
  ],
);

/// `expenses` — le registre.
///
/// - `expense_date` / `paid_on` : des **jours** `YYYY-MM-DD`, sans fuseau.
///   Les bornes de période se comparent en chaînes, jamais en instants.
/// - `amount_in_cents` : dans la devise d'engagement, francs compris ; jamais
///   converti.
/// - `client_updated_at` : horloge d'arbitrage du contenu (ISO-8601 UTC).
/// - `deleted_at` : retrait réversible (D4) ; `withdrawal_pending_at` porte
///   l'instant d'un retrait ou d'une restauration **pas encore accusés** —
///   tant qu'il est posé, ni le pull ni l'accusé d'un contenu ne touchent au
///   retrait.
/// - `server_deleted_at` : le retrait tel que le serveur l'a dit en dernier
///   (accusé ou pull). C'est l'état auquel revient un geste refusé : le
///   deviner depuis le geste lui-même se tromperait après « retirer puis
///   Annuler ».
/// - `expense_number` : `DEP-0412`, `NULL` tant que le serveur ne l'a pas
///   attribué (« en attente », A3).
const TableSchema expensesTable = TableSchema(
  name: 'expenses',
  createTableSql: '''
    CREATE TABLE expenses (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      expense_number TEXT,
      type_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      status TEXT NOT NULL,
      paid_on TEXT,
      expense_date TEXT NOT NULL,
      supplier TEXT,
      funding_source TEXT NOT NULL DEFAULT 'CASH',
      recorded_by_id TEXT,
      recorded_by_name TEXT,
      client_updated_at TEXT NOT NULL,
      deleted_at TEXT,
      server_deleted_at TEXT,
      withdrawal_pending_at TEXT,
      version INTEGER,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_expenses_school_date '
        'ON expenses(school_id, expense_date)',
    'CREATE INDEX idx_expenses_sync ON expenses(sync_status)',
  ],
);

/// Tables du module Dépenses.
const List<TableSchema> expenseOfflineTables = [
  refExpenseTypesTable,
  expensesTable,
];
