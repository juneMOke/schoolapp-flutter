import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/examen_notation_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/sous_periode_notation_model.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';

part 'periode_notation_model.g.dart';

@JsonSerializable(explicitToJson: true)
class PeriodeNotationModel extends Equatable {
  final String periodeScolaireId;
  final int ordre;

  // Enum conservé en String : converti en domaine via `fromApiValue`.
  final String statut;
  final List<SousPeriodeNotationModel> sousPeriodes;
  final ExamenNotationModel? examen;

  const PeriodeNotationModel({
    required this.periodeScolaireId,
    required this.ordre,
    required this.statut,
    required this.sousPeriodes,
    this.examen,
  });

  factory PeriodeNotationModel.fromJson(Map<String, dynamic> json) =>
      _$PeriodeNotationModelFromJson(json);

  Map<String, dynamic> toJson() => _$PeriodeNotationModelToJson(this);

  PeriodeNotation toEntity() => PeriodeNotation(
    periodeScolaireId: periodeScolaireId,
    ordre: ordre,
    statut: StatutPeriodeX.fromApiValue(statut),
    sousPeriodes: sousPeriodes
        .map((sousPeriode) => sousPeriode.toEntity())
        .toList(growable: false),
    examen: examen?.toEntity(),
  );

  @override
  List<Object?> get props => [
    periodeScolaireId,
    ordre,
    statut,
    sousPeriodes,
    examen,
  ];
}
