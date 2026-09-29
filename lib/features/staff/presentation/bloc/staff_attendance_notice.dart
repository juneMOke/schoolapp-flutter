import 'package:equatable/equatable.dart';

/// Ce qu'un geste du Pointage annonce à l'écran (un toast), sans texte : les
/// libellés sont l'affaire de la vue.
enum StaffAttendanceNoticeKind {
  /// « Restants présents » : [StaffAttendanceNotice.count] agents marqués.
  remainingMarked,

  /// Un statut effacé : [StaffAttendanceNotice.name] remis à pointer.
  cleared,
  justified,
  justificationRemoved,
  settingsSaved,
  reportValidated,
  reportReopened,

  /// Un geste refusé sur un jour validé : rouvrir d'abord.
  dayFrozen,

  /// Un geste refusé sur un mois clos.
  monthFrozen,

  /// [StaffAttendanceNotice.month] clos.
  monthClosed,

  /// L'écriture locale a échoué (base, session).
  writeFailed,

  /// Un geste d'écriture sans `hr.attendance.write` : jamais mis en file (un
  /// 403 y serait terminal).
  forbidden,
}

/// Un toast à montrer. [seq] distingue deux annonces identiques successives.
class StaffAttendanceNotice extends Equatable {
  final StaffAttendanceNoticeKind kind;
  final String? name;
  final int? count;

  /// `YYYY-MM`.
  final String? month;
  final int seq;

  const StaffAttendanceNotice(
    this.kind, {
    this.name,
    this.count,
    this.month,
    this.seq = 0,
  });

  StaffAttendanceNotice withSeq(int value) => StaffAttendanceNotice(
    kind,
    name: name,
    count: count,
    month: month,
    seq: value,
  );

  @override
  List<Object?> get props => [kind, name, count, month, seq];
}
