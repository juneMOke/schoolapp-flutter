import 'package:school_app_flutter/core/database/table_schema.dart';

/// `recouvrement_dashboard_cache` — la dernière réponse du serveur au tableau
/// de bord du Recouvrement v2, **avec la question qu'elle servait**.
///
/// Le tableau de bord est calculé par le serveur ; hors ligne, il montre les
/// derniers chiffres reçus, datés, **pour les derniers réglages seulement**
/// (arbitrage du 2026-11-22) : changer de frais, de périmètre ou de règle
/// demande le réseau. Ce n'est **pas** un miroir : rien ne s'y écrit par
/// l'outbox, rien n'y descend par le pull, et la perdre ne coûte qu'un écran
/// d'erreur réseau.
///
/// - `kind` : `dashboard` (les chiffres) ou `students` (la première page de la
///   liste, sans recherche ni fiche de classe).
/// - `payload` : `{"question": …, "tab": …, "response": <JSON reçu>}`.
/// - `fetched_at` : epoch ms de la réponse.
const TableSchema recouvrementDashboardCacheTable = TableSchema(
  name: 'recouvrement_dashboard_cache',
  createTableSql: '''
    CREATE TABLE recouvrement_dashboard_cache (
      school_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      payload TEXT NOT NULL,
      fetched_at INTEGER NOT NULL,
      PRIMARY KEY (school_id, academic_year_id, kind)
    )
  ''',
);

const List<TableSchema> recouvrementDashboardCacheTables = [
  recouvrementDashboardCacheTable,
];
