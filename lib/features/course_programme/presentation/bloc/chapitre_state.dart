import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_detail.dart';

/// `gone` : le chapitre affiché a disparu (supprimé ailleurs) — plus aucun
/// geste, l'écran rend la main au programme.
enum ChapitreStatus { loading, ready, failure, gone }

enum ChapitreFeedbackKind { noteAdded, noteDeleted, contentSaved, writeFailed }

/// Un retour à montrer une fois. [noteId] : la note dont la suppression peut
/// encore s'annuler.
class ChapitreFeedback extends Equatable {
  final ChapitreFeedbackKind kind;
  final int seq;
  final String? noteId;

  const ChapitreFeedback(this.kind, this.seq, {this.noteId});

  @override
  List<Object?> get props => [kind, seq, noteId];
}

class ChapitreState extends Equatable {
  final ChapitreStatus status;
  final ChapitreDetail? detail;
  final Failure? failure;
  final ChapitreFeedback? feedback;

  /// Notes masquées dont la suppression attend la fin du délai d'annulation.
  final Set<String> hiddenNotes;

  const ChapitreState({
    this.status = ChapitreStatus.loading,
    this.detail,
    this.failure,
    this.feedback,
    this.hiddenNotes = const {},
  });

  ChapitreState copyWith({
    ChapitreStatus? status,
    ChapitreDetail? detail,
    Failure? failure,
    ChapitreFeedback? feedback,
    Set<String>? hiddenNotes,
  }) => ChapitreState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    failure: failure ?? this.failure,
    feedback: feedback ?? this.feedback,
    hiddenNotes: hiddenNotes ?? this.hiddenNotes,
  );

  @override
  List<Object?> get props => [status, detail, failure, feedback, hiddenNotes];
}
