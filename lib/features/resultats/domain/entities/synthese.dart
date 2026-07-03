import 'package:equatable/equatable.dart';

/// Synthèse de la vue focus : Pourcentage · Place · Application · Conduite.
///
/// [application] et [conduite] sont **toujours `null` en V1** (hors périmètre,
/// rendu « — ») : ce n'est **pas** une erreur. [pourcentage] / [place] sont
/// `null` si l'élève n'est pas classé. [nbClasses] = dénominateur de la place.
class Synthese extends Equatable {
  final double? pourcentage;
  final int? place;
  final int nbClasses;
  final String? application;
  final String? conduite;

  const Synthese({
    this.pourcentage,
    this.place,
    required this.nbClasses,
    this.application,
    this.conduite,
  });

  @override
  List<Object?> get props => [
    pourcentage,
    place,
    nbClasses,
    application,
    conduite,
  ];
}
