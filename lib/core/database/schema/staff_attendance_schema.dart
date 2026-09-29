/// Tables du Pointage du personnel (module Ressources humaines, sous-module B).
///
/// Deux flux descendent (`hr.staff-attendance`, `hr.staff-attendance-locks`,
/// sous `hr.attendance.read`), trois écritures remontent : un pointage, un
/// geste de verrou, les réglages. Le module de présence des élèves n'est pas
/// touché : un agent n'est pas un élève.
library;

import 'package:school_app_flutter/core/database/table_schema.dart';

/// `staff_attendance_records` — un pointage par agent et par jour.
///
/// - `id` : uuid5 de (agent, `"attendance:" + jour`), le même sur toutes les
///   tablettes ; la ligne est unique par `(staff_member_id, work_date)`.
/// - `status` : `NONE` · `PRESENT` · `RETARD` · `ABSENT`. Effacer écrit `NONE`,
///   jamais une suppression.
/// - Heures `HH:mm` sans fuseau ; jour `YYYY-MM-DD`.
/// - `client_updated_at` : horloge d'arbitrage (ISO-8601 UTC), dernier écrit
///   gagne sur toute la ligne.
const TableSchema staffAttendanceRecordsTable = TableSchema(
  name: 'staff_attendance_records',
  createTableSql: '''
    CREATE TABLE staff_attendance_records (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      work_date TEXT NOT NULL,
      status TEXT NOT NULL,
      arrival_time TEXT,
      departure_time TEXT,
      late_minutes INTEGER NOT NULL DEFAULT 0,
      worked_minutes INTEGER,
      justification_reason TEXT,
      justification_note TEXT,
      client_updated_at TEXT NOT NULL,
      version INTEGER,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_staff_attendance_records_day '
        'ON staff_attendance_records(school_id, work_date)',
    'CREATE UNIQUE INDEX idx_staff_attendance_records_member_day '
        'ON staff_attendance_records(staff_member_id, work_date)',
  ],
);

/// `staff_attendance_locks` — l'état **serveur** d'un jour validé ou d'un mois
/// clos, tel que le flux ou un accusé l'a donné. Ce que la tablette a fait
/// depuis vit dans `staff_attendance_gestures`, et l'emporte à l'affichage
/// tant que ce n'est pas accusé.
const TableSchema staffAttendanceLocksTable = TableSchema(
  name: 'staff_attendance_locks',
  createTableSql: '''
    CREATE TABLE staff_attendance_locks (
      school_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      period_start TEXT NOT NULL,
      locked INTEGER NOT NULL DEFAULT 0,
      locked_at TEXT,
      locked_by_name TEXT,
      version INTEGER,
      server_updated_at TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, kind, period_start)
    )
  ''',
);

/// `staff_attendance_gestures` — les gestes de verrou posés sur la tablette
/// (`VALIDATE_DAY`, `REOPEN_DAY`, `CLOSE_MONTH`), un par ligne, jamais
/// fusionnés. `id` = le `gestureId`, clé d'idempotence côté serveur et id de
/// l'entrée d'outbox. Gardés après accusé : ils ordonnent les envois et disent
/// qui a validé avant la descente du flux.
const TableSchema staffAttendanceGesturesTable = TableSchema(
  name: 'staff_attendance_gestures',
  createTableSql: '''
    CREATE TABLE staff_attendance_gestures (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      period_start TEXT NOT NULL,
      gesture TEXT NOT NULL,
      recorded_at TEXT NOT NULL,
      author_name TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      sync_error_code TEXT,
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_staff_attendance_gestures_period '
        'ON staff_attendance_gestures(school_id, kind, period_start)',
  ],
);

/// `ref_staff_attendance_settings` — début des cours et tolérance, une ligne
/// par école. Descend avec le socle (section `staffAttendanceSettings`) ;
/// modifiée sur la tablette, elle remonte par la file (dernier écrit gagne) et
/// le socle ne l'écrase pas tant qu'elle n'est pas accusée. Absente = défauts.
const TableSchema refStaffAttendanceSettingsTable = TableSchema(
  name: 'ref_staff_attendance_settings',
  createTableSql: '''
    CREATE TABLE ref_staff_attendance_settings (
      school_id TEXT PRIMARY KEY,
      start_time TEXT NOT NULL,
      tolerance_minutes INTEGER NOT NULL,
      client_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
);

const List<TableSchema> staffAttendanceTables = [
  staffAttendanceRecordsTable,
  staffAttendanceLocksTable,
  staffAttendanceGesturesTable,
  refStaffAttendanceSettingsTable,
];
