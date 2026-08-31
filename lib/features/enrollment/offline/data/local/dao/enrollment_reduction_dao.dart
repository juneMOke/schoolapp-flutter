import 'package:sqflite_common/sqlite_api.dart';

/// Octrois de réduction d'une inscription (`enrollment_reductions`, ADR-021 V1).
///
/// **Mémoire seule** : aucune créance ne les lit, aucun montant n'en dépend.
/// La table n'a pas de `sync_status` et n'en aura pas — elle n'a pas de flux
/// propre, les codes voyagent dans l'agrégat d'inscription et le serveur les
/// renvoie.
class EnrollmentReductionDao {
  final Database _db;

  const EnrollmentReductionDao(this._db);

  /// Les codes octroyés à cette inscription, triés (ordre stable à l'affichage
  /// comme à l'envoi — un ordre de liste qui bouge ferait diverger deux
  /// payloads identiques).
  Future<List<String>> codesFor(String enrollmentId) async {
    if (enrollmentId.isEmpty) return const [];
    final rows = await _db.query(
      'enrollment_reductions',
      columns: ['reduction_code'],
      where: 'enrollment_id = ?',
      whereArgs: [enrollmentId],
      orderBy: 'reduction_code',
    );
    return [for (final row in rows) row['reduction_code'] as String];
  }

  /// Remplace l'intégralité des octrois de cette inscription.
  ///
  /// Remplacement et non ajout : décocher DOIT retirer. Purge + insertion dans
  /// une transaction, pour qu'un échec ne laisse jamais l'inscription sans
  /// aucune réduction alors qu'elle en avait.
  Future<void> replaceFor(
    String enrollmentId,
    List<String> codes, {
    required int nowMs,
  }) async {
    if (enrollmentId.isEmpty) return;
    await _db.transaction((txn) async {
      await txn.delete(
        'enrollment_reductions',
        where: 'enrollment_id = ?',
        whereArgs: [enrollmentId],
      );
      final batch = txn.batch();
      // `toSet()` : deux fois le même code viendrait buter sur la clé primaire
      // et ferait échouer la transaction entière — donc perdre TOUS les
      // octrois pour un doublon qui ne change rien.
      for (final code in codes.toSet()) {
        batch.insert('enrollment_reductions', {
          'enrollment_id': enrollmentId,
          'reduction_code': code,
          'updated_at': nowMs,
        });
      }
      await batch.commit(noResult: true);
    });
  }
}
