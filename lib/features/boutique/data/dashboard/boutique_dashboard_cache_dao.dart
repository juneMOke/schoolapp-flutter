import 'dart:convert';

import 'package:sqflite_common/sqlite_api.dart';

/// Ce que le cache garde : deux réponses, chacune par largeur de fenêtre.
enum BoutiqueDashboardCacheKind {
  stats('stats'),
  beneficiaries('beneficiaries');

  const BoutiqueDashboardCacheKind(this.column);

  final String column;
}

/// Une réponse en cache, et quand le serveur l'a donnée.
typedef CachedDashboardPayload = ({
  Map<String, dynamic> payload,
  DateTime fetchedAt,
});

/// La photo hors ligne du tableau de bord (`boutique_dashboard_cache`).
///
/// **Scopée école et année** : une tablette partagée ne montre pas les chiffres
/// de l'établissement voisin, et une photo de l'an dernier ne passe pas pour
/// celle de l'exercice courant.
class BoutiqueDashboardCacheDao {
  static const String _table = 'boutique_dashboard_cache';

  final Database _db;

  const BoutiqueDashboardCacheDao(this._db);

  Future<void> write({
    required String schoolId,
    required String academicYearId,
    required BoutiqueDashboardCacheKind kind,
    required int spanDays,
    required Map<String, dynamic> payload,
    required DateTime fetchedAt,
  }) => _db.insert(_table, {
    'school_id': schoolId,
    'academic_year_id': academicYearId,
    'kind': kind.column,
    'span_days': spanDays,
    'payload': jsonEncode(payload),
    'fetched_at': fetchedAt.millisecondsSinceEpoch,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// `null` sans photo — ou avec une photo illisible, qui ne vaut pas mieux.
  Future<CachedDashboardPayload?> read({
    required String schoolId,
    required String academicYearId,
    required BoutiqueDashboardCacheKind kind,
    required int spanDays,
  }) async {
    final rows = await _db.query(
      _table,
      columns: const ['payload', 'fetched_at'],
      where:
          'school_id = ? AND academic_year_id = ? AND kind = ? AND span_days = ?',
      whereArgs: [schoolId, academicYearId, kind.column, spanDays],
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
