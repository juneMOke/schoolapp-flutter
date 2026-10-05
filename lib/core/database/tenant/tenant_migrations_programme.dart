part of 'tenant_migrations.dart';

/// v61 — le programme de cours : trois tables neuves, puis les chapitres de
/// `ref_chapitre` recopiés en **ébauches**.
///
/// La recopie garde la modale de création d'évaluation garnie entre la mise à
/// jour et le premier flux des chapitres. Une ébauche est connue du serveur
/// (`server_known = 1`) mais jamais descendue (`server_updated_at` nul) : elle
/// se lit, se coche dans une évaluation, mais ne s'édite pas avant que le
/// flux l'ait remplacée par la fiche entière.
///
/// `ref_chapitre` est partitionnée par compte (`owner_uid`) : un même chapitre
/// peut y figurer deux fois, d'où `INSERT OR IGNORE`. Garde de table, même
/// raison qu'à la v53 : une base qui n'a jamais porté le référentiel de notes
/// traverse le palier sans lever.
Future<void> _courseProgramme(DatabaseExecutor db) async {
  await _createTables(db, courseProgrammeTables);
  final ref = await db.rawQuery('PRAGMA table_info(ref_chapitre)');
  if (ref.isEmpty) return;
  await db.execute('''
    INSERT OR IGNORE INTO chapitre
      (id, cours_id, ordre, titre, server_known, sync_status, updated_at)
    SELECT id, cours_id, ordre, titre, 1, 'SYNCED', 0 FROM ref_chapitre
  ''');
}
