import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_anomaly_dao.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_anomaly.dart';

/// Anomalies d'encaissement ouvertes, pour l'alerte d'administration.
///
/// Volontairement **hors** de `SyncStatusCubit` : la pastille de synchro est un
/// indicateur d'état — elle passe au vert dès que la file est vide. Une anomalie
/// survit à la synchro réussie qui l'a révélée, et ne s'éteint que sur un accusé
/// explicite. Confondre les deux ferait disparaître l'alerte au moment précis où
/// elle devient pertinente.
class PaymentAnomaliesCubit extends Cubit<PaymentAnomaliesState> {
  final PaymentAnomalyDao _dao;
  final CurrentUserContext? _currentUser;
  final int Function() _now;

  /// Désabonnement de la fin de flush.
  void Function()? _unsubscribeFlush;

  PaymentAnomaliesCubit(
    this._dao, {
    CurrentUserContext? currentUser,
    SyncEngine? syncEngine,
    int Function()? now,
  }) : _currentUser = currentUser,
       _now = now ?? _systemNow,
       super(const PaymentAnomaliesState()) {
    // Une anomalie n'est écrite QUE par la transaction d'ACK, donc pendant un
    // flush. S'abonner à la FIN de chaque flush est le seul déclencheur correct :
    // se brancher sur une transition de connectivité manquerait à la fois le
    // poste resté en ligne (aucune transition) et le retour de réseau (le
    // statut passe à `syncing` AVANT le flush, donc avant l'écriture).
    // Même point d'accroche que `SyncStatusCubit`, pour la même raison.
    _unsubscribeFlush = syncEngine?.addFlushCompleteListener(
      () => unawaited(refresh()),
    );
  }

  static int _systemNow() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<void> close() {
    _unsubscribeFlush?.call();
    _unsubscribeFlush = null;
    return super.close();
  }

  /// Relit les anomalies ouvertes. **Ne lève jamais** : une alerte qui fait
  /// planter l'application serait pire que l'anomalie qu'elle signale.
  Future<void> refresh() async {
    try {
      final open = await _dao.openAnomalies();
      if (isClosed) return;
      emit(PaymentAnomaliesState(loaded: true, open: open));
    } catch (_) {
      if (isClosed) return;
      emit(const PaymentAnomaliesState(loaded: true));
    }
  }

  /// Accuse le traitement d'une anomalie par l'opérateur connecté, puis relit.
  Future<void> acknowledge(String anomalyId) async {
    try {
      await _dao.acknowledge(
        id: anomalyId,
        // `?? ''` plutôt qu'un refus : un accusé sans uid connu vaut mieux
        // qu'une alerte qu'on ne peut plus éteindre.
        acknowledgedBy: _currentUser?.uid ?? '',
        nowMs: _now(),
      );
    } catch (_) {
      // Relecture quand même : l'état affiché doit refléter la base, pas
      // l'issue du geste.
    }
    await refresh();
  }
}

class PaymentAnomaliesState extends Equatable {
  final bool loaded;
  final List<PaymentAnomaly> open;

  const PaymentAnomaliesState({
    this.loaded = false,
    this.open = const <PaymentAnomaly>[],
  });

  bool get hasOpenAnomalies => open.isNotEmpty;

  /// La plus récente — celle que le bandeau met en avant quand il y en a
  /// plusieurs. Les autres restent comptées.
  PaymentAnomaly? get latest => open.isEmpty ? null : open.first;

  @override
  List<Object?> get props => [loaded, open];
}
