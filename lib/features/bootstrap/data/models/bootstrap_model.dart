import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_academic_year_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_group_bundle_model.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';

class BootstrapModel {
  final String schoolId;
  final BootstrapAcademicYearModel academicYear;
  final List<BootstrapSchoolLevelGroupBundleModel> schoolLevelGroups;

  const BootstrapModel({
    required this.schoolId,
    required this.academicYear,
    required this.schoolLevelGroups,
  });

  factory BootstrapModel.fromJson(Map<String, dynamic> json) {
    return BootstrapModel(
      schoolId: (json['schoolId'] as String?) ?? '',
      academicYear: BootstrapAcademicYearModel.fromJson(
        json['academicYear'] as Map<String, dynamic>,
      ),
      schoolLevelGroups:
          (json['schoolLevelGroups'] as List<dynamic>? ?? const [])
              .map(
                (item) => BootstrapSchoolLevelGroupBundleModel.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schoolId': schoolId,
    'academicYear': academicYear.toJson(),
    'schoolLevelGroups': schoolLevelGroups
        .map((item) => item.toJson())
        .toList(),
  };

  BootstrapModel withSchoolId(String value) {
    return BootstrapModel(
      schoolId: value,
      academicYear: academicYear,
      schoolLevelGroups: schoolLevelGroups,
    );
  }

  Bootstrap toEntity() {
    return Bootstrap(
      schoolId: schoolId,
      academicYear: academicYear.toEntity(),
      schoolLevelGroups: schoolLevelGroups
          .map((item) => item.toEntity())
          .toList(),
    );
  }
}
