import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/database/app_database.dart';
import 'package:school_app_flutter/core/database/offline_schema.dart';

/// Escalier d'un fichier d'ÉCOLE (`school_<id>.db`).
///
/// Un fichier d'école neuf naît en v49 : il ne passe jamais par ici. Seule la
/// base héritée ADOPTÉE arrive en dessous — en v48, ou plus bas si le poste a
/// sauté des versions. Elle repasse alors par l'escalier hérité, sur le schéma
/// COMPLET (elle porte encore les tables de l'appareil), avant le palier v49.
///
/// Les paliers suivants d'une école s'ajoutent ici, `if (upTo(n))`, jamais
/// dans l'escalier hérité : celui-ci est clos à la v48.
Future<void> migrateTenantDatabase(
  DatabaseExecutor db,
  int oldVersion, {
  int newVersion = AppConstants.offlineDbSchemaVersion,
}) async {
  bool upTo(int version) => oldVersion < version && version <= newVersion;

  if (oldVersion < AppConstants.legacyOfflineDbSchemaVersion) {
    await migrateOfflineDatabase(
      db,
      oldVersion,
      buildOfflineSchema(),
      newVersion: AppConstants.legacyOfflineDbSchemaVersion,
    );
  }
  if (upTo(49)) {
    await _returnDeviceTables(db);
  }
}

/// Escalier de `device.db`. Né en v49 : aucun palier en dessous, et les
/// suivants de l'appareil s'ajouteront ici.
Future<void> migrateDeviceDatabase(
  DatabaseExecutor db,
  int oldVersion, {
  int newVersion = AppConstants.offlineDbSchemaVersion,
}) async {}

/// v49 — la base adoptée rend à l'appareil ce qui lui appartient.
///
/// L'éclatement l'a déjà recopié dans `device.db` (MULTI_ECOLE_PLAN.md §10.3).
/// Le garder ici laisserait deux copies de la session diverger, et un DAO mal
/// câblé lirait la mauvaise sans que rien ne le signale.
///
/// DDL inline, jamais lu du schéma vivant. La session avant le compte : elle le
/// référence, et les clés étrangères sont actives.
Future<void> _returnDeviceTables(DatabaseExecutor db) async {
  await db.execute('DROP TABLE IF EXISTS auth_local_session');
  await db.execute('DROP TABLE IF EXISTS auth_local_user');
  await db.execute('DROP TABLE IF EXISTS editique_cache_entries');
  // Les curseurs du catalogue éditique sont partis avec son index ; le marqueur
  // d'école de sa garde n'a plus d'objet sous la coexistence.
  await db.execute(
    "DELETE FROM sync_meta WHERE resource = 'editique_cache_school' "
    "OR substr(resource, 1, 18) = 'editique_documents'",
  );
}
