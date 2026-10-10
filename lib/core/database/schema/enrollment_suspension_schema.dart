import 'package:school_app_flutter/core/database/table_schema.dart';

/// `enrollment_suspensions` — les périodes de désactivation d'un élève inscrit.
///
/// Miroir du flux `enrollment.suspensions` : une ligne par période, ouverte
/// tant que `reactivated_at` est nul. La période est un **fait daté** rattaché
/// à l'inscription de l'année, jamais un statut d'inscription : le dossier
/// reste `COMPLETED`.
///
/// `id` est l'uuid posé par la tablette qui a désactivé ; `reactivation_id`
/// celui de la tablette qui a réactivé. Les deux servent d'identifiant de
/// geste au serveur, qui rejoue un même id sans effet.
///
/// Le geste local en attente d'envoi vit sur la même ligne : `pending_op`
/// (`SUSPEND` | `REACTIVATE`, le dernier posé) et `sync_status` disent ce que
/// la tablette attend du serveur. Un refus garde sa raison dans `sync_error`.
///
/// Index unique partiel : une seule période ouverte par inscription, comme au
/// serveur.
const TableSchema enrollmentSuspensionsTable = TableSchema(
  name: 'enrollment_suspensions',
  createTableSql: '''
    CREATE TABLE enrollment_suspensions (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      enrollment_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      suspended_at TEXT NOT NULL,
      suspended_by TEXT,
      reason TEXT,
      precision TEXT,
      reactivation_id TEXT,
      reactivated_at TEXT,
      reactivated_by TEXT,
      server_updated_at TEXT,
      pending_op TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE UNIQUE INDEX idx_enrollment_suspensions_open '
        'ON enrollment_suspensions(enrollment_id) '
        'WHERE reactivated_at IS NULL',
    'CREATE INDEX idx_enrollment_suspensions_year '
        'ON enrollment_suspensions(school_id, academic_year_id)',
    'CREATE INDEX idx_enrollment_suspensions_student '
        'ON enrollment_suspensions(student_id)',
  ],
);

const List<TableSchema> enrollmentSuspensionTables = [
  enrollmentSuspensionsTable,
];
