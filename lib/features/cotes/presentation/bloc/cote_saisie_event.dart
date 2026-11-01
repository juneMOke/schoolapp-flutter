import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';

sealed class CoteSaisieEvent extends Equatable {
  const CoteSaisieEvent();

  @override
  List<Object?> get props => const [];
}

/// Ouvre une classe. [scope] et [eleveId] viennent de l'adresse : une portée ou
/// un élève devenus inconnus retombent sur ceux d'ouverture. [singleColumn] :
/// sur téléphone, on ouvre sur une colonne plutôt que sur un groupe.
final class CoteSaisieOpened extends CoteSaisieEvent {
  final String classroomId;
  final CoteScope? scope;
  final String? eleveId;
  final bool singleColumn;

  const CoteSaisieOpened(
    this.classroomId, {
    this.scope,
    this.eleveId,
    this.singleColumn = false,
  });

  @override
  List<Object?> get props => [classroomId, scope, eleveId, singleColumn];
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

/// Une frappe : l'écran recalcule, rien n'est écrit. [base] est la cellule à
/// l'arrivée du focus, sans quoi « 2 » en route vers « 25 » compterait comme une
/// saisie.
final class CoteCellTyped extends CoteSaisieEvent {
  final CoteCellKey key;
  final String raw;
  final CoteCell base;

  const CoteCellTyped(this.key, this.raw, this.base);

  @override
  List<Object?> get props => [key, raw, base];
}

/// La case est quittée : ce qui y reste s'écrit, comparé à [base].
final class CoteCellCommitted extends CoteSaisieEvent {
  final CoteCellKey key;
  final String raw;
  final CoteCell base;

  const CoteCellCommitted(this.key, this.raw, this.base);

  @override
  List<Object?> get props => [key, raw, base];
}

/// Échap : la cellule revient à [base], rien n'a été écrit.
final class CoteCellReverted extends CoteSaisieEvent {
  final CoteCell base;

  const CoteCellReverted(this.base);

  @override
  List<Object?> get props => [base];
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
