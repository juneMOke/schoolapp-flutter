import 'package:school_app_flutter/core/database/table_schema.dart';

/// `evaluation_depot` — la copie qu'un parent a déposée pour un devoir en
/// ligne (portail parent, V180). Fille de `evaluation`.
///
/// **Miroir pur** : elle descend imbriquée dans le pull des évaluations
/// (`depots` de `EvaluationSyncView`) et n'est jamais écrite par la tablette.
/// Une copie par élève, la plus récente. Seules les métadonnées des pages sont
/// rangées (`fichiers_json` : id, ordre, nom, type, taille, empreinte) : les
/// octets — la copie d'un mineur — ne se gardent pas, ils se téléchargent à
/// la demande.
const TableSchema evaluationDepotTable = TableSchema(
  name: 'evaluation_depot',
  createTableSql: '''
    CREATE TABLE evaluation_depot (
      id TEXT PRIMARY KEY,
      evaluation_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      deposited_at TEXT,
      en_retard INTEGER NOT NULL DEFAULT 0,
      fichiers_json TEXT NOT NULL DEFAULT '[]'
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_evaluation_depot_evaluation '
        'ON evaluation_depot(evaluation_id)',
  ],
);

const List<TableSchema> evaluationDepotTables = [evaluationDepotTable];
