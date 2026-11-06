import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce que la correction de niveau d'un élève interdit ailleurs : encaisser
/// (D7 de l'étude « Changer un élève de niveau »).
///
/// Logé dans le socle, comme la désactivation : la finance lit
/// `enrollment_level_corrections` sans dépendre du module qui l'écrit.
///
/// ## Quand l'encaissement est retenu
///
/// Seule compte la **dernière** correction de chaque inscription (par instant
/// du geste). Elle retient l'encaissement dans deux cas :
///
///  1. **elle attend** (`PENDING_SYNC`) et son entrée d'outbox est vivante. Un
///     versement saisi maintenant viserait l'ancienne grille, et l'outbox
///     n'ordonne rien entre deux types de gestes : parti avant la correction,
///     il la ferait refuser ;
///  2. **elle est accusée, mais pas encore descendue** : l'inscription locale
///     porte encore un autre niveau que la cible, donc les créances affichées
///     sont celles de l'ancienne grille. Ce cas est **borné** à
///     [appliedHoldWindowMs] après l'accusé : si une autre tablette a remis
///     l'élève à un autre niveau entre-temps, l'écart ne se refermerait jamais,
///     et une garde sans issue gèlerait la caisse de cet élève pour toujours.
///
/// Une correction refusée ne retient rien : elle n'a rien changé au serveur.
/// Une entrée d'outbox tombée en échec terminal non plus : sans elle, le geste
/// ne partira jamais, et la ligne en attente ne doit pas garder la caisse.
abstract final class EnrollmentLevelCorrectionSql {
  static const String table = 'enrollment_level_corrections';

  /// Type d'agrégat des corrections dans l'outbox.
  static const String aggregateType = 'ENROLLMENT_LEVEL_CORRECTION';

  /// Durée pendant laquelle une correction accusée retient encore
  /// l'encaissement, le temps que la descente apporte la nouvelle grille.
  static const int appliedHoldWindowMs = 60 * 60 * 1000;

  /// L'encaissement de [studentId] est-il retenu par une correction de niveau ?
  /// [academicYearId] `null` : sur n'importe quelle année.
  static Future<bool> holdsCollection(
    DatabaseExecutor db, {
    required String studentId,
    String? academicYearId,
    required int nowMs,
  }) async {
    final rows = await db.rawQuery(
      '''
      SELECT 1 FROM $table c
      WHERE c.student_id = ?
        ${academicYearId == null ? '' : 'AND c.academic_year_id = ?'}
        AND NOT EXISTS (
          SELECT 1 FROM $table n
          WHERE n.enrollment_id = c.enrollment_id
            AND (n.corrected_at > c.corrected_at
              OR (n.corrected_at = c.corrected_at AND n.rowid > c.rowid))
        )
        AND (
          (c.sync_status = ? AND EXISTS (
            SELECT 1 FROM ${OutboxDao.table} o
            WHERE o.id = '$aggregateType:' || c.id AND o.status = ?
          ))
          OR (c.sync_status = ? AND c.acked_at > ? AND EXISTS (
            SELECT 1 FROM enrollments e
            WHERE e.id = c.enrollment_id
              AND COALESCE(e.school_level_id, '') <> c.to_school_level_id
          ))
        )
      LIMIT 1
      ''',
      [
        studentId,
        ?academicYearId,
        RecordSyncState.pending.dbValue,
        OutboxStatus.pending.dbValue,
        RecordSyncState.synced.dbValue,
        nowMs - appliedHoldWindowMs,
      ],
    );
    return rows.isNotEmpty;
  }
}
