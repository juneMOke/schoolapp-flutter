import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_bundle_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_school_level_group_model.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';

class BootstrapSchoolLevelGroupBundleModel {
  final BootstrapSchoolLevelGroupModel schoolLevelGroup;
  final List<BootstrapSchoolLevelBundleModel> schoolLevels;

  const BootstrapSchoolLevelGroupBundleModel({
    required this.schoolLevelGroup,
    required this.schoolLevels,
  });

  factory BootstrapSchoolLevelGroupBundleModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return BootstrapSchoolLevelGroupBundleModel(
      schoolLevelGroup: BootstrapSchoolLevelGroupModel.fromJson(
        json['schoolLevelGroup'] as Map<String, dynamic>,
      ),
      schoolLevels: (json['schoolLevels'] as List<dynamic>? ?? const [])
          .map(
            (item) => BootstrapSchoolLevelBundleModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'schoolLevelGroup': schoolLevelGroup.toJson(),
    'schoolLevels': schoolLevels.map((item) => item.toJson()).toList(),
  };

  BootstrapSchoolLevelGroupBundle toEntity() {
    return BootstrapSchoolLevelGroupBundle(
      schoolLevelGroup: schoolLevelGroup.toEntity(),
      schoolLevels: schoolLevels.map((item) => item.toEntity()).toList(),
    );
  }
}
