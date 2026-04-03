import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group.dart';

class BootstrapSchoolLevelGroupModel {
  final String id;
  final int version;
  final String name;
  final String code;
  final String periodType;
  final int displayOrder;

  const BootstrapSchoolLevelGroupModel({
    required this.id,
    required this.version,
    required this.name,
    required this.code,
    required this.periodType,
    required this.displayOrder,
  });

  factory BootstrapSchoolLevelGroupModel.fromJson(Map<String, dynamic> json) {
    return BootstrapSchoolLevelGroupModel(
      id: json['id'] as String,
      version: json['version'] as int? ?? 0,
      name: json['name'] as String,
      code: json['code'] as String,
      periodType: json['periodType'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'name': name,
    'code': code,
    'periodType': periodType,
    'displayOrder': displayOrder,
  };

  BootstrapSchoolLevelGroup toEntity() {
    return BootstrapSchoolLevelGroup(
      id: id,
      version: version,
      name: name,
      code: code,
      periodType: periodType,
      displayOrder: displayOrder,
    );
  }
}
