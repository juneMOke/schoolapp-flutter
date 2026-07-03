// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'periode_notation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodeNotationModel _$PeriodeNotationModelFromJson(
  Map<String, dynamic> json,
) => PeriodeNotationModel(
  periodeScolaireId: json['periodeScolaireId'] as String,
  ordre: (json['ordre'] as num).toInt(),
  statut: json['statut'] as String,
  sousPeriodes: (json['sousPeriodes'] as List<dynamic>)
      .map((e) => SousPeriodeNotationModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  examen: json['examen'] == null
      ? null
      : ExamenNotationModel.fromJson(json['examen'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PeriodeNotationModelToJson(
  PeriodeNotationModel instance,
) => <String, dynamic>{
  'periodeScolaireId': instance.periodeScolaireId,
  'ordre': instance.ordre,
  'statut': instance.statut,
  'sousPeriodes': instance.sousPeriodes.map((e) => e.toJson()).toList(),
  'examen': instance.examen?.toJson(),
};
