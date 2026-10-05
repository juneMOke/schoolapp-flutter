import 'package:school_app_flutter/core/database/table_schema.dart';

/// `chapitre` — un chapitre du programme d'un cours, **fiche entière** :
/// les listes (objectifs, stratégies, blocs de contenu) vivent en JSON dans la
/// ligne, parce qu'elles partent toujours avec elle (dernier enregistrement
/// gagnant, sur la fiche complète).
///
/// - `server_known` : le serveur connaît ce chapitre (descendu, ou accusé
///   une fois). Tant qu'il vaut 0, ses notes, ses ressources, le geste
///   d'ordre et toute évaluation qui le cite attendent (`blocked`).
/// - `server_updated_at` nul sur une ligne connue du serveur : **ébauche**
///   recopiée de `ref_chapitre` à la v61, pas encore descendue — elle ne
///   s'édite pas, l'envoyer écraserait une fiche serveur que le poste n'a
///   jamais vue.
/// - `deleted_at` : la suppression attend son accusé ; la ligne est masquée.
const TableSchema chapitreTable = TableSchema(
  name: 'chapitre',
  createTableSql: '''
    CREATE TABLE chapitre (
      id TEXT PRIMARY KEY,
      cours_id TEXT NOT NULL,
      ordre INTEGER NOT NULL DEFAULT 0,
      titre TEXT NOT NULL,
      resume TEXT,
      statut TEXT NOT NULL DEFAULT 'PLANIFIE',
      seances INTEGER NOT NULL DEFAULT 4,
      sous_periode_id TEXT,
      objectifs_json TEXT NOT NULL DEFAULT '[]',
      strategies_json TEXT NOT NULL DEFAULT '[]',
      blocs_json TEXT NOT NULL DEFAULT '[]',
      client_updated_at TEXT,
      server_updated_at TEXT,
      server_known INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error_code TEXT,
      deleted_at TEXT,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_chapitre_cours ON chapitre(cours_id, ordre)',
  ],
);

/// `chapitre_note` — une note de séance. Insertion et suppression seulement,
/// jamais de modification. `cours_id` sert l'éviction d'un cours réaffecté.
const TableSchema chapitreNoteTable = TableSchema(
  name: 'chapitre_note',
  createTableSql: '''
    CREATE TABLE chapitre_note (
      id TEXT PRIMARY KEY,
      chapitre_id TEXT NOT NULL,
      cours_id TEXT NOT NULL,
      texte TEXT NOT NULL,
      ecrite_le TEXT NOT NULL,
      auteur TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error_code TEXT,
      deleted_at TEXT,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_chapitre_note_chapitre ON chapitre_note(chapitre_id)',
  ],
);

/// `chapitre_ressource` — la description d'une ressource (document, lien,
/// manuel). Les octets d'un document vivent dans le magasin chiffré du
/// programme, sous l'id de la ressource : à envoyer tant qu'elle attend,
/// copie de lecture ensuite (une ressource ne change jamais de contenu).
const TableSchema chapitreRessourceTable = TableSchema(
  name: 'chapitre_ressource',
  createTableSql: '''
    CREATE TABLE chapitre_ressource (
      id TEXT PRIMARY KEY,
      chapitre_id TEXT NOT NULL,
      cours_id TEXT NOT NULL,
      type TEXT NOT NULL,
      nom TEXT NOT NULL,
      url TEXT,
      reference TEXT,
      taille INTEGER,
      sha256 TEXT,
      mime_type TEXT,
      file_name TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error_code TEXT,
      deleted_at TEXT,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_chapitre_ressource_chapitre '
        'ON chapitre_ressource(chapitre_id)',
  ],
);

/// Le programme de cours (Cours ▸ Mes cours) — palier d'école v61.
const List<TableSchema> courseProgrammeTables = [
  chapitreTable,
  chapitreNoteTable,
  chapitreRessourceTable,
];
