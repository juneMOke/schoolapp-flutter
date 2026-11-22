import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

/// Ce que le cache garde : les chiffres, et la première page de la liste.
enum RecoveryCacheKind {
  dashboard('dashboard'),
  students('students');

  const RecoveryCacheKind(this.column);

  final String column;
}

/// Une photo et l'heure où le serveur l'a donnée.
typedef RecoveryCachedPayload = ({
  Map<String, dynamic> payload,
  DateTime fetchedAt,
});

/// La photo hors ligne du tableau de bord (`recouvrement_dashboard_cache`).
///
/// **Scopée école et année** : une tablette partagée ne montre pas les chiffres
/// de l'établissement voisin, et une photo de l'an dernier ne passe pas pour
/// celle de l'exercice courant.
class RecoveryDashboardCacheDao {
  static const String _table = 'recouvrement_dashboard_cache';

  final Database _db;

  const RecoveryDashboardCacheDao(this._db);

  Future<void> write({
    required String schoolId,
    required String academicYearId,
    required RecoveryCacheKind kind,
    required Map<String, dynamic> payload,
    required DateTime fetchedAt,
  }) => _db.insert(_table, {
    'school_id': schoolId,
    'academic_year_id': academicYearId,
    'kind': kind.column,
    'payload': jsonEncode(payload),
    'fetched_at': fetchedAt.millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// `null` sans photo — ou avec une photo illisible, qui ne vaut pas mieux.
  Future<RecoveryCachedPayload?> read({
    required String schoolId,
    required String academicYearId,
    required RecoveryCacheKind kind,
  }) async {
    final rows = await _db.query(
      _table,
      columns: const ['payload', 'fetched_at'],
      where: 'school_id = ? AND academic_year_id = ? AND kind = ?',
      whereArgs: [schoolId, academicYearId, kind.column],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final decoded = jsonDecode(rows.first['payload'] as String);
    if (decoded is! Map<String, dynamic>) return null;
    return (
      payload: decoded,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        rows.first['fetched_at'] as int,
      ),
    );
  }
}
