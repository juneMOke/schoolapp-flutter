// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_eleve_ligne_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultatEleveLigneModel _$ResultatEleveLigneModelFromJson(
  Map<String, dynamic> json,
) => ResultatEleveLigneModel(
  rang: (json['rang'] as num?)?.toInt(),
  studentId: json['studentId'] as String,
  nom: json['nom'] as String,
  postnom: json['postnom'] as String?,
  prenom: json['prenom'] as String,
  genre: json['genre'] as String?,
  nonClasse: json['nonClasse'] as bool,
  pourcentages: (json['pourcentages'] as List<dynamic>)
      .map((e) => ResultatSousPeriodeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  moyenneGroupe: (json['moyenneGroupe'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ResultatEleveLigneModelToJson(
  ResultatEleveLigneModel instance,
) => <String, dynamic>{
  'rang': instance.rang,
  'studentId': instance.studentId,
  'nom': instance.nom,
  'postnom': instance.postnom,
  'prenom': instance.prenom,
  'genre': instance.genre,
  'nonClasse': instance.nonClasse,
  'pourcentages': instance.pourcentages.map((e) => e.toJson()).toList(),
  'moyenneGroupe': instance.moyenneGroupe,
};
