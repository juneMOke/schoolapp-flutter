import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/domain/repositories/offline/classroom_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_summary.dart';

/// Élèves d'un niveau **non affectés à une classe**, calculé 100% hors-ligne
/// (CF3/CF4 — écran d'organisation).
///
/// Diffère du miroir « réellement inscrits l'année courante » de Facturation
/// ([SearchLocalEnrollmentsUseCase.currentYearEnrolled], seule dépendance à
/// l'inscription réutilisée ici) : on soustrait en plus les élèves déjà
/// présents dans les rosters composés du niveau ([ClassroomOfflineRepository
/// .getComposedRosters]) et on ne retient que les dossiers `COMPLETED` (un
/// élève dont l'inscription n'est pas finalisée — ou annulée — n'a pas à
/// être proposé pour une répartition en classe — Facturation ne fait pas ce
/// tri, ne pas reproduire cette restriction là-bas sans le vouloir).
/// `academicYearId` est toujours résolu en amont sur l'année courante
/// (`AcademicYearContextBloc`), donc déjà scopé avant d'atteindre ce usecase.
class GetUnassignedLevelEnrollmentsUseCase {
  final SearchLocalEnrollmentsUseCase _searchEnrollments;
  final ClassroomOfflineRepository _classroomRepository;

  const GetUnassignedLevelEnrollmentsUseCase({
    required SearchLocalEnrollmentsUseCase searchEnrollments,
    required ClassroomOfflineRepository classroomRepository,
  }) : _searchEnrollments = searchEnrollments,
       _classroomRepository = classroomRepository;

  Future<Either<Failure, List<EnrollmentSummary>>> call({
    required String academicYearId,
    required String schoolLevelId,
  }) async {
    final enrolledResult = await _searchEnrollments.currentYearEnrolled(
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
    );
    final rostersResult = await _classroomRepository.getComposedRosters(
      academicYearId: academicYearId,
      schoolLevelId: schoolLevelId,
    );

    return enrolledResult.flatMap(
      (enrolled) => rostersResult.map((rosters) => _diff(enrolled, rosters)),
    );
  }

  List<EnrollmentSummary> _diff(
    List<LocalEnrollmentListItem> enrolled,
    Map<String, List<ClassroomMember>> rostersByClassroom,
  ) {
    final assignedStudentIds = rostersByClassroom.values
        .expand((members) => members)
        .map((member) => member.studentId)
        .toSet();

    // Déduplication par studentId : une anomalie de données (deux dossiers
    // actifs pour le même élève sur la même année) ne doit jamais gonfler
    // l'effectif ni les pastilles G/F affichés.
    final seenStudentIds = <String>{};

    return enrolled
        .where((item) => item.status == OfflineEnrollmentStatus.completed)
        .where((item) => !assignedStudentIds.contains(item.studentId))
        .where((item) => seenStudentIds.add(item.studentId))
        .map(_toEnrollmentSummary)
        .toList(growable: false);
  }

  // Mapping local (pas d'import du mapper de présentation d'Inscription) :
  // garde ce usecase domaine indépendant de la couche présentation d'une
  // autre feature.
  EnrollmentSummary _toEnrollmentSummary(LocalEnrollmentListItem item) =>
      EnrollmentSummary(
        enrollmentId: item.enrollmentId,
        enrollmentCode: item.matriculationNumber ?? '',
        status: item.status.apiValue,
        enrollmentType: item.enrollmentType.apiValue,
        syncState: item.syncState,
        student: StudentSummary(
          id: item.studentId,
          firstName: item.firstName,
          lastName: item.lastName,
          surname: item.surname ?? '',
          dateOfBirth: item.dateOfBirth,
          gender: item.gender == OfflineGender.female
              ? Gender.female
              : Gender.male,
        ),
      );
}
