import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';

/// Pulls KEYSET du grand-livre Facturation (miroir `openapi_billing_sync.yaml`,
/// ADR-008/009) : peuplent le cache local, jamais l'affichage direct (ADR-003).
/// Chaque méthode est self-sufficient (jeton via `sync_meta`, périmètre porté
/// par le JWT) et idempotente — appelée par les `FinancePullHandler` du
/// `PullCoordinator`, **seul** chemin depuis le repli ADR-015 F6 : le cycle
/// complet (ouverture de session, retour online) et le sous-ensemble que
/// `SyncFinancePullsUseCase` demande au montage du module y passent tous les
/// deux. Les deux seules autres bouches sont `FinanceLedgerRefresher` (rafraî-
/// chissement ciblé d'une fiche élève, hors périmètre du plan) et le handler
/// d'outbox, qui pousse.
abstract class FinancePullRepository {
  /// Créances autoritaires du roster (§2.1) — le plus gros volume. UPSERT
  /// `SYNCED` : le client n'écrit jamais `amount_paid`/`status` lui-même.
  Future<Either<Failure, FinancePullOutcome>> syncStudentCharges();

  /// Paiements + leurs allocations (§2.2), **y compris ceux de l'autre poste de
  /// perception** — c'est l'anti-divergence de snapshot. UPSERT `SYNCED`.
  Future<Either<Failure, FinancePullOutcome>> syncPayments();
}
