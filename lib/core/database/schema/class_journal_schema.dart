import 'package:school_app_flutter/core/database/table_schema.dart';

/// `journal_seance` — le journal de classe : ce qui a été fait à une séance
/// datée, une ligne par (cours, jour, créneau).
///
/// - `id` : uuid5 de (cours, `journal:AAAA-MM-JJ:<créneau>`), le même sur
///   toutes les tablettes et au serveur (`JournalIds`).
/// - `date_seance` : jour civil `AAAA-MM-JJ`, jamais un instant.
/// - `time_slot_id` : créneau du module emploi du temps, sans clé étrangère.
/// - `chapitre_id` nul : séance hors programme.
/// - Une ligne ne se supprime pas : vider une séance écrit ses sept champs
///   vides. Elle part avec son cours (éviction, cours retiré).
const TableSchema journalSeanceTable = TableSchema(
  name: 'journal_seance',
  createTableSql: '''
    CREATE TABLE journal_seance (
      id TEXT PRIMARY KEY,
      cours_id TEXT NOT NULL,
      date_seance TEXT NOT NULL,
      time_slot_id TEXT NOT NULL,
      chapitre_id TEXT,
      cb TEXT NOT NULL DEFAULT '',
      objectif TEXT NOT NULL DEFAULT '',
      contenu TEXT NOT NULL DEFAULT '',
      strategie TEXT NOT NULL DEFAULT '',
      ressources TEXT NOT NULL DEFAULT '',
      evaluation TEXT NOT NULL DEFAULT '',
      observation TEXT NOT NULL DEFAULT '',
      client_updated_at TEXT,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_journal_seance_cours '
        'ON journal_seance(cours_id, date_seance)',
  ],
);

/// Le journal de classe (Cours ▸ Mon journal) — palier d'école v64.
const List<TableSchema> classJournalTables = [journalSeanceTable];
