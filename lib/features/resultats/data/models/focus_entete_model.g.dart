// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_entete_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FocusEnteteModel _$FocusEnteteModelFromJson(Map<String, dynamic> json) =>
    FocusEnteteModel(
      studentId: json['studentId'] as String,
      nom: json['nom'] as String,
      postnom: json['postnom'] as String?,
      prenom: json['prenom'] as String,
      genre: json['genre'] as String?,
      moyenneAnnuelle: (json['moyenneAnnuelle'] as num?)?.toDouble(),
      rang: (json['rang'] as num?)?.toInt(),
      nbClasses: (json['nbClasses'] as num).toInt(),
    );

Map<String, dynamic> _$FocusEnteteModelToJson(FocusEnteteModel instance) =>
    <String, dynamic>{
      'studentId': instance.studentId,
      'nom': instance.nom,
      'postnom': instance.postnom,
      'prenom': instance.prenom,
      'genre': instance.genre,
      'moyenneAnnuelle': instance.moyenneAnnuelle,
      'rang': instance.rang,
      'nbClasses': instance.nbClasses,
    };
