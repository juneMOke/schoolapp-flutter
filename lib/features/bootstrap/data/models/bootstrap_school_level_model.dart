import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level.dart';

class BootstrapSchoolLevelModel {
  final String id;
  final int version;
  final String name;
  final String code;
  final int displayOrder;

  const BootstrapSchoolLevelModel({
    required this.id,
    required this.version,
    required this.name,
    required this.code,
    required this.displayOrder,
  });

  factory BootstrapSchoolLevelModel.fromJson(Map<String, dynamic> json) {
    return BootstrapSchoolLevelModel(
      id: json['id'] as String,
      version: json['version'] as int? ?? 0,
      name: json['name'] as String,
      code: json['code'] as String,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'name': name,
    'code': code,
    'displayOrder': displayOrder,
  };

  BootstrapSchoolLevel toEntity() {
    return BootstrapSchoolLevel(
      id: id,
      version: version,
      name: name,
      code: code,
      displayOrder: displayOrder,
    );
  }
}
