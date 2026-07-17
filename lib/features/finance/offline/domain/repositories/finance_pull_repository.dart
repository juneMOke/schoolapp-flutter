import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';

/// Pulls KEYSET du grand-livre Facturation (miroir `openapi_billing_sync.yaml`,
/// ADR-008/009) : peuplent le cache local, jamais l'affichage direct (ADR-003).
/// Chaque méthode est self-sufficient (jeton via `sync_meta`, périmètre porté
/// par le JWT) et idempotente — appelée par les `FinancePullHandler` du
/// `PullCoordinator` (retour online) et par `SyncFinancePullsUseCase` (montage
/// du module, hydratation d'une tablette neuve).
abstract class FinancePullRepository {
  /// Créances autoritaires du roster (§2.1) — le plus gros volume. UPSERT
  /// `SYNCED` : le client n'écrit jamais `amount_paid`/`status` lui-même.
  Future<Either<Failure, FinancePullOutcome>> syncStudentCharges();

  /// Paiements + leurs allocations (§2.2), **y compris ceux de l'autre poste de
  /// perception** — c'est l'anti-divergence de snapshot. UPSERT `SYNCED`.
  Future<Either<Failure, FinancePullOutcome>> syncPayments();
}
