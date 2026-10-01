part of 'tenant_migrations.dart';

/// v58 — présences des élèves v2 : le retard sur une ligne d'appel
/// (`status`, `arrival_time`, `late_minutes`), la réouverture locale d'un
/// appel validé (`attendance_sessions.reopened_at`), le brouillon de l'appel
/// et les clôtures de mois.
///
/// Additif : une ligne existante garde `status` nul et se lit d'après
/// `present`. Gardes de colonne et de table, même raison qu'à la v53 : une
/// base qui n'a jamais porté l'appel traverse le palier sans lever.
Future<void> _studentAttendanceV2(DatabaseExecutor db) async {
  await _addColumns(db, 'attendance_records', const {
    'status': 'TEXT',
    'arrival_time': 'TEXT',
    'late_minutes': 'INTEGER',
  });
  await _addColumns(db, 'attendance_sessions', const {
    'reopened_at': 'INTEGER',
  });
  await _createTables(db, studentAttendanceV2Tables);
}

/// Ajoute les [columns] absentes de [table] ; rien si la table n'existe pas.
Future<void> _addColumns(
  DatabaseExecutor db,
  String table,
  Map<String, String> columns,
) async {
  final info = await db.rawQuery('PRAGMA table_info($table)');
  if (info.isEmpty) return;
  final existing = {for (final row in info) row['name']};
  for (final column in columns.entries) {
    if (existing.contains(column.key)) continue;
    await db.execute(
      'ALTER TABLE $table ADD COLUMN ${column.key} ${column.value}',
    );
  }
}
