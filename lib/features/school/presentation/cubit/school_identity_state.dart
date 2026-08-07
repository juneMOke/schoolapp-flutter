part of 'school_identity_cubit.dart';

/// État de l'identité de l'établissement courant.
///
/// Pas de statut d'erreur : l'identité est une information d'affichage, et son
/// absence ([school] à `null`) est le seul cas que l'UI ait à traiter — elle se
/// rabat alors sur le nom de marque.
class SchoolIdentityState extends Equatable {
  final School? school;

  const SchoolIdentityState({this.school});

  const SchoolIdentityState.unknown() : school = null;

  bool get isKnown => school != null;

  @override
  List<Object?> get props => [school];
}
