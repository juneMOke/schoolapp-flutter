import 'package:school_app_flutter/core/database/table_schema.dart';

/// `attendance_justifications` — les justifications d'absence déposées par les
/// parents depuis le portail, et la décision de l'école.
///
/// **Miroir du flux `attendance.justifications`** pour les colonnes serveur
/// (`status`, `decided_*`, `decision_note`), que seul le pull et l'accusé
/// écrivent. La décision prise sur CETTE tablette vit à part, dans les
/// colonnes `local_*`, tant que le serveur ne l'a pas accusée : un pull qui
/// arrive entre-temps ne l'efface donc pas.
///
/// - `accept_blocked_code` : `NOT_AN_ABSENCE` ou `MONTH_CLOSED`, quand le
///   serveur a refusé l'acceptation. La demande reste en attente, et seul le
///   refus reste possible.
/// - `decided_elsewhere` : 1 quand une autre tablette a tranché autrement que
///   celle-ci ; l'écran le dit une fois la ligne affichée.
/// - La pièce n'est décrite que par ses métadonnées (`file_*`) : ses octets ne
///   se stockent jamais ici (certificat médical d'un mineur).
const TableSchema attendanceJustificationsTable = TableSchema(
  name: 'attendance_justifications',
  createTableSql: '''
    CREATE TABLE attendance_justifications (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      classroom_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      attendance_date TEXT NOT NULL,
      parent_id TEXT,
      reason TEXT NOT NULL,
      note TEXT,
      submitted_at TEXT,
      file_name TEXT,
      file_mime_type TEXT,
      file_size_bytes INTEGER,
      file_sha256 TEXT,
      status TEXT NOT NULL,
      decided_at TEXT,
      decided_by TEXT,
      decision_note TEXT,
      server_updated_at TEXT,
      local_gesture_id TEXT,
      local_decision TEXT,
      local_decision_note TEXT,
      local_decided_at INTEGER,
      accept_blocked_code TEXT,
      decided_elsewhere INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_attendance_justifications_status '
        'ON attendance_justifications(status, attendance_date)',
    'CREATE INDEX idx_attendance_justifications_day '
        'ON attendance_justifications(classroom_id, attendance_date)',
  ],
);

const List<TableSchema> attendanceJustificationTables = [
  attendanceJustificationsTable,
];
