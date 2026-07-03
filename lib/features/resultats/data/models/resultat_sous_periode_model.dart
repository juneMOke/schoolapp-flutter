import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_sous_periode.dart';

part 'resultat_sous_periode_model.g.dart';

@JsonSerializable()
class ResultatSousPeriodeModel extends Equatable {
  final String sousPeriodeId;

  /// `null` = « non noté » : conservé tel quel, jamais coercé en `0`.
  final double? pourcentage;

  const ResultatSousPeriodeModel({
    required this.sousPeriodeId,
    this.pourcentage,
  });

  factory ResultatSousPeriodeModel.fromJson(Map<String, dynamic> json) =>
      _$ResultatSousPeriodeModelFromJson(json);

  Map<String, dynamic> toJson() => _$ResultatSousPeriodeModelToJson(this);

  ResultatSousPeriode toEntity() => ResultatSousPeriode(
    sousPeriodeId: sousPeriodeId,
    pourcentage: pourcentage,
  );

  @override
  List<Object?> get props => [sousPeriodeId, pourcentage];
}
