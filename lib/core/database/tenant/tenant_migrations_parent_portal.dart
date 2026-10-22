part of 'tenant_migrations.dart';

/// v66 — le côté école du portail parent (PR back #178 à #184), en UN seul
/// palier pour tous ses lots : une montée de schéma par livraison, pas par lot.
///
/// - les justifications d'absence déposées par les parents (création pure :
///   la table se remplit au premier pull du flux `attendance.justifications`) ;
/// - la remise d'un devoir (V179) : trois colonnes sur `evaluation`, posées aux
///   valeurs par défaut du serveur (en classe, fin du jour, pas de retard) ;
/// - les copies déposées par les parents (V180) : `evaluation_depot`, création
///   pure, remplie par le re-pull des évaluations ;
/// - les curseurs des évaluations et des notes repartent de zéro : les
///   tablettes ont déjà tiré, en ignorant les champs neufs, les devoirs
///   déposés depuis la mise en prod du portail (v0.13.0, 2026-10-20). Sans ce
///   re-pull, elles ne verraient jamais ces copies ni ces remises.
Future<void> _parentPortalStaffSide(DatabaseExecutor db) async {
  await _createTables(db, attendanceJustificationTables);
  await _createTables(db, evaluationDepotTables);
  await _addColumns(db, 'evaluation', const {
    'heure_limite': 'TEXT',
    'mode_remise': "TEXT NOT NULL DEFAULT 'EN_CLASSE'",
    'depot_tardif_permis': 'INTEGER NOT NULL DEFAULT 0',
  });
  await _rewindCursors(db, const ['academics_evaluations', 'academics_notes']);
}

/// Remet à zéro les curseurs dont la clé commence par l'un des [prefixes] (un
/// par cours). Rien si la base ne porte pas encore `sync_meta`.
Future<void> _rewindCursors(DatabaseExecutor db, List<String> prefixes) async {
  final info = await db.rawQuery('PRAGMA table_info(sync_meta)');
  if (info.isEmpty) return;
  for (final prefix in prefixes) {
    await db.delete(
      'sync_meta',
      where: 'substr(resource, 1, ?) = ?',
      whereArgs: [prefix.length, prefix],
    );
  }
}
