part of 'school_identity_cubit.dart';

/// État de l'identité de l'établissement courant : ce qui la NOMME ([school])
/// et ce qui la SIGNE ([logo]).
///
/// Pas de statut d'erreur : l'identité est une information d'affichage, et son
/// absence est le seul cas que l'UI ait à traiter — elle se rabat alors sur le
/// nom et le symbole de marque.
///
/// Les deux champs sont **indépendants**. Une école peut être nommée sans sceau
/// (elle n'en a pas déposé), et porter son sceau sans être nommée (`ref_school`
/// décrit une autre école sur une tablette multi-école, alors que le cache de
/// logos, lui, est clavé par école). Aucune surface ne doit donc déduire l'un
/// de l'autre.
class SchoolIdentityState extends Equatable {
  final School? school;

  /// Le sceau de l'école, `null` quand elle n'en a pas ou qu'il n'est pas
  /// encore descendu. Les surfaces de marque retombent alors sur ETEELO.
  final SchoolLogo? logo;

  const SchoolIdentityState({this.school, this.logo});

  const SchoolIdentityState.unknown() : school = null, logo = null;

  bool get isKnown => school != null;

  @override
  List<Object?> get props => [school, logo];
}
