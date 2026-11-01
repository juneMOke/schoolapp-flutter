import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

sealed class CoteSaisieEvent extends Equatable {
  const CoteSaisieEvent();

  @override
  List<Object?> get props => const [];
}

/// Ouvre une classe. [scope] et [eleveId] viennent de l'adresse : une portée ou
/// un élève devenus inconnus retombent sur ceux d'ouverture.
final class CoteSaisieOpened extends CoteSaisieEvent {
  final String classroomId;
  final CoteScope? scope;
  final String? eleveId;

  const CoteSaisieOpened(this.classroomId, {this.scope, this.eleveId});

  @override
  List<Object?> get props => [classroomId, scope, eleveId];
}

final class CoteSaisieRetried extends CoteSaisieEvent {
  const CoteSaisieRetried();
}

/// « Changer de classe » : retour à l'invite.
final class CoteSaisieClosed extends CoteSaisieEvent {
  const CoteSaisieClosed();
}

final class CoteScopeChanged extends CoteSaisieEvent {
  final CoteScope scope;

  const CoteScopeChanged(this.scope);

  @override
  List<Object?> get props => [scope];
}

final class CoteStudentSelected extends CoteSaisieEvent {
  final String studentId;

  const CoteStudentSelected(this.studentId);

  @override
  List<Object?> get props => [studentId];
}

final class CoteStudentStepped extends CoteSaisieEvent {
  final int delta;

  const CoteStudentStepped(this.delta);

  @override
  List<Object?> get props => [delta];
}

/// Une frappe, brute : `''`, `'14,5'`, ou un texte hors barème.
final class CoteCellEdited extends CoteSaisieEvent {
  final CoteCellKey key;
  final String raw;

  const CoteCellEdited(this.key, this.raw);

  @override
  List<Object?> get props => [key, raw];
}

/// Renonce à une cote que le serveur a refusée.
final class CoteRejectedDiscarded extends CoteSaisieEvent {
  final CoteCellKey key;

  const CoteRejectedDiscarded(this.key);

  @override
  List<Object?> get props => [key];
}

/// La file vient de se vider : relire ce que le serveur a tranché.
final class CoteCellsRefreshed extends CoteSaisieEvent {
  const CoteCellsRefreshed();
}

final class CoteHighlightCleared extends CoteSaisieEvent {
  const CoteHighlightCleared();
}
