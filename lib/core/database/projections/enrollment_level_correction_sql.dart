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
///  2. **elle est accusée, mais pas encore descendue** (`settled_at` nul) :
///     tant qu'aucune descente partie **après** l'accusé n'a ramené
///     l'inscription, les créances et leurs pierres tombales, les créances
///     affichées peuvent être celles de l'ancienne grille — que le serveur a
///     supprimées. Ni le niveau local (l'inscription peut descendre sans les
///     créances, chaque flux échouant pour lui-même) ni une durée (une tablette
///     restée hors ligne après l'accusé) ne prouvent cette descente.
///
/// Une correction refusée ne retient rien : elle n'a rien changé au serveur.
/// Une entrée d'outbox tombée en échec terminal non plus : sans elle, le geste
/// ne partira jamais, et la ligne en attente ne doit pas garder la caisse.
abstract final class EnrollmentLevelCorrectionSql {
  static const String table = 'enrollment_level_corrections';

  /// Type d'agrégat des corrections dans l'outbox.
  static const String aggregateType = 'ENROLLMENT_LEVEL_CORRECTION';

  /// Prédicat SQL : l'entrée d'outbox de la correction [alias] est encore en
  /// file (`PENDING`). Faux quand le moteur l'a abandonnée (`SYNC_ERROR`, après
  /// trop d'échecs transitoires ou un contenu illisible) : la ligne, elle,
  /// resterait `PENDING_SYNC` pour toujours, faute de quiconque pour la juger.
  static String queued(String alias) =>
      '''EXISTS (
        SELECT 1 FROM ${OutboxDao.table} o
        WHERE o.id = '$aggregateType:' || $alias.id
          AND o.status = '${OutboxStatus.pending.dbValue}'
      )''';

  /// L'encaissement de [studentId] est-il retenu par une correction de niveau ?
  /// [academicYearId] `null` : sur n'importe quelle année.
  static Future<bool> holdsCollection(
    DatabaseExecutor db, {
    required String studentId,
    String? academicYearId,
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
          (c.sync_status = ? AND ${queued('c')})
          OR (c.sync_status = ? AND c.settled_at IS NULL)
        )
      LIMIT 1
      ''',
      [
        studentId,
        ?academicYearId,
        RecordSyncState.pending.dbValue,
        RecordSyncState.synced.dbValue,
      ],
    );
    return rows.isNotEmpty;
  }
}
