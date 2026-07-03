import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';

/// En-tête de la vue focus : identité de l'élève + moyenne annuelle et rang.
///
/// [moyenneAnnuelle] (toutes périodes) et [rang] (parmi les classés du groupe)
/// sont `null` si l'élève n'est pas classé. [nbClasses] = nb d'élèves classés du
/// groupe (dénominateur du rang).
class FocusEntete extends Equatable {
  final String studentId;
  final String nom;
  final String? postnom;
  final String prenom;
  final ClassroomMemberGender? genre;
  final double? moyenneAnnuelle;
  final int? rang;
  final int nbClasses;

  const FocusEntete({
    required this.studentId,
    required this.nom,
    this.postnom,
    required this.prenom,
    this.genre,
    this.moyenneAnnuelle,
    this.rang,
    required this.nbClasses,
  });

  @override
  List<Object?> get props => [
    studentId,
    nom,
    postnom,
    prenom,
    genre,
    moyenneAnnuelle,
    rang,
    nbClasses,
  ];
}
