import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_sous_periode.dart';

/// Ligne « élève » de la table de la vue classe.
///
/// Les lignes arrivent **déjà triées** (rang croissant, non classés en fin) :
/// conserver l'ordre du backend. Un élève sans **aucune** note sur la période a
/// [nonClasse] `true`, avec [rang] / [moyenneGroupe] `null` (rendu « — »), exclu
/// du classement et des stats best/worst.
class ResultatEleveLigne extends Equatable {
  /// Rang dans le classement (ex-aequo = même rang) ; `null` si non classé.
  final int? rang;
  final String studentId;

  /// Nom de famille (lastName).
  final String nom;

  /// Postnom (middleName) ; `null` si absent.
  final String? postnom;

  /// Prénom (firstName).
  final String prenom;
  final ClassroomMemberGender? genre;
  final bool nonClasse;

  /// Un `%` par colonne `sousPeriodes` (aligné index par index).
  final List<ResultatSousPeriode> pourcentages;

  /// `%` de la grande période (= moyenne du bulletin) ; `null` si non classé.
  final double? moyenneGroupe;

  const ResultatEleveLigne({
    this.rang,
    required this.studentId,
    required this.nom,
    this.postnom,
    required this.prenom,
    this.genre,
    required this.nonClasse,
    required this.pourcentages,
    this.moyenneGroupe,
  });

  @override
  List<Object?> get props => [
    rang,
    studentId,
    nom,
    postnom,
    prenom,
    genre,
    nonClasse,
    pourcentages,
    moyenneGroupe,
  ];
}
