import 'package:school_app_flutter/core/database/table_schema.dart';

/// `cote_classe_cache` — la structure d'une classe telle que le chargement l'a
/// rendue (calendrier, barème, élèves), en JSON : elle se lit d'un bloc et ne
/// se requête jamais. Une classe déjà ouverte se rouvre donc hors ligne.
const TableSchema coteClasseCacheTable = TableSchema(
  name: 'cote_classe_cache',
  createTableSql: '''
    CREATE TABLE cote_classe_cache (
      classroom_id TEXT PRIMARY KEY,
      structure_json TEXT NOT NULL,
      synced_at INTEGER NOT NULL
    )
  ''',
);

/// `cote_saisie` — une cellule de l'écran de saisie, cache et file d'envoi sur
/// la même ligne.
///
/// `server_cote`, `calculee` et `server_updated_at` sont ce que le serveur a dit
/// au dernier chargement. Le **brouillon** (`has_draft`, `draft_valeur`,
/// `draft_updated_at`) est la dernière saisie valide : `draft_valeur` nul avec
/// `has_draft` à 1 veut dire « cote vidée ». `sync_status` dit où il en est ;
/// `SYNC_ERROR` le garde : le serveur ne conserve pas une cote refusée, c'est
/// donc la seule trace de la valeur. `invalid_raw` est une frappe hors barème,
/// jamais envoyée. `author_id` borne l'envoi à son auteur, `''` sans identité.
///
/// Distincte de `ref_cote_cours` : celle-là se vide quand un cours quitte un
/// enseignant, et une éviction ne doit jamais emporter une écriture en attente.
const TableSchema coteSaisieTable = TableSchema(
  name: 'cote_saisie',
  createTableSql: '''
    CREATE TABLE cote_saisie (
      student_id TEXT NOT NULL,
      cours_id TEXT NOT NULL,
      colonne_id TEXT NOT NULL,
      classroom_id TEXT NOT NULL,
      examen INTEGER NOT NULL DEFAULT 0,
      server_cote REAL,
      calculee REAL,
      server_updated_at INTEGER,
      has_draft INTEGER NOT NULL DEFAULT 0,
      draft_valeur REAL,
      draft_updated_at INTEGER,
      invalid_raw TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      rejection_reason TEXT,
      author_id TEXT NOT NULL DEFAULT '',
      superseded_at INTEGER,
      PRIMARY KEY (student_id, cours_id, colonne_id)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_cote_saisie_classroom ON cote_saisie(classroom_id)',
    'CREATE INDEX idx_cote_saisie_sync ON cote_saisie(sync_status)',
  ],
);

/// `ref_cote_cours` — les cotes des cours d'un enseignant, en lecture seule
/// (flux `academics.cotes`). `valeur` nulle : la cote a été vidée, la tablette
/// revient à sa moyenne. `colonne_id` : une sous-période, ou la période d'un
/// examen.
const TableSchema refCoteCoursTable = TableSchema(
  name: 'ref_cote_cours',
  createTableSql: '''
    CREATE TABLE ref_cote_cours (
      student_id TEXT NOT NULL,
      cours_id TEXT NOT NULL,
      colonne_id TEXT NOT NULL,
      examen INTEGER NOT NULL DEFAULT 0,
      valeur REAL,
      updated_at INTEGER,
      PRIMARY KEY (student_id, cours_id, colonne_id)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_cote_cours ON ref_cote_cours(cours_id)',
  ],
);

/// Contribution de schéma de la saisie des notes, insérée dans
/// `buildOfflineSchema()`.
const List<TableSchema> coteSaisieTables = [
  coteClasseCacheTable,
  coteSaisieTable,
  refCoteCoursTable,
];
