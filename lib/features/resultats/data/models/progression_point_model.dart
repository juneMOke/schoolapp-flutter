import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/progression_point.dart';

part 'progression_point_model.g.dart';

@JsonSerializable()
class ProgressionPointModel extends Equatable {
  final String sousPeriodeId;
  final int indexGlobal;
  final int periodeOrdre;
  final int sousPeriodeOrdre;
  final double? pourcentage;

  // Enum conservé en String : converti en domaine via `fromApiValue`.
  final String statut;
  final bool dansGroupe;

  const ProgressionPointModel({
    required this.sousPeriodeId,
    required this.indexGlobal,
    required this.periodeOrdre,
    required this.sousPeriodeOrdre,
    this.pourcentage,
    required this.statut,
    required this.dansGroupe,
  });

  factory ProgressionPointModel.fromJson(Map<String, dynamic> json) =>
      _$ProgressionPointModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProgressionPointModelToJson(this);

  ProgressionPoint toEntity() => ProgressionPoint(
    sousPeriodeId: sousPeriodeId,
    indexGlobal: indexGlobal,
    periodeOrdre: periodeOrdre,
    sousPeriodeOrdre: sousPeriodeOrdre,
    pourcentage: pourcentage,
    statut: StatutPeriodeX.fromApiValue(statut),
    dansGroupe: dansGroupe,
  );

  @override
  List<Object?> get props => [
    sousPeriodeId,
    indexGlobal,
    periodeOrdre,
    sousPeriodeOrdre,
    pourcentage,
    statut,
    dansGroupe,
  ];
}
