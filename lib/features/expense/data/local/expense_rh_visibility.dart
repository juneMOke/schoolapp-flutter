import 'package:school_app_flutter/core/offline/sync_engine.dart'
    show Clock, systemClock;
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_pull_repository.dart';

/// Lit si la session voit la paie (`hr.pay.read`) ; `null` = droits inconnus.
typedef ExpenseReadsPayroll = Future<bool?> Function();

/// Le bloc R.H. d'une avance est caviardé **à la descente** (T14) : une
/// demande reçue sans `hr.pay.read` arrive sans son bloc, et un pull
/// incrémental ne la renverra pas. Un poste qui gagne le droit doit donc
/// reprendre le flux des dépenses depuis le début.
///
/// Le marqueur retient, par école, si le dernier pull s'est fait avec ou sans
/// le droit. Rembobiner, **puis** réécrire le marqueur : un processus tué
/// entre les deux rembobine de nouveau au cycle suivant, jamais l'inverse.
class ExpenseRhVisibility {
  final SyncMetaDao _syncMetaDao;
  final ExpenseReadsPayroll _readsPayroll;
  final Clock _now;

  const ExpenseRhVisibility({
    required SyncMetaDao syncMetaDao,
    required ExpenseReadsPayroll readsPayroll,
    Clock now = systemClock,
  }) : _syncMetaDao = syncMetaDao,
       _readsPayroll = readsPayroll,
       _now = now;

  static const String _granted = 'granted';
  static const String _redacted = 'redacted';

  /// Clé du marqueur, hors de l'espace `expenses@…` que balaie
  /// [SyncMetaDao.deleteCursorsOf].
  static String markerKey(String schoolId) =>
      '${kExpensesResource}_rh_visibility@$schoolId';

  /// Rembobine [cursorKey] si la session vient de gagner le droit. Rend `true`
  /// quand le curseur a été effacé. Droits inconnus : rien ne bouge.
  Future<bool> rewindIfGained(String schoolId, String cursorKey) async {
    final reads = await _readsPayroll();
    if (reads == null) return false;
    final marker = markerKey(schoolId);
    final previous = await _syncMetaDao.getCursor(marker);
    final rewind = reads && previous != _granted;
    if (rewind) await _syncMetaDao.deleteCursor(cursorKey);
    await _syncMetaDao.setCursor(
      marker,
      cursor: reads ? _granted : _redacted,
      syncedAt: _now(),
    );
    return rewind;
  }
}
