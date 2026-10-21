import 'package:school_app_flutter/core/database/table_schema.dart';

/// `boutique_dashboard_cache` — la dernière réponse du serveur au tableau de
/// bord de la boutique, **une par largeur de fenêtre**.
///
/// Le tableau de bord est consultatif : hors ligne, il montre la dernière photo
/// connue, datée, plutôt qu'une erreur. Ce n'est **pas** un miroir : rien ne s'y
/// écrit par l'outbox, rien n'y descend par le pull, et la perdre ne coûte
/// qu'un écran d'erreur réseau.
///
/// - `kind` : `stats` ou `beneficiaries` (la première page **sans filtre**, la
///   seule qu'on garde — une recherche hors ligne se filtre sur elle).
/// - `span_days` : 1, 7 ou 30. La clé est la largeur et non la fenêtre : la
///   photo des « 7 jours » d'hier remplace celle d'avant-hier, et c'est elle
///   qu'on montre — datée — si le réseau manque aujourd'hui.
/// - `payload` : le JSON de la réponse, tel que le modèle le réécrit.
/// - `fetched_at` : epoch ms de la réponse.
const TableSchema boutiqueDashboardCacheTable = TableSchema(
  name: 'boutique_dashboard_cache',
  createTableSql: '''
    CREATE TABLE boutique_dashboard_cache (
      school_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      span_days INTEGER NOT NULL,
      payload TEXT NOT NULL,
      fetched_at INTEGER NOT NULL,
      PRIMARY KEY (school_id, academic_year_id, kind, span_days)
    )
  ''',
);

const List<TableSchema> boutiqueDashboardCacheTables = [
  boutiqueDashboardCacheTable,
];
