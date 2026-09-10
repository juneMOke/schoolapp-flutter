import 'package:equatable/equatable.dart';

/// Sur quel périmètre porte une liste de relance.
///
/// Quatre valeurs **exclusives**. Le libellé du périmètre est résolu par le
/// serveur, jamais envoyé : une tablette ne doit pas pouvoir titrer une liste
/// « 6ème A » en y mettant autre chose.
enum RelanceScopeKind { classroom, schoolLevel, schoolLevelGroup, unassigned }

class RelanceScope extends Equatable {
  final RelanceScopeKind kind;

  /// Identifiant du périmètre. `null` — et seulement — pour
  /// [RelanceScopeKind.unassigned], qui ne désigne aucune entité du
  /// référentiel.
  final String? id;

  const RelanceScope._(this.kind, this.id);

  factory RelanceScope.classroom(String id) =>
      RelanceScope._(RelanceScopeKind.classroom, id);

  factory RelanceScope.schoolLevel(String id) =>
      RelanceScope._(RelanceScopeKind.schoolLevel, id);

  factory RelanceScope.schoolLevelGroup(String id) =>
      RelanceScope._(RelanceScopeKind.schoolLevelGroup, id);

  static const unassigned = RelanceScope._(RelanceScopeKind.unassigned, null);

  @override
  List<Object?> get props => [kind, id];
}
