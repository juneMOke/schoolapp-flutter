import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/extreme_eleve.dart';

part 'extreme_eleve_model.g.dart';

@JsonSerializable()
class ExtremeEleveModel extends Equatable {
  final String studentId;
  final String nomComplet;
  final double pourcentage;

  const ExtremeEleveModel({
    required this.studentId,
    required this.nomComplet,
    required this.pourcentage,
  });

  factory ExtremeEleveModel.fromJson(Map<String, dynamic> json) =>
      _$ExtremeEleveModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExtremeEleveModelToJson(this);

  ExtremeEleve toEntity() => ExtremeEleve(
    studentId: studentId,
    nomComplet: nomComplet,
    pourcentage: pourcentage,
  );

  @override
  List<Object?> get props => [studentId, nomComplet, pourcentage];
}
