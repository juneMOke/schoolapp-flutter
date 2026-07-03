import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/resultats/data/models/domaine_resultat_model.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/bulletin_domaine.dart';

part 'bulletin_domaine_model.g.dart';

@JsonSerializable(explicitToJson: true)
class BulletinDomaineModel extends Equatable {
  final List<DomaineResultatModel> domaines;
  final double totalObtenu;
  final double totalMax;
  final double pourcentage;

  const BulletinDomaineModel({
    required this.domaines,
    required this.totalObtenu,
    required this.totalMax,
    required this.pourcentage,
  });

  factory BulletinDomaineModel.fromJson(Map<String, dynamic> json) =>
      _$BulletinDomaineModelFromJson(json);

  Map<String, dynamic> toJson() => _$BulletinDomaineModelToJson(this);

  BulletinDomaine toEntity() => BulletinDomaine(
    domaines: domaines
        .map((domaine) => domaine.toEntity())
        .toList(growable: false),
    totalObtenu: totalObtenu,
    totalMax: totalMax,
    pourcentage: pourcentage,
  );

  @override
  List<Object?> get props => [domaines, totalObtenu, totalMax, pourcentage];
}
