import 'package:school_app_flutter/core/database/table_schema.dart';

/// `enrollment_level_corrections` — les corrections de niveau posées sur ce
/// poste, une ligne par geste.
///
/// **La ligne porte le geste, jamais son effet.** Tant que le serveur n'a pas
/// accusé, l'inscription, ses créances et son membre de classe restent ceux de
/// l'ancien niveau : c'est le serveur seul qui recalcule ce qui est dû, et le
/// guichet ne doit pas encaisser sur une grille provisoire (D7). Un refus n'a
/// donc rien à défaire : la ligne passe en échec, avec son code.
///
/// `sync_status` suit [RecordSyncState] : `PENDING_SYNC` tant que le geste
/// attend, `SYNCED` une fois accusé, `SYNC_ERROR` sur un refus 422 — dont le
/// code stable reste dans `sync_error_code` pour que l'écran le traduise.
///
/// Index unique partiel : une seule correction en attente par inscription. Une
/// seconde, posée sur la même copie, partirait avec un niveau de départ périmé
/// et tomberait en `STALE_LEVEL`.
const TableSchema enrollmentLevelCorrectionsTable = TableSchema(
  name: 'enrollment_level_corrections',
  createTableSql: '''
    CREATE TABLE enrollment_level_corrections (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      enrollment_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      from_school_level_id TEXT NOT NULL,
      to_school_level_id TEXT NOT NULL,
      to_school_level_group_id TEXT NOT NULL,
      to_classroom_id TEXT,
      reason TEXT NOT NULL,
      corrected_at TEXT NOT NULL,
      corrected_by TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      sync_error_code TEXT,
      acked_at INTEGER,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE UNIQUE INDEX idx_enrollment_level_corrections_pending '
        'ON enrollment_level_corrections(enrollment_id) '
        "WHERE sync_status = 'PENDING_SYNC'",
    'CREATE INDEX idx_enrollment_level_corrections_student '
        'ON enrollment_level_corrections(student_id, academic_year_id)',
  ],
);

const List<TableSchema> enrollmentLevelCorrectionTables = [
  enrollmentLevelCorrectionsTable,
];
