import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultat_sous_periode_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';

part 'resultat_eleve_ligne_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ResultatEleveLigneModel extends Equatable {
  final int? rang;
  final String studentId;
  final String nom;
  final String? postnom;
  final String prenom;

  // Enum genre partagé conservé en String : converti via `fromApiValue`.
  final String? genre;
  final bool nonClasse;
  final List<ResultatSousPeriodeModel> pourcentages;
  final double? moyenneGroupe;

  const ResultatEleveLigneModel({
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

  factory ResultatEleveLigneModel.fromJson(Map<String, dynamic> json) =>
      _$ResultatEleveLigneModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResultatEleveLigneModelToJson(this);

  ResultatEleveLigne toEntity() => ResultatEleveLigne(
    rang: rang,
    studentId: studentId,
    nom: nom,
    postnom: postnom,
    prenom: prenom,
    genre: genre == null ? null : ClassroomMemberGender.fromApiValue(genre!),
    nonClasse: nonClasse,
    pourcentages: pourcentages
        .map((cellule) => cellule.toEntity())
        .toList(growable: false),
    moyenneGroupe: moyenneGroupe,
  );

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
