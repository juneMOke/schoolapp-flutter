/// Ce que corrige un geste « Corriger le niveau » : l'inscription, et le niveau qu'elle porte.
class LevelCorrectionSubject {
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final String fromSchoolLevelId;
  final String fromLevelName;

  const LevelCorrectionSubject({
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.fromSchoolLevelId,
    required this.fromLevelName,
  });
}
