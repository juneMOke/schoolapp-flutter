part of 'tenant_migrations.dart';

/// v63 (appareil) — le cache éditique admet la fiche d'inscription (`FI`).
///
/// La tablette garde la fiche qu'elle a demandée pour la rouvrir hors ligne.
/// SQLite ne sait pas élargir un `CHECK` : la table est reconstruite **avec
/// copie**, jamais vidée — chaque ligne perdue serait un fichier chiffré
/// introuvable (même raison qu'à la v22).
///
/// Rejouable : l'étape se garde sur le DDL réel de la table et ne fait rien si
/// `FI` y figure déjà.
Future<void> _admitEnrollmentSheetInEditiqueCache(DatabaseExecutor db) async {
  const name = 'editique_cache_entries';
  final ddl = await db.rawQuery(
    "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
    [name],
  );
  if (ddl.isEmpty) return;
  final sql = ddl.first['sql'] as String? ?? '';
  if (sql.contains("'FI'")) return;

  // Les colonnes de la forme v62, et elles seules : la table source porte la
  // forme d'avant cette étape.
  const columnList =
      'id, document_id, document_number, doc_type, student_id, '
      'academic_year_id, school_id, owner_uid, size_bytes, content_sha256, '
      'emitted_at, cancelled_at, cancellation_reason, created_at, '
      'last_accessed_at';

  await db.execute('ALTER TABLE $name RENAME TO ${name}_v62');
  await db.execute(editiqueCacheEntriesTable.createTableSql);
  await db.execute(
    'INSERT INTO $name ($columnList) SELECT $columnList FROM ${name}_v62',
  );
  await db.execute('DROP TABLE ${name}_v62');
  for (final indexSql in editiqueCacheEntriesTable.createIndexSql) {
    await db.execute(_ifNotExists(indexSql));
  }
}
