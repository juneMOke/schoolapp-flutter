import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_sujet.dart';

enum EvalDetailStatus { loading, ready, failure }

/// Enregistrement du sujet : chaque issue est un état, pour que l'écran
/// réagisse une fois (toast, sortie de l'éditeur) sans relire l'historique.
enum SujetSaveStatus { idle, saving, saved, failed }

/// Avancement de la saisie : notes posées (notée ou absence) sur l'effectif.
class NotesProgress extends Equatable {
  final int saisies;
  final int total;

  /// Notes `NOTEE` : dès la première, le maximum est figé (les notes sont
  /// bornées par lui).
  final int notees;

  const NotesProgress({
    required this.saisies,
    required this.total,
    this.notees = 0,
  });

  static const NotesProgress empty = NotesProgress(saisies: 0, total: 0);

  bool get maxLocked => notees > 0;

  /// Toutes les notes de l'effectif sont posées (et il y a un effectif).
  bool get isComplete => total > 0 && saisies >= total;

  @override
  List<Object?> get props => [saisies, total, notees];
}

class EvalDetailState extends Equatable {
  final EvalDetailStatus status;
  final EvaluationSujet sujet;
  final NotesProgress progress;
  final Failure? failure;
  final SujetSaveStatus sujetSave;

  /// Maximum aligné par le dernier enregistrement du sujet ; `null` tant que
  /// celui de l'en-tête vaut.
  final double? maxPoints;

  const EvalDetailState({
    this.status = EvalDetailStatus.loading,
    this.sujet = const EvaluationSujet(),
    this.progress = NotesProgress.empty,
    this.failure,
    this.sujetSave = SujetSaveStatus.idle,
    this.maxPoints,
  });

  EvalDetailState copyWith({
    EvalDetailStatus? status,
    EvaluationSujet? sujet,
    NotesProgress? progress,
    Failure? Function()? failure,
    SujetSaveStatus? sujetSave,
    double? maxPoints,
  }) => EvalDetailState(
    status: status ?? this.status,
    sujet: sujet ?? this.sujet,
    progress: progress ?? this.progress,
    failure: failure != null ? failure() : this.failure,
    sujetSave: sujetSave ?? this.sujetSave,
    maxPoints: maxPoints ?? this.maxPoints,
  );

  @override
  List<Object?> get props => [
    status,
    sujet,
    progress,
    failure,
    sujetSave,
    maxPoints,
  ];
}
