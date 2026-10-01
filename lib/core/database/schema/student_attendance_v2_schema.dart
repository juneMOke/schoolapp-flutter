import 'package:school_app_flutter/core/database/table_schema.dart';

/// `attendance_draft_marks` — l'appel en cours de saisie, **jamais envoyé**.
///
/// Chaque toucher du registre y écrit la marque d'un élève ; « Valider
/// l'appel » la transforme en session (agrégat envoyé) et vide le brouillon
/// du jour, dans la même transaction. Un brouillon ne compte dans aucune
/// statistique : tant qu'il n'est pas validé, l'appel n'est pas fait.
///
/// `status` ∈ `PRESENT`, `LATE`, `ABSENT` : un élève « à pointer » n'a pas de
/// ligne. Après une réouverture, la classe entière y est recopiée.
const TableSchema attendanceDraftMarksTable = TableSchema(
  name: 'attendance_draft_marks',
  createTableSql: '''
    CREATE TABLE attendance_draft_marks (
      classroom_id TEXT NOT NULL,
      attendance_date TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      status TEXT NOT NULL,
      arrival_time TEXT,
      late_minutes INTEGER,
      absence_reason TEXT,
      absence_reason_note TEXT,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (classroom_id, attendance_date, academic_year_id, student_id)
    )
  ''',
);

/// `attendance_month_closures` — la clôture d'un mois pour une classe.
///
/// Écrite à la clôture (`PENDING_SYNC`, une entrée d'outbox par geste,
/// `gesture_id` = id de l'entrée), puis accusée ou reçue par le pull
/// (`SYNCED`). Irréversible : un mois clos ne se rouvre pas. `month` =
/// `YYYY-MM`.
const TableSchema attendanceMonthClosuresTable = TableSchema(
  name: 'attendance_month_closures',
  createTableSql: '''
    CREATE TABLE attendance_month_closures (
      gesture_id TEXT PRIMARY KEY,
      classroom_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      month TEXT NOT NULL,
      closed_at TEXT,
      closed_by TEXT,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      UNIQUE (classroom_id, academic_year_id, month)
    )
  ''',
);

const List<TableSchema> studentAttendanceV2Tables = [
  attendanceDraftMarksTable,
  attendanceMonthClosuresTable,
];
