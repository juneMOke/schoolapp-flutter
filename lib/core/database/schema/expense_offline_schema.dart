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
/// - `status` : les cinq états du circuit de validation (v2) — jamais saisi,
///   toujours le résultat d'un geste de décision.
/// - `decided_*`, `decision_reason`, `reminder_count` : la décision et la
///   pression du demandeur ; tout revient à zéro au retour en attente.
/// - `last_message_at` : fraîcheur du fil, **distincte** de
///   `client_updated_at` — un message ne doit jamais faire perdre une
///   décision à l'arbitrage (le défaut du module Discipline).
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
      updated_at INTEGER NOT NULL DEFAULT 0,
      -- Colonnes du circuit (v52), EN FIN DE TABLE : `ALTER TABLE` ne sait
      -- qu'ajouter à la fin, et une base montée doit finir identique à une
      -- base créée à neuf. Les déclarer ailleurs casse cet invariant, que le
      -- test de palier vérifie colonne par colonne, dans l'ordre.
      decided_by_id TEXT,
      decided_by_name TEXT,
      decided_at TEXT,
      decision_reason TEXT,
      reminder_count INTEGER NOT NULL DEFAULT 0,
      last_message_at TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_expenses_school_date '
        'ON expenses(school_id, expense_date)',
    'CREATE INDEX idx_expenses_sync ON expenses(sync_status)',
  ],
);

/// `expense_messages` — le fil d'une demande (v2, F30).
///
/// **Append-only** : on ajoute, on ne modifie ni ne supprime. Un geste de
/// décision y écrit son message, et c'est ce message qui porte l'ordre.
///
/// - `id` : uuid fabriqué par le poste. Clé d'idempotence du message **et du
///   geste** qui le porte (Q3) — un rejeu est inerte côté serveur.
/// - `act` : l'un des neuf actes anglais (F33) ; `NULL` = commentaire libre.
/// - `author_id` / `author_name` : l'identifiant pour juger la propriété
///   (F24), le nom pour l'afficher. Jamais le nom seul : deux Ilunga dans une
///   école suffisent à rendre la comparaison fausse.
/// - `created_at` : ISO-8601 UTC. **C'est lui qui ordonne la séquence** des
///   gestes d'une même dépense (F31), donc son format ne varie pas : deux
///   écritures de forme différente se compareraient de travers.
/// - `sync_status` : `PENDING_SYNC` tant que le serveur n'a pas accusé. Le
///   pull n'écrase jamais un message encore en attente, et c'est ce signal que
///   lira la garde d'ordre.
///
/// `body` SENSIBLE : un motif de refus nomme des fournisseurs et des
/// collègues. La base est chiffrée (SQLCipher), et aucun corps de message ne
/// part dans un journal.
const TableSchema expenseMessagesTable = TableSchema(
  name: 'expense_messages',
  createTableSql: '''
    CREATE TABLE expense_messages (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      expense_id TEXT NOT NULL,
      body TEXT NOT NULL,
      act TEXT,
      author_id TEXT,
      author_name TEXT,
      created_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC'
    )
  ''',
  createIndexSql: [
    // Il sert l'affichage du fil ET la garde d'ordre, qui cherche le plus
    // ancien message non synchronisé d'une dépense.
    'CREATE INDEX idx_expense_messages_thread '
        'ON expense_messages(expense_id, created_at)',
  ],
);

/// Tables du module Dépenses.
const List<TableSchema> expenseOfflineTables = [
  refExpenseTypesTable,
  expensesTable,
  expenseMessagesTable,
];
