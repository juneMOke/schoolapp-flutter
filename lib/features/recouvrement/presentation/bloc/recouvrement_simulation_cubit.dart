import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_recovery_line.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

export 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_simulation.dart';

class RecouvrementSimulationState extends Equatable {
  final RecouvrementCriterion criterion;

  /// Plancher du critère « a versé moins que… ». `null` tant que rien n'est
  /// saisi — auquel cas le critère ne vise **personne**, plutôt que tout le
  /// monde.
  final Money? threshold;

  /// Seuil sous lequel un groupe est dit ingérable, en points de pourcentage.
  final int criticalPercent;

  final RecouvrementSimulation result;

  const RecouvrementSimulationState({
    this.criterion = RecouvrementCriterion.noPayment,
    this.threshold,
    this.criticalPercent = defaultCriticalPercent,
    this.result = RecouvrementSimulation.empty,
  });

  /// Bornes du curseur, telles que la spec les pose : 30 → 90, pas de 5.
  static const int minCriticalPercent = 30;
  static const int maxCriticalPercent = 90;
  static const int criticalPercentStep = 5;
  static const int defaultCriticalPercent = 60;

  /// Un groupe est « fragile » entre le seuil et ce nombre de points au-dessus.
  static const int fragileBand = 15;

  bool get needsThreshold => criterion == RecouvrementCriterion.belowThreshold;

  @override
  List<Object?> get props => [criterion, threshold, criticalPercent, result];
}

/// Les réglages de la simulation, et son résultat.
///
/// **Pur et synchrone.** Aucun `Future`, aucune lecture : le curseur de seuil
/// doit se sentir immédiat, et un recalcul asynchrone se verrait. Les lignes
/// viennent du tableau de bord, qui les tient hors de son état.
///
/// **N'écrit jamais.** Ce cubit chiffre le coût d'une décision ; l'appliquer
/// passe par les Inscriptions, dossier par dossier.
class RecouvrementSimulationCubit extends Cubit<RecouvrementSimulationState> {
  RecouvrementSimulationCubit() : super(const RecouvrementSimulationState());

  List<LocalRecoveryLine> _lines = const <LocalRecoveryLine>[];
  ExchangeRate? _rate;

  /// Repose la simulation sur un nouveau registre — appelé quand le tableau de
  /// bord a fini de lire. Les réglages sont **conservés** : après un
  /// rafraîchissement, l'utilisateur retrouve exactement son arbitrage.
  void setLines(List<LocalRecoveryLine> lines, {ExchangeRate? rate}) {
    _lines = lines;
    _rate = rate;
    _recompute();
  }

  void setCriterion(RecouvrementCriterion criterion) {
    if (criterion == state.criterion) return;
    // Quitter le critère du plancher oublie le plancher : le garder ferait
    // réapparaître un montant qu'on croyait avoir laissé derrière soi.
    emit(
      RecouvrementSimulationState(
        criterion: criterion,
        threshold: criterion == RecouvrementCriterion.belowThreshold
            ? state.threshold
            : null,
        criticalPercent: state.criticalPercent,
        result: state.result,
      ),
    );
    _recompute();
  }

  void setThreshold(Money? threshold) {
    if (threshold == state.threshold) return;
    emit(
      RecouvrementSimulationState(
        criterion: state.criterion,
        threshold: threshold,
        criticalPercent: state.criticalPercent,
        result: state.result,
      ),
    );
    _recompute();
  }

  void setCriticalPercent(int percent) {
    final clamped = percent.clamp(
      RecouvrementSimulationState.minCriticalPercent,
      RecouvrementSimulationState.maxCriticalPercent,
    );
    if (clamped == state.criticalPercent) return;
    emit(
      RecouvrementSimulationState(
        criterion: state.criterion,
        threshold: state.threshold,
        criticalPercent: clamped,
        result: state.result,
      ),
    );
    _recompute();
  }

  void _recompute() {
    emit(
      RecouvrementSimulationState(
        criterion: state.criterion,
        threshold: state.threshold,
        criticalPercent: state.criticalPercent,
        result: RecouvrementSimulationProjector.project(
          _lines,
          criterion: state.criterion,
          criticalPercent: state.criticalPercent,
          threshold: state.threshold,
          rate: _rate,
        ),
      ),
    );
  }
}
