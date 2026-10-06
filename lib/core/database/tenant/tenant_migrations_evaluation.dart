part of 'tenant_migrations.dart';

/// v62 — le sujet d'une évaluation, sa copie et ses publications
/// (`EVALUATION_SUJET` : plan front EV-1).
///
/// Neuf colonnes sur `evaluation` — le titre, le sujet en sous-agrégat LWW à
/// statut propre, l'état des publications — et la table neuve du journal des
/// copies. Additif, **aucune reprise** : une évaluation existante garde un
/// sujet vide et un titre nul (repli sur le nom dérivé), et ses publications
/// descendent avec le delta.
///
/// Gardes de colonne et de table, même raison qu'à la v58 : une base héritée
/// adoptée repasse par cet escalier, et une base qui n'a jamais porté les
/// notes le traverse sans lever.
Future<void> _evaluationSujet(DatabaseExecutor db) async {
  await _addColumns(db, 'evaluation', const {
    'titre': 'TEXT',
    'duree_minutes': 'INTEGER',
    'programme_json': "TEXT NOT NULL DEFAULT '[]'",
    'consignes': 'TEXT',
    'sujet_questions_json': "TEXT NOT NULL DEFAULT '[]'",
    'sujet_updated_at': 'INTEGER',
    'sujet_sync_status': 'TEXT',
    'sujet_rejection_code': 'TEXT',
    'publication_json': 'TEXT',
  });
  await _createTables(db, const [evaluationCopieLogTable]);
}
