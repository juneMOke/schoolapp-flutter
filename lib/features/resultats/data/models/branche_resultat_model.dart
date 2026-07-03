import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/branche_resultat.dart';

part 'branche_resultat_model.g.dart';

@JsonSerializable()
class BrancheResultatModel extends Equatable {
  final String ligneBaremeId;
  final String brancheId;
  final String brancheNom;
  final double obtenu;
  final double max;
  final double? pourcentage;

  const BrancheResultatModel({
    required this.ligneBaremeId,
    required this.brancheId,
    required this.brancheNom,
    required this.obtenu,
    required this.max,
    this.pourcentage,
  });

  factory BrancheResultatModel.fromJson(Map<String, dynamic> json) =>
      _$BrancheResultatModelFromJson(json);

  Map<String, dynamic> toJson() => _$BrancheResultatModelToJson(this);

  BrancheResultat toEntity() => BrancheResultat(
    ligneBaremeId: ligneBaremeId,
    brancheId: brancheId,
    brancheNom: brancheNom,
    obtenu: obtenu,
    max: max,
    pourcentage: pourcentage,
  );

  @override
  List<Object?> get props => [
    ligneBaremeId,
    brancheId,
    brancheNom,
    obtenu,
    max,
    pourcentage,
  ];
}
