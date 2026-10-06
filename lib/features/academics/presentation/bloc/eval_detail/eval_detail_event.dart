import 'package:equatable/equatable.dart';

sealed class EvalDetailEvent extends Equatable {
  const EvalDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Charge (ou recharge) le sujet et l'avancement des notes d'une évaluation.
/// Un rechargement garde l'écran affiché : il ne repasse pas par le squelette.
class EvalDetailRequested extends EvalDetailEvent {
  final String evaluationId;

  const EvalDetailRequested(this.evaluationId);

  @override
  List<Object?> get props => [evaluationId];
}
