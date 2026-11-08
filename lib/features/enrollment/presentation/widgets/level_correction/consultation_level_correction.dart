import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_subject.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';

/// Les niveaux de l'année, chacun avec son cycle, dans l'ordre du référentiel.
List<LevelOption> levelOptionsFromAcademicYearContext(
  AcademicYearContext? context,
) {
  if (context == null) return const [];
  return [
    for (final bundle in context.schoolLevelGroups)
      for (final level in bundle.levels)
        LevelOption(
          id: level.id,
          name: level.name,
          groupId: bundle.group.id,
          groupName: bundle.group.name,
        ),
  ];
}

/// Le nom affiché d'un niveau, l'identifiant brut s'il est inconnu du
/// référentiel local.
String Function(String levelId) levelNameResolver(List<LevelOption> levels) {
  final names = {for (final l in levels) l.id: l.name};
  return (id) => names[id] ?? id;
}

/// Ce que corrige la consultation de [detail] ; `null` quand le dossier ne
/// porte pas de niveau (rien à corriger).
LevelCorrectionSubject? consultationLevelCorrectionSubject(
  LocalEnrollmentDetail detail,
  List<LevelOption> levels,
) {
  final fromLevelId = detail.enrollment.schoolLevelId?.trim() ?? '';
  if (fromLevelId.isEmpty) return null;
  return LevelCorrectionSubject(
    enrollmentId: detail.enrollment.id,
    studentId: detail.student.id,
    academicYearId: detail.enrollment.academicYearId,
    fromSchoolLevelId: fromLevelId,
    fromLevelName: levelNameResolver(levels)(fromLevelId),
  );
}
