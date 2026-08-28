import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';

part 'provisioning_plan_model.g.dart';

/// Miroir de `ProvisioningPlan` côté serveur — la réponse de la simulation
/// **et** celle de l'activation, qui sont le même objet par construction.
@JsonSerializable(createToJson: false)
class ProvisioningPlanModel {
  @JsonKey(defaultValue: false)
  final bool dryRun;

  final String? academicYearId;
  final String? academicYearName;

  final ProvisioningCountsModel? counts;

  @JsonKey(defaultValue: <PlannedCycleModel>[])
  final List<PlannedCycleModel> cycles;

  @JsonKey(defaultValue: <PlannedFeeModel>[])
  final List<PlannedFeeModel> fees;

  @JsonKey(defaultValue: <ProvisioningWarningModel>[])
  final List<ProvisioningWarningModel> warnings;

  const ProvisioningPlanModel({
    required this.dryRun,
    required this.academicYearId,
    required this.academicYearName,
    required this.counts,
    required this.cycles,
    required this.fees,
    required this.warnings,
  });

  factory ProvisioningPlanModel.fromJson(Map<String, dynamic> json) =>
      _$ProvisioningPlanModelFromJson(json);

  ProvisioningPlan toEntity() => ProvisioningPlan(
    dryRun: dryRun,
    academicYearId: academicYearId,
    academicYearName: academicYearName,
    // Des comptes absents valent zéro et non « inconnu » : l'écran doit
    // pouvoir afficher un chiffre, et zéro est le seul qui ne promette rien.
    counts: counts?.toEntity() ?? ProvisioningCounts.zero,
    cycles: cycles.map((cycle) => cycle.toEntity()).toList(),
    fees: fees.map((fee) => fee.toEntity()).toList(),
    warnings: warnings.map((warning) => warning.toEntity()).toList(),
  );
}

@JsonSerializable(createToJson: false)
class ProvisioningCountsModel {
  @JsonKey(defaultValue: 0)
  final int cycles;

  @JsonKey(defaultValue: 0)
  final int levels;

  @JsonKey(defaultValue: 0)
  final int classrooms;

  @JsonKey(defaultValue: 0)
  final int courses;

  @JsonKey(defaultValue: 0)
  final int fees;

  const ProvisioningCountsModel({
    required this.cycles,
    required this.levels,
    required this.classrooms,
    required this.courses,
    required this.fees,
  });

  factory ProvisioningCountsModel.fromJson(Map<String, dynamic> json) =>
      _$ProvisioningCountsModelFromJson(json);

  ProvisioningCounts toEntity() => ProvisioningCounts(
    cycles: cycles,
    levels: levels,
    classrooms: classrooms,
    courses: courses,
    fees: fees,
  );
}

@JsonSerializable(createToJson: false)
class PlannedCycleModel {
  @JsonKey(defaultValue: '')
  final String catalogCode;

  @JsonKey(defaultValue: '')
  final String name;

  final String? periodType;
  final String? id;

  @JsonKey(defaultValue: <PlannedLevelModel>[])
  final List<PlannedLevelModel> levels;

  const PlannedCycleModel({
    required this.catalogCode,
    required this.name,
    required this.periodType,
    required this.id,
    required this.levels,
  });

  factory PlannedCycleModel.fromJson(Map<String, dynamic> json) =>
      _$PlannedCycleModelFromJson(json);

  PlannedCycle toEntity() => PlannedCycle(
    catalogCode: catalogCode,
    name: name,
    periodType: periodType,
    id: id,
    levels: levels.map((level) => level.toEntity()).toList(),
  );
}

@JsonSerializable(createToJson: false)
class PlannedLevelModel {
  @JsonKey(defaultValue: '')
  final String catalogCode;

  @JsonKey(defaultValue: '')
  final String name;

  final String? id;

  @JsonKey(defaultValue: <PlannedClassroomModel>[])
  final List<PlannedClassroomModel> classrooms;

  const PlannedLevelModel({
    required this.catalogCode,
    required this.name,
    required this.id,
    required this.classrooms,
  });

  factory PlannedLevelModel.fromJson(Map<String, dynamic> json) =>
      _$PlannedLevelModelFromJson(json);

  PlannedLevel toEntity() => PlannedLevel(
    catalogCode: catalogCode,
    name: name,
    id: id,
    classrooms: classrooms.map((classroom) => classroom.toEntity()).toList(),
  );
}

@JsonSerializable(createToJson: false)
class PlannedClassroomModel {
  @JsonKey(defaultValue: '')
  final String name;

  final String? id;
  final String? officialCode;
  final String? filiere;
  final String? grilleId;

  @JsonKey(defaultValue: 0)
  final int courseCount;

  const PlannedClassroomModel({
    required this.name,
    required this.id,
    required this.officialCode,
    required this.filiere,
    required this.grilleId,
    required this.courseCount,
  });

  factory PlannedClassroomModel.fromJson(Map<String, dynamic> json) =>
      _$PlannedClassroomModelFromJson(json);

  PlannedClassroom toEntity() => PlannedClassroom(
    name: name,
    id: id,
    officialCode: officialCode,
    filiere: filiere,
    grilleId: grilleId,
    courseCount: courseCount,
  );
}

@JsonSerializable(createToJson: false)
class PlannedFeeModel {
  @JsonKey(defaultValue: '')
  final String feeCode;

  final String? label;

  @JsonKey(defaultValue: 0)
  final int amountInCents;

  @JsonKey(defaultValue: 'USD')
  final String currency;

  final String? dueAt;
  final String? levelCatalogCode;
  final String? id;

  const PlannedFeeModel({
    required this.feeCode,
    required this.label,
    required this.amountInCents,
    required this.currency,
    required this.dueAt,
    required this.levelCatalogCode,
    required this.id,
  });

  factory PlannedFeeModel.fromJson(Map<String, dynamic> json) =>
      _$PlannedFeeModelFromJson(json);

  PlannedFee toEntity() => PlannedFee(
    feeCode: feeCode,
    label: label,
    amountInCents: amountInCents,
    currency: currency,
    dueAt: ProvisioningInstant.parse(dueAt),
    levelCatalogCode: levelCatalogCode,
    id: id,
  );
}

@JsonSerializable(createToJson: false)
class ProvisioningWarningModel {
  @JsonKey(defaultValue: '')
  final String code;

  final String? catalogCode;

  @JsonKey(defaultValue: '')
  final String message;

  const ProvisioningWarningModel({
    required this.code,
    required this.catalogCode,
    required this.message,
  });

  factory ProvisioningWarningModel.fromJson(Map<String, dynamic> json) =>
      _$ProvisioningWarningModelFromJson(json);

  ProvisioningWarning toEntity() => ProvisioningWarning(
    code: code,
    catalogCode: catalogCode,
    message: message,
  );
}
