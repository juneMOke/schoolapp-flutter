import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_academic_year.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';

class Bootstrap extends Equatable {
  final String schoolId;
  final BootstrapAcademicYear academicYear;
  final List<BootstrapSchoolLevelGroupBundle> schoolLevelGroups;

  const Bootstrap({
    required this.schoolId,
    required this.academicYear,
    required this.schoolLevelGroups,
  });

  Bootstrap copyWith({
    String? schoolId,
    BootstrapAcademicYear? academicYear,
    List<BootstrapSchoolLevelGroupBundle>? schoolLevelGroups,
  }) => Bootstrap(
    schoolId: schoolId ?? this.schoolId,
    academicYear: academicYear ?? this.academicYear,
    schoolLevelGroups: schoolLevelGroups ?? this.schoolLevelGroups,
  );

  @override
  List<Object?> get props => [schoolId, academicYear, schoolLevelGroups];
}
