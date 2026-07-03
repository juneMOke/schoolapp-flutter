// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_focus_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultatFocusModel _$ResultatFocusModelFromJson(Map<String, dynamic> json) =>
    ResultatFocusModel(
      classroomId: json['classroomId'] as String,
      periodeScolaireId: json['periodeScolaireId'] as String,
      periodeOrdre: (json['periodeOrdre'] as num).toInt(),
      entete: FocusEnteteModel.fromJson(json['entete'] as Map<String, dynamic>),
      progression: (json['progression'] as List<dynamic>)
          .map((e) => ProgressionPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      deltaPts: (json['deltaPts'] as num?)?.toDouble(),
      topMatieres: (json['topMatieres'] as List<dynamic>)
          .map((e) => MatiereScoreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bottomMatieres: (json['bottomMatieres'] as List<dynamic>)
          .map((e) => MatiereScoreModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      bulletinParDomaine: json['bulletinParDomaine'] == null
          ? null
          : BulletinDomaineModel.fromJson(
              json['bulletinParDomaine'] as Map<String, dynamic>,
            ),
      synthese: SyntheseModel.fromJson(
        json['synthese'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ResultatFocusModelToJson(ResultatFocusModel instance) =>
    <String, dynamic>{
      'classroomId': instance.classroomId,
      'periodeScolaireId': instance.periodeScolaireId,
      'periodeOrdre': instance.periodeOrdre,
      'entete': instance.entete.toJson(),
      'progression': instance.progression.map((e) => e.toJson()).toList(),
      'deltaPts': instance.deltaPts,
      'topMatieres': instance.topMatieres.map((e) => e.toJson()).toList(),
      'bottomMatieres': instance.bottomMatieres.map((e) => e.toJson()).toList(),
      'bulletinParDomaine': instance.bulletinParDomaine?.toJson(),
      'synthese': instance.synthese.toJson(),
    };
