import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/services/class_day_lock.dart';

/// Ce qu'un geste de l'appel annonce à l'écran (un toast), sans texte : les
/// libellés sont l'affaire de la vue.
enum ClassPresenceNoticeKind {
  /// « Restants présents » : [ClassPresenceNotice.count] élèves marqués.
  remainingMarked,

  /// Un statut effacé : [ClassPresenceNotice.name] remis à pointer.
  cleared,
  justified,
  justificationRemoved,

  /// L'appel de [ClassPresenceNotice.name] (la classe) est validé.
  validated,
  reopened,
  retried,

  /// Le mois [ClassPresenceNotice.month] de la classe [ClassPresenceNotice.name]
  /// est clôturé.
  monthClosed,

  /// Un geste refusé sur un appel validé : le rouvrir d'abord.
  dayFrozen,

  /// Le même, pour un compte qui ne peut pas rouvrir un jour passé.
  dayFrozenNoAmend,

  /// Un geste refusé dans un mois clôturé.
  monthFrozen,

  /// Un geste d'écriture sans le droit de faire l'appel : jamais mis en file
  /// (un 403 y serait terminal).
  forbidden,

  /// Un motif inconnu de cette tablette empêche de renvoyer la journée.
  unsupportedReason,

  /// L'écriture locale a échoué.
  writeFailed,

  /// Une écriture concurrente a pris la main : la journée a été relue.
  raced;

  /// L'annonce d'un verrou de journée.
  static ClassPresenceNoticeKind ofLock(ClassDayLock lock) => switch (lock) {
    ClassDayLock.forbidden => forbidden,
    ClassDayLock.monthClosed => monthFrozen,
    ClassDayLock.validated => dayFrozen,
    ClassDayLock.needsAmend => dayFrozenNoAmend,
  };
}

/// Un toast à montrer. [seq] distingue deux annonces identiques successives.
class ClassPresenceNotice extends Equatable {
  final ClassPresenceNoticeKind kind;
  final String? name;
  final int? count;

  /// `YYYY-MM`.
  final String? month;
  final int seq;

  const ClassPresenceNotice(
    this.kind, {
    this.name,
    this.count,
    this.month,
    this.seq = 0,
  });

  ClassPresenceNotice withSeq(int value) => ClassPresenceNotice(
    kind,
    name: name,
    count: count,
    month: month,
    seq: value,
  );

  @override
  List<Object?> get props => [kind, name, count, month, seq];
}
