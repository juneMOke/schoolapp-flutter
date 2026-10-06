part of 'tenant_migrations.dart';

/// v62 — le sujet d'une évaluation, sa copie et ses publications
/// (`EVALUATION_SUJET` : plan front EV-1).
///
/// Dix colonnes sur `evaluation` — le titre, le sujet en sous-agrégat LWW à
/// statut propre, l'état des publications — et la table neuve du journal des
/// copies. Une évaluation existante garde un sujet vide et un titre nul
/// (repli sur le nom dérivé) jusqu'au pull : le curseur des évaluations est
/// remis à zéro pour que tout redescende.
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
    'sujet_max_points': 'REAL',
    'publication_json': 'TEXT',
  });
  await _createTables(db, const [evaluationCopieLogTable]);
  // Les évaluations déjà tirées n'ont ni titre, ni cadre, ni sujet, ni
  // journal, ni publications : on reprend leur flux du début. Sûr, le pull
  // les rafraîchit par UPDATE et ne touche jamais un brouillon en attente.
  final meta = await db.rawQuery('PRAGMA table_info(sync_meta)');
  if (meta.isNotEmpty) {
    await db.delete(
      'sync_meta',
      where: 'resource LIKE ?',
      whereArgs: ['academics_evaluations%'],
    );
  }
}
