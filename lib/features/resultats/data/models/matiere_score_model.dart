import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/matiere_score.dart';

part 'matiere_score_model.g.dart';

@JsonSerializable()
class MatiereScoreModel extends Equatable {
  final String brancheId;
  final String brancheNom;
  final double? pourcentage;

  const MatiereScoreModel({
    required this.brancheId,
    required this.brancheNom,
    this.pourcentage,
  });

  factory MatiereScoreModel.fromJson(Map<String, dynamic> json) =>
      _$MatiereScoreModelFromJson(json);

  Map<String, dynamic> toJson() => _$MatiereScoreModelToJson(this);

  MatiereScore toEntity() => MatiereScore(
    brancheId: brancheId,
    brancheNom: brancheNom,
    pourcentage: pourcentage,
  );

  @override
  List<Object?> get props => [brancheId, brancheNom, pourcentage];
}
