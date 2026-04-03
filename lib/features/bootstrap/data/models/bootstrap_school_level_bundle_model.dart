import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_classroom_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_tariff_model.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_bundle.dart';

class BootstrapSchoolLevelBundleModel {
  final BootstrapSchoolLevelModel schoolLevel;
  final List<BootstrapClassroomModel> classrooms;
  final List<BootstrapTariffModel> tariffs;

  const BootstrapSchoolLevelBundleModel({
    required this.schoolLevel,
    required this.classrooms,
    required this.tariffs,
  });

  factory BootstrapSchoolLevelBundleModel.fromJson(Map<String, dynamic> json) {
    return BootstrapSchoolLevelBundleModel(
      schoolLevel: BootstrapSchoolLevelModel.fromJson(
        json['schoolLevel'] as Map<String, dynamic>,
      ),
      classrooms: (json['classrooms'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                BootstrapClassroomModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      tariffs: (json['tariffs'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                BootstrapTariffModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schoolLevel': schoolLevel.toJson(),
    'classrooms': classrooms.map((item) => item.toJson()).toList(),
    'tariffs': tariffs.map((item) => item.toJson()).toList(),
  };

  BootstrapSchoolLevelBundle toEntity() {
    return BootstrapSchoolLevelBundle(
      schoolLevel: schoolLevel.toEntity(),
      classrooms: classrooms.map((item) => item.toEntity()).toList(),
      tariffs: tariffs.map((item) => item.toEntity()).toList(),
    );
  }
}
