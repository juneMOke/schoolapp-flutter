// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'synthese_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyntheseModel _$SyntheseModelFromJson(Map<String, dynamic> json) =>
    SyntheseModel(
      pourcentage: (json['pourcentage'] as num?)?.toDouble(),
      place: (json['place'] as num?)?.toInt(),
      nbClasses: (json['nbClasses'] as num).toInt(),
      application: json['application'] as String?,
      conduite: json['conduite'] as String?,
    );

Map<String, dynamic> _$SyntheseModelToJson(SyntheseModel instance) =>
    <String, dynamic>{
      'pourcentage': instance.pourcentage,
      'place': instance.place,
      'nbClasses': instance.nbClasses,
      'application': instance.application,
      'conduite': instance.conduite,
    };
