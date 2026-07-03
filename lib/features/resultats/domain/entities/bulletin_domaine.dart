import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/domaine_resultat.dart';

/// Bulletin par domaine (vue focus) : arbre récursif de domaines + totaux.
///
/// `null` côté [ResultatFocus] quand l'élève focus n'est pas classé sur le
/// groupe. [domaines] arrive déjà ordonné : conserver l'ordre du backend.
class BulletinDomaine extends Equatable {
  final List<DomaineResultat> domaines;
  final double totalObtenu;
  final double totalMax;
  final double pourcentage;

  const BulletinDomaine({
    required this.domaines,
    required this.totalObtenu,
    required this.totalMax,
    required this.pourcentage,
  });

  @override
  List<Object?> get props => [domaines, totalObtenu, totalMax, pourcentage];
}
