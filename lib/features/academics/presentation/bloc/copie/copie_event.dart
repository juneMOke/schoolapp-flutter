import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';

sealed class CopieEvent extends Equatable {
  const CopieEvent();

  @override
  List<Object?> get props => [];
}

/// Charge le journal des copies d'une évaluation.
class CopieLogRequested extends CopieEvent {
  final String evaluationId;

  const CopieLogRequested(this.evaluationId);

  @override
  List<Object?> get props => [evaluationId];
}

/// Une impression ou un partage a abouti : on le journalise.
class CopieDiffused extends CopieEvent {
  final String evaluationId;
  final CopieKind kind;
  final bool corrige;

  const CopieDiffused({
    required this.evaluationId,
    required this.kind,
    required this.corrige,
  });

  @override
  List<Object?> get props => [evaluationId, kind, corrige];
}
