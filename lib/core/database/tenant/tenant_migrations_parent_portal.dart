part of 'tenant_migrations.dart';

/// v66 — le côté école du portail parent (PR back #178 à #184), en UN seul
/// palier pour tous ses lots : une montée de schéma par livraison, pas par lot.
///
/// - les justifications d'absence déposées par les parents (création pure :
///   la table se remplit au premier pull du flux `attendance.justifications`).
Future<void> _parentPortalStaffSide(DatabaseExecutor db) async {
  await _createTables(db, attendanceJustificationTables);
}
