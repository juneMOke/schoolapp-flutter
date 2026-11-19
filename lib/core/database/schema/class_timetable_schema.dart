import 'package:school_app_flutter/core/database/table_schema.dart';

/// `tt_programmes` (v85) — le programme de chaque classe de l'année, bundle
/// `schedule.programmes` (ETag, remplacé en entier) sous `schedule.write` :
/// cours, branche (la clé de la copie), domaine et son ordre (la teinte),
/// enseignant, volume hebdomadaire (`null` = inconnu, B2).
const TableSchema ttProgrammesTable = TableSchema(
  name: 'tt_programmes',
  createTableSql: '''
    CREATE TABLE tt_programmes (
      cours_id TEXT PRIMARY KEY,
      classroom_id TEXT NOT NULL,
      branch_id TEXT NOT NULL,
      branch_label TEXT NOT NULL,
      domain_id TEXT,
      domain_label TEXT,
      domain_order INTEGER,
      teacher_id TEXT,
      teacher_label TEXT,
      weekly_hours INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_tt_programmes_classroom ON tt_programmes(classroom_id)',
  ],
);

/// `tt_class_timetables` (v85) — l'en-tête de l'emploi du temps d'une classe
/// (flux `schedule.timetables`) : version publiée, brouillon ouvert, révision.
const TableSchema ttClassTimetablesTable = TableSchema(
  name: 'tt_class_timetables',
  createTableSql: '''
    CREATE TABLE tt_class_timetables (
      id TEXT PRIMARY KEY,
      classroom_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      published_version INTEGER,
      published_at TEXT,
      published_by_name TEXT,
      published_by_role TEXT,
      draft_id TEXT,
      draft_updated_at TEXT,
      draft_updated_by_name TEXT,
      draft_updated_by_role TEXT,
      revision INTEGER NOT NULL DEFAULT 0,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_tt_class_timetables_classroom '
        'ON tt_class_timetables(classroom_id)',
  ],
);

/// `tt_cells` (v85) — les cases publiées et en brouillon de toutes les classes
/// (flux `schedule.timetable-cells`), et les gestes de brouillon faits sur
/// l'appareil (dernier écrit gagne par case, `client_updated_at`).
///
/// Une case nomme ses minutes et son enseignant : les conflits se calculent
/// sur l'appareil (A11). `id` est celui du serveur, stable pour (classe,
/// statut, brouillon, jour, créneau) ; une case posée ici, encore inconnue du
/// serveur, a un id local de même forme.
const TableSchema ttCellsTable = TableSchema(
  name: 'tt_cells',
  createTableSql: '''
    CREATE TABLE tt_cells (
      id TEXT PRIMARY KEY,
      classroom_id TEXT NOT NULL,
      classroom_label TEXT NOT NULL,
      status TEXT NOT NULL,
      draft_id TEXT,
      day TEXT NOT NULL,
      slot_id TEXT NOT NULL,
      start_minute INTEGER NOT NULL,
      end_minute INTEGER NOT NULL,
      cours_id TEXT,
      teacher_id TEXT,
      subject_label TEXT,
      teacher_label TEXT,
      client_updated_at INTEGER,
      server_updated_at INTEGER,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error_code TEXT,
      superseded_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_tt_cells_classroom ON tt_cells(classroom_id, status)',
    'CREATE INDEX idx_tt_cells_teacher ON tt_cells(teacher_id, day)',
  ],
);

const List<TableSchema> classTimetableTables = [
  ttProgrammesTable,
  ttClassTimetablesTable,
  ttCellsTable,
];
