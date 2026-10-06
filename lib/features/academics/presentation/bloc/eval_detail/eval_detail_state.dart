import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';

enum EvalDetailStatus { loading, ready, failure }

/// Avancement de la saisie : notes posées (notée ou absence) sur l'effectif.
class NotesProgress extends Equatable {
  final int saisies;
  final int total;

  const NotesProgress({required this.saisies, required this.total});

  static const NotesProgress empty = NotesProgress(saisies: 0, total: 0);

  /// Toutes les notes de l'effectif sont posées (et il y a un effectif).
  bool get isComplete => total > 0 && saisies >= total;

  @override
  List<Object?> get props => [saisies, total];
}

class EvalDetailState extends Equatable {
  final EvalDetailStatus status;
  final EvaluationSujet sujet;
  final NotesProgress progress;
  final Failure? failure;

  const EvalDetailState({
    this.status = EvalDetailStatus.loading,
    this.sujet = const EvaluationSujet(),
    this.progress = NotesProgress.empty,
    this.failure,
  });

  EvalDetailState copyWith({
    EvalDetailStatus? status,
    EvaluationSujet? sujet,
    NotesProgress? progress,
    Failure? Function()? failure,
  }) => EvalDetailState(
    status: status ?? this.status,
    sujet: sujet ?? this.sujet,
    progress: progress ?? this.progress,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [status, sujet, progress, failure];
}
