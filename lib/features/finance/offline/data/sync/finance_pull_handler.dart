import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_pull_outcome.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_pull_repository.dart';

/// [PullHandler] du grand-livre Facturation — une instance par ressource keyset
/// (créances / paiements), enregistrées en DI sur le `PullCoordinator`.
/// **Self-sufficient** : le jeton vit dans `sync_meta` via le repository, le
/// périmètre (école/année) est porté par le JWT. Ne lève pas : l'échec du
/// repository (`Left`) est traduit en [PullOutcome.error].
class FinancePullHandler implements PullHandler {
  @override
  final String resource;

  final Future<Either<Failure, FinancePullOutcome>> Function() _pull;

  const FinancePullHandler._(this.resource, this._pull);

  /// Créances autoritaires du roster (le plus gros volume, §2.1).
  FinancePullHandler.studentCharges(FinancePullRepository repository)
    : this._(
        FinancePullRepositoryImpl.chargesResource,
        repository.syncStudentCharges,
      );

  /// Paiements — y compris ceux de l'autre poste de perception (§2.2).
  FinancePullHandler.payments(FinancePullRepository repository)
    : this._(
        FinancePullRepositoryImpl.paymentsResource,
        repository.syncPayments,
      );

  @override
  Future<PullOutcome> pull() async {
    final result = await _pull();
    return result.fold(
      (failure) => PullOutcome.error(failure.toString()),
      (outcome) => outcome.notModified
          ? const PullOutcome.notModified()
          : PullOutcome.updated(
              upserted: outcome.upserted,
              serverTimeMs: outcome.serverTimeMs,
            ),
    );
  }
}
