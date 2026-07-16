import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';

/// Fraîcheur du grand-livre local d'un élève : epoch ms du dernier
/// rafraîchissement ciblé réussi (null si jamais synchronisé). Alimente
/// l'affichage « à jour à HHhMM » (ADR-002) — l'information qui déclenche la
/// coordination humaine entre les 2 postes de perception (FRONT §5).
class GetLedgerFreshnessUseCase {
  final FinanceLedgerRefresher _refresher;

  const GetLedgerFreshnessUseCase(this._refresher);

  Future<int?> call(String studentId) => _refresher.lastSyncedAt(studentId);
}
