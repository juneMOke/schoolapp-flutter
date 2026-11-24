import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/examen_notation_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/intitule_colonne_json.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
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

  /// `intituleExamen` du fil : absent, `null` ou nommé — trois sens que le
  /// générateur confondrait, d'où la lecture à la main.
  @JsonKey(includeFromJson: false, includeToJson: false)
  final ColonneExamen intituleExamen;

  const PeriodeNotationModel({
    required this.periodeScolaireId,
    required this.ordre,
    required this.statut,
    required this.sousPeriodes,
    this.examen,
    this.intituleExamen = const ColonneExamen.inconnue(),
  });

  factory PeriodeNotationModel.fromJson(Map<String, dynamic> json) {
    final model = _$PeriodeNotationModelFromJson(json);
    return PeriodeNotationModel(
      periodeScolaireId: model.periodeScolaireId,
      ordre: model.ordre,
      statut: model.statut,
      sousPeriodes: model.sousPeriodes,
      examen: model.examen,
      intituleExamen: colonneExamenFromJson(json, 'intituleExamen'),
    );
  }

  Map<String, dynamic> toJson() => _$PeriodeNotationModelToJson(this);

  PeriodeNotation toEntity() => PeriodeNotation(
    periodeScolaireId: periodeScolaireId,
    ordre: ordre,
    statut: StatutPeriodeX.fromApiValue(statut),
    sousPeriodes: sousPeriodes
        .map((sousPeriode) => sousPeriode.toEntity())
        .toList(growable: false),
    examen: examen?.toEntity(),
    intituleExamen: intituleExamen,
  );

  @override
  List<Object?> get props => [
    periodeScolaireId,
    ordre,
    statut,
    sousPeriodes,
    examen,
    intituleExamen,
  ];
}
