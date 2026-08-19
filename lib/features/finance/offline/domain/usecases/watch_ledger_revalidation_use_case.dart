import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';

/// Flux des aboutissements du rafraîchissement ciblé (un `studentId` par cycle
/// abouti), consommé par le détail Facturation pour relire le grand-livre local.
///
/// C'est l'autre moitié du régime **stale-while-revalidate** : les repos
/// offline-first servent la base sans attendre le réseau, ce signal leur dit
/// quand il y a peut-être du neuf. Sans lui, une tablette dont la base est vide
/// afficherait « Aucun frais » et n'en sortirait jamais — l'`await` qu'on a
/// retiré tenait ce rôle, très cher, à chaque lecture.
class WatchLedgerRevalidationUseCase {
  final FinanceLedgerRefresher _refresher;

  const WatchLedgerRevalidationUseCase(this._refresher);

  Stream<String> call() => _refresher.revalidated;
}
