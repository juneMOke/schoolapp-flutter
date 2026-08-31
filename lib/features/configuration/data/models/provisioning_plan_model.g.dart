// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provisioning_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProvisioningPlanModel _$ProvisioningPlanModelFromJson(
  Map<String, dynamic> json,
) => ProvisioningPlanModel(
  dryRun: json['dryRun'] as bool? ?? false,
  academicYearId: json['academicYearId'] as String?,
  academicYearName: json['academicYearName'] as String?,
  counts: json['counts'] == null
      ? null
      : ProvisioningCountsModel.fromJson(
          json['counts'] as Map<String, dynamic>,
        ),
  cycles:
      (json['cycles'] as List<dynamic>?)
          ?.map((e) => PlannedCycleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  fees:
      (json['fees'] as List<dynamic>?)
          ?.map((e) => PlannedFeeModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  warnings:
      (json['warnings'] as List<dynamic>?)
          ?.map(
            (e) => ProvisioningWarningModel.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

ProvisioningCountsModel _$ProvisioningCountsModelFromJson(
  Map<String, dynamic> json,
) => ProvisioningCountsModel(
  cycles: (json['cycles'] as num?)?.toInt() ?? 0,
  levels: (json['levels'] as num?)?.toInt() ?? 0,
  classrooms: (json['classrooms'] as num?)?.toInt() ?? 0,
  courses: (json['courses'] as num?)?.toInt() ?? 0,
  fees: (json['fees'] as num?)?.toInt() ?? 0,
);

PlannedCycleModel _$PlannedCycleModelFromJson(Map<String, dynamic> json) =>
    PlannedCycleModel(
      catalogCode: json['catalogCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      periodType: json['periodType'] as String?,
      id: json['id'] as String?,
      levels:
          (json['levels'] as List<dynamic>?)
              ?.map(
                (e) => PlannedLevelModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

PlannedLevelModel _$PlannedLevelModelFromJson(Map<String, dynamic> json) =>
    PlannedLevelModel(
      catalogCode: json['catalogCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      id: json['id'] as String?,
      classrooms:
          (json['classrooms'] as List<dynamic>?)
              ?.map(
                (e) =>
                    PlannedClassroomModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

PlannedClassroomModel _$PlannedClassroomModelFromJson(
  Map<String, dynamic> json,
) => PlannedClassroomModel(
  name: json['name'] as String? ?? '',
  id: json['id'] as String?,
  officialCode: json['officialCode'] as String?,
  filiere: json['filiere'] as String?,
  grilleId: json['grilleId'] as String?,
  courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
);

PlannedFeeModel _$PlannedFeeModelFromJson(Map<String, dynamic> json) =>
    PlannedFeeModel(
      feeCode: json['feeCode'] as String? ?? '',
      label: json['label'] as String?,
      amountInCents: (json['amountInCents'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      dueAt: json['dueAt'] as String?,
      levelCatalogCode: json['levelCatalogCode'] as String?,
      id: json['id'] as String?,
    );

ProvisioningWarningModel _$ProvisioningWarningModelFromJson(
  Map<String, dynamic> json,
) => ProvisioningWarningModel(
  code: json['code'] as String? ?? '',
  catalogCode: json['catalogCode'] as String?,
  message: json['message'] as String? ?? '',
);
