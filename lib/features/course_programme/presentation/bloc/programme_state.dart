import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';

enum ProgrammeStatus { loading, ready, failure }

/// Le retour d'un geste, montré une fois (toast). [seq] le distingue d'un
/// retour identique précédent.
enum ProgrammeFeedbackKind {
  chapitreCreated,
  chapitreUpdated,
  chapitreDeleted,
  ressourceKeepFailed,
  writeFailed,
}

class ProgrammeFeedback extends Equatable {
  final ProgrammeFeedbackKind kind;
  final int seq;

  /// Le titre du chapitre concerné, quand le message le nomme.
  final String? titre;

  const ProgrammeFeedback(this.kind, this.seq, {this.titre});

  @override
  List<Object?> get props => [kind, seq, titre];
}

class ProgrammeState extends Equatable {
  final ProgrammeStatus status;
  final Programme? programme;
  final Failure? failure;
  final ProgrammeFeedback? feedback;

  /// Les sous-périodes où rattacher un chapitre du cours.
  final List<SousPeriodeOption> sousPeriodes;

  const ProgrammeState({
    this.status = ProgrammeStatus.loading,
    this.programme,
    this.failure,
    this.feedback,
    this.sousPeriodes = const [],
  });

  ProgrammeState copyWith({
    ProgrammeStatus? status,
    Programme? programme,
    Failure? failure,
    ProgrammeFeedback? feedback,
    List<SousPeriodeOption>? sousPeriodes,
  }) => ProgrammeState(
    status: status ?? this.status,
    programme: programme ?? this.programme,
    failure: failure ?? this.failure,
    feedback: feedback ?? this.feedback,
    sousPeriodes: sousPeriodes ?? this.sousPeriodes,
  );

  @override
  List<Object?> get props => [
    status,
    programme,
    failure,
    feedback,
    sousPeriodes,
  ];
}
