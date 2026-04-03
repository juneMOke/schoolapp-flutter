import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group.dart';

class BootstrapSchoolLevelGroupBundle extends Equatable {
  final BootstrapSchoolLevelGroup schoolLevelGroup;
  final List<BootstrapSchoolLevelBundle> schoolLevels;

  const BootstrapSchoolLevelGroupBundle({
    required this.schoolLevelGroup,
    required this.schoolLevels,
  });

  @override
  List<Object?> get props => [schoolLevelGroup, schoolLevels];
}
