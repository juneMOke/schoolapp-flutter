import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';

/// Un élève et sa marque du jour.
///
/// La justification de la marque ne porte qu'un **vrai motif**. Ce qu'une
/// ligne reçue porte d'autre — le verdict « non justifiée » d'avant la v2
/// (`UNKNOWN`, `UNJUSTIFIED`), une précision sans motif, un motif que cette
/// tablette ne connaît pas — est gardé tel quel ([keptReason], [keptNote]) et
/// renvoyé à l'identique tant qu'on ne touche pas à la justification : un
/// renvoi ne réécrit jamais la donnée d'un autre.
class ClassPresenceLine extends Equatable {
  final ClassPresenceStudent student;
  final PresenceMark<AbsenceReason> mark;
  final AbsenceReason? keptReason;
  final String? keptNote;

  /// Où en est la marque : sur la tablette (brouillon, appel pas encore
  /// envoyé) ou au serveur.
  final RecordSyncState sync;

  const ClassPresenceLine({
    required this.student,
    required this.mark,
    this.keptReason,
    this.keptNote,
    this.sync = RecordSyncState.synced,
  });

  /// Une ligne lue (base ou brouillon) : la justification n'en garde que les
  /// vrais motifs, le reste est conservé à part.
  factory ClassPresenceLine.read({
    required ClassPresenceStudent student,
    required PresenceMark<AbsenceReason> mark,
    required AbsenceReason? reason,
    required String? note,
    RecordSyncState sync = RecordSyncState.synced,
  }) {
    final justification = justificationOf(reason, note);
    final withJustification = mark.status.isIncident
        ? PresenceMark<AbsenceReason>(
            status: mark.status,
            arrival: mark.arrival,
            lateMinutes: mark.lateMinutes,
            justification: justification,
          )
        : mark;
    return ClassPresenceLine(
      student: student,
      mark: withJustification,
      keptReason: justification == null ? reason : null,
      keptNote: justification == null ? note : null,
      sync: sync,
    );
  }

  /// Un vrai motif justifie ; un verdict, une valeur inconnue ou rien ne
  /// justifient pas.
  static PresenceJustification<AbsenceReason>? justificationOf(
    AbsenceReason? reason,
    String? note,
  ) {
    if (reason == null ||
        reason == AbsenceReason.unsupported ||
        isUnjustifiedAbsence(reason)) {
      return null;
    }
    return PresenceJustification(reason: reason, note: note);
  }

  PresenceStatus get status => mark.status;

  /// Une ligne porte un motif que cette tablette ne sait pas réécrire : la
  /// renvoyer telle quelle est impossible (cf. [AbsenceReason.unsupported]).
  bool get blocksResend =>
      mark.status.isIncident &&
      mark.justification == null &&
      keptReason == AbsenceReason.unsupported;

  /// Le motif et la précision qui partent au serveur.
  (AbsenceReason?, String?) get wireReason {
    final justification = mark.justification;
    if (justification == null) return (keptReason, keptNote);
    return (justification.reason, justification.note);
  }

  /// La même ligne portant [mark]. Toucher à la justification (en poser une,
  /// la retirer) abandonne ce qui était gardé à part.
  ClassPresenceLine withMark(
    PresenceMark<AbsenceReason> mark, {
    RecordSyncState sync = RecordSyncState.pending,
  }) {
    final keep =
        mark.status.isIncident && mark.justification == this.mark.justification;
    return ClassPresenceLine(
      student: student,
      mark: mark,
      keptReason: keep ? keptReason : null,
      keptNote: keep ? keptNote : null,
      sync: sync,
    );
  }

  @override
  List<Object?> get props => [student, mark, keptReason, keptNote, sync];
}
