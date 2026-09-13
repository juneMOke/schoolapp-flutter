import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/expense/domain/entities/expense_register_snapshot.dart';
import 'package:school_app_flutter/features/expense/domain/repositories/expense_pull_repository.dart';
import 'package:school_app_flutter/features/expense/domain/usecases/load_expense_register_use_case.dart';

/// La lecture du registre **et ce qui la périme**, partagée par les deux
/// écrans.
///
/// Trois signaux font relire : un pull qui a écrit le registre, les types (le
/// socle) ou le taux ; et la fin d'un flush — c'est là qu'un accusé donne son
/// numéro à une dépense saisie hors ligne (A3) ou la marque « à corriger »
/// (A4). Sans ce second abonnement, la ligne resterait « en attente » à
/// l'écran jusqu'au prochain pull.
class ExpenseSnapshotSource {
  final LoadExpenseRegisterUseCase _load;
  final PullCompletionBus _bus;
  final SyncEngine _engine;

  const ExpenseSnapshotSource({
    required LoadExpenseRegisterUseCase load,
    required PullCompletionBus bus,
    required SyncEngine engine,
  }) : _load = load,
       _bus = bus,
       _engine = engine;

  static final Set<String> watchedResources = {
    kExpensesResource,
    ...resourcesOf(SyncPlanKeys.schoolReferential),
    ...resourcesOf(SyncPlanKeys.financeExchangeRates),
  };

  Future<Either<Failure, ExpenseRegisterSnapshot>> read() => _load();

  /// Appelle [onChanged] à chaque signal ; rend la fonction qui désabonne.
  void Function() watch(void Function() onChanged) {
    final subscription = _bus.stream
        .where((resources) => resources.any(watchedResources.contains))
        .listen((_) => onChanged());
    final removeFlushListener = _engine.addFlushCompleteListener(onChanged);
    return () {
      unawaited(subscription.cancel());
      removeFlushListener();
    };
  }
}
