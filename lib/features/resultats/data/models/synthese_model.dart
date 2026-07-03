import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/synthese.dart';

part 'synthese_model.g.dart';

@JsonSerializable()
class SyntheseModel extends Equatable {
  final double? pourcentage;
  final int? place;
  final int nbClasses;

  /// Toujours `null` en V1 (hors périmètre) : conservé tel quel, pas une erreur.
  final String? application;

  /// Toujours `null` en V1 (hors périmètre) : conservé tel quel, pas une erreur.
  final String? conduite;

  const SyntheseModel({
    this.pourcentage,
    this.place,
    required this.nbClasses,
    this.application,
    this.conduite,
  });

  factory SyntheseModel.fromJson(Map<String, dynamic> json) =>
      _$SyntheseModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyntheseModelToJson(this);

  Synthese toEntity() => Synthese(
    pourcentage: pourcentage,
    place: place,
    nbClasses: nbClasses,
    application: application,
    conduite: conduite,
  );

  @override
  List<Object?> get props => [
    pourcentage,
    place,
    nbClasses,
    application,
    conduite,
  ];
}
