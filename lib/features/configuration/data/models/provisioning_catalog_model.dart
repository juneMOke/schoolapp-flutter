import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';

part 'provisioning_catalog_model.g.dart';

/// Miroir de `ProvisioningCatalogResponse` côté serveur.
///
/// Les valeurs par défaut ne sont pas de la complaisance : une liste absente y
/// vaut liste vide plutôt qu'exception, parce qu'un catalogue qui gagne un champ
/// ne doit pas fermer l'assistant à toute une release d'appareils.
@JsonSerializable(createToJson: false)
class ProvisioningCatalogModel {
  @JsonKey(defaultValue: '')
  final String version;

  @JsonKey(defaultValue: '')
  final String country;

  @JsonKey(defaultValue: <CatalogCycleModel>[])
  final List<CatalogCycleModel> cycles;

  const ProvisioningCatalogModel({
    required this.version,
    required this.country,
    required this.cycles,
  });

  factory ProvisioningCatalogModel.fromJson(Map<String, dynamic> json) =>
      _$ProvisioningCatalogModelFromJson(json);

  ProvisioningCatalog toEntity() => ProvisioningCatalog(
    version: version,
    country: country,
    // Le serveur sert déjà ses cycles triés, mais l'ordre d'affichage est une
    // donnée du référentiel : s'en remettre à l'ordre du tableau JSON ferait
    // dépendre l'écran d'un détail de sérialisation.
    cycles: (cycles.map((cycle) => cycle.toEntity()).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder))),
  );
}

@JsonSerializable(createToJson: false)
class CatalogCycleModel {
  @JsonKey(defaultValue: '')
  final String code;

  @JsonKey(defaultValue: '')
  final String name;

  final String? periodType;

  @JsonKey(defaultValue: 0)
  final int displayOrder;

  @JsonKey(defaultValue: false)
  final bool defaultSelected;

  @JsonKey(defaultValue: <CatalogLevelModel>[])
  final List<CatalogLevelModel> levels;

  const CatalogCycleModel({
    required this.code,
    required this.name,
    required this.periodType,
    required this.displayOrder,
    required this.defaultSelected,
    required this.levels,
  });

  factory CatalogCycleModel.fromJson(Map<String, dynamic> json) =>
      _$CatalogCycleModelFromJson(json);

  CatalogCycle toEntity() => CatalogCycle(
    code: code,
    name: name,
    periodType: periodType ?? '',
    displayOrder: displayOrder,
    defaultSelected: defaultSelected,
    levels: (levels.map((level) => level.toEntity()).toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder))),
  );
}

@JsonSerializable(createToJson: false)
class CatalogLevelModel {
  @JsonKey(defaultValue: '')
  final String code;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: 0)
  final int displayOrder;

  @JsonKey(defaultValue: false)
  final bool defaultSelected;

  @JsonKey(defaultValue: 1)
  final int defaultClassrooms;

  @JsonKey(defaultValue: <CatalogSectionModel>[])
  final List<CatalogSectionModel> sections;

  @JsonKey(defaultValue: <String>[])
  final List<String> warnings;

  const CatalogLevelModel({
    required this.code,
    required this.name,
    required this.displayOrder,
    required this.defaultSelected,
    required this.defaultClassrooms,
    required this.sections,
    required this.warnings,
  });

  factory CatalogLevelModel.fromJson(Map<String, dynamic> json) =>
      _$CatalogLevelModelFromJson(json);

  CatalogLevel toEntity() => CatalogLevel(
    code: code,
    name: name,
    displayOrder: displayOrder,
    defaultSelected: defaultSelected,
    defaultClassrooms: defaultClassrooms,
    sections: sections.map((section) => section.toEntity()).toList(),
    warnings: warnings,
  );
}

@JsonSerializable(createToJson: false)
class CatalogSectionModel {
  @JsonKey(defaultValue: '')
  final String officialCode;

  final String? filiere;

  /// Peut manquer sur un serveur qui n'a pas encore livré le lot « nommage ».
  /// Son absence ne casse rien : le nom d'une classe est lu du plan, pas
  /// reconstruit — cette valeur ne sert qu'à l'écran « ajouter une classe ».
  final String? filiereAbregee;

  @JsonKey(defaultValue: '')
  final String libelle;

  @JsonKey(defaultValue: '')
  final String codeOfficiel;

  @JsonKey(defaultValue: 0)
  final int courseCount;

  const CatalogSectionModel({
    required this.officialCode,
    required this.filiere,
    required this.filiereAbregee,
    required this.libelle,
    required this.codeOfficiel,
    required this.courseCount,
  });

  factory CatalogSectionModel.fromJson(Map<String, dynamic> json) =>
      _$CatalogSectionModelFromJson(json);

  CatalogSection toEntity() => CatalogSection(
    officialCode: officialCode,
    filiere: filiere,
    filiereAbregee: filiereAbregee,
    libelle: libelle,
    codeOfficiel: codeOfficiel,
    courseCount: courseCount,
  );
}
