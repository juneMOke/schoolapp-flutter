import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/programme.dart';

enum ProgrammeStatus { loading, ready, failure }

/// Le retour d'un geste, montré une fois (toast). [seq] le distingue d'un
/// retour identique précédent.
enum ProgrammeFeedbackKind { chapitreDeleted, writeFailed }

class ProgrammeFeedback extends Equatable {
  final ProgrammeFeedbackKind kind;
  final int seq;

  const ProgrammeFeedback(this.kind, this.seq);

  @override
  List<Object?> get props => [kind, seq];
}

class ProgrammeState extends Equatable {
  final ProgrammeStatus status;
  final Programme? programme;
  final Failure? failure;
  final ProgrammeFeedback? feedback;

  const ProgrammeState({
    this.status = ProgrammeStatus.loading,
    this.programme,
    this.failure,
    this.feedback,
  });

  ProgrammeState copyWith({
    ProgrammeStatus? status,
    Programme? programme,
    Failure? failure,
    ProgrammeFeedback? feedback,
  }) => ProgrammeState(
    status: status ?? this.status,
    programme: programme ?? this.programme,
    failure: failure ?? this.failure,
    feedback: feedback ?? this.feedback,
  );

  @override
  List<Object?> get props => [status, programme, failure, feedback];
}
