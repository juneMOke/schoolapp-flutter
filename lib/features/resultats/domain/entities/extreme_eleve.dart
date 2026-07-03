import 'package:equatable/equatable.dart';

/// Élève extrême d'une classe (meilleur ou pire) pour la synthèse de classe.
///
/// `null` côté [ResultatsClasseStats] quand aucun élève n'est classé.
class ExtremeEleve extends Equatable {
  final String studentId;
  final String nomComplet;
  final double pourcentage;

  const ExtremeEleve({
    required this.studentId,
    required this.nomComplet,
    required this.pourcentage,
  });

  @override
  List<Object?> get props => [studentId, nomComplet, pourcentage];
}
