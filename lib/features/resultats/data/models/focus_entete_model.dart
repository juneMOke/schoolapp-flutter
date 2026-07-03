import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/focus_entete.dart';

part 'focus_entete_model.g.dart';

@JsonSerializable()
class FocusEnteteModel extends Equatable {
  final String studentId;
  final String nom;
  final String? postnom;
  final String prenom;

  // Enum genre partagé conservé en String : converti via `fromApiValue`.
  final String? genre;
  final double? moyenneAnnuelle;
  final int? rang;
  final int nbClasses;

  const FocusEnteteModel({
    required this.studentId,
    required this.nom,
    this.postnom,
    required this.prenom,
    this.genre,
    this.moyenneAnnuelle,
    this.rang,
    required this.nbClasses,
  });

  factory FocusEnteteModel.fromJson(Map<String, dynamic> json) =>
      _$FocusEnteteModelFromJson(json);

  Map<String, dynamic> toJson() => _$FocusEnteteModelToJson(this);

  FocusEntete toEntity() => FocusEntete(
    studentId: studentId,
    nom: nom,
    postnom: postnom,
    prenom: prenom,
    genre: genre == null ? null : ClassroomMemberGender.fromApiValue(genre!),
    moyenneAnnuelle: moyenneAnnuelle,
    rang: rang,
    nbClasses: nbClasses,
  );

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
