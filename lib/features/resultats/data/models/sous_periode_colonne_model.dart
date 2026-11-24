import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/sous_periode_colonne.dart';

part 'sous_periode_colonne_model.g.dart';

@JsonSerializable()
class SousPeriodeColonneModel extends Equatable {
  final String sousPeriodeId;
  final int ordre;

  // Enum conservé en String : converti en domaine via `fromApiValue`.
  final String statut;

  /// Le nom de la colonne donné par la grille ; absents d'un serveur ancien.
  final String? libelle;
  final String? libelleCourt;

  const SousPeriodeColonneModel({
    required this.sousPeriodeId,
    required this.ordre,
    required this.statut,
    this.libelle,
    this.libelleCourt,
  });

  factory SousPeriodeColonneModel.fromJson(Map<String, dynamic> json) =>
      _$SousPeriodeColonneModelFromJson(json);

  Map<String, dynamic> toJson() => _$SousPeriodeColonneModelToJson(this);

  SousPeriodeColonne toEntity() => SousPeriodeColonne(
    sousPeriodeId: sousPeriodeId,
    ordre: ordre,
    statut: StatutPeriodeX.fromApiValue(statut),
    intitule: IntituleColonne.of(libelle, libelleCourt),
  );

  @override
  List<Object?> get props => [
    sousPeriodeId,
    ordre,
    statut,
    libelle,
    libelleCourt,
  ];
}
