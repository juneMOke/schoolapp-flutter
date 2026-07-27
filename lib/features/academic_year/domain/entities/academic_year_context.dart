import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';

/// Contexte académique résolu localement (référentiel offline) : une année
/// scolaire (courante ou précédente) et ses cycles/niveaux. Remplace le
/// module `bootstrap` (cache Hive online-only) — mêmes données, sourcées
/// depuis `ref_academic_years`/`ref_school_level_groups`/`ref_school_levels`.
class AcademicYearContext extends Equatable {
  final AcademicYear academicYear;
  final List<SchoolLevelGroupBundle> schoolLevelGroups;

  const AcademicYearContext({
    required this.academicYear,
    required this.schoolLevelGroups,
  });

  @override
  List<Object?> get props => [academicYear, schoolLevelGroups];
}
