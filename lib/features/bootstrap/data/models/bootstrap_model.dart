import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_academic_year_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_group_bundle_model.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap.dart';

class BootstrapModel {
  final String schoolId;
  final BootstrapAcademicYearModel currentAcademicYear;
  final List<BootstrapSchoolLevelGroupBundleModel> schoolLevelGroups;

  const BootstrapModel({
    required this.schoolId,
    required this.currentAcademicYear,
    required this.schoolLevelGroups,
  });

  factory BootstrapModel.fromJson(Map<String, dynamic> json) {
    return BootstrapModel(
      schoolId: (json['schoolId'] as String?) ?? '',
      currentAcademicYear: BootstrapAcademicYearModel.fromJson(
        json['currentAcademicYear'] as Map<String, dynamic>,
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
    'currentAcademicYear': currentAcademicYear.toJson(),
    'schoolLevelGroups': schoolLevelGroups
        .map((item) => item.toJson())
        .toList(),
  };

  BootstrapModel withSchoolId(String value) {
    return BootstrapModel(
      schoolId: value,
      currentAcademicYear: currentAcademicYear,
      schoolLevelGroups: schoolLevelGroups,
    );
  }

  Bootstrap toEntity() {
    return Bootstrap(
      schoolId: schoolId,
      currentAcademicYear: currentAcademicYear.toEntity(),
      schoolLevelGroups: schoolLevelGroups
          .map((item) => item.toEntity())
          .toList(),
    );
  }
}
