import 'package:school_app_flutter/core/database/table_schema.dart';

/// `treasury_closures` — les clôtures de caisse de l'école, descendues par le
/// flux `treasury.closures` (réouvertures comprises : une réouverture revient
/// comme une mise à jour de la même clôture, `reopened_at` posé).
///
/// La tablette n'en lit qu'une chose : la caisse d'une devise est-elle close
/// **aujourd'hui** ? Si oui, plus aucun encaissement en espèces dans cette
/// devise avant le lendemain (R11). Les montants ne sont pas gardés : l'écran
/// de clôture les lit en ligne.
///
/// `cash_day` : la journée de caisse, `yyyy-MM-dd`, telle que le serveur la
/// nomme (heure de l'école).
const TableSchema treasuryClosuresTable = TableSchema(
  name: 'treasury_closures',
  createTableSql: '''
    CREATE TABLE treasury_closures (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      register_id TEXT NOT NULL,
      currency TEXT NOT NULL,
      cash_day TEXT NOT NULL,
      closed_at TEXT NOT NULL,
      reopened_at TEXT,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_treasury_closures_day '
        'ON treasury_closures(school_id, cash_day, currency)',
  ],
);

const List<TableSchema> treasuryTables = [treasuryClosuresTable];
