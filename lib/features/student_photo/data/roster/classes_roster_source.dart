import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_classrooms_usecase.dart';
import 'package:school_app_flutter/features/classes/domain/usecases/offline/get_offline_roster_usecase.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';
import 'package:school_app_flutter/features/student_photo/domain/services/class_roster_source.dart';

/// [ClassRosterSource] sur les lectures locales du module Classes : la
/// séance photo parcourt les mêmes classes que l'écran Classes.
class ClassesRosterSource implements ClassRosterSource {
  final GetOfflineClassroomsUseCase _classrooms;
  final GetOfflineRosterUseCase _roster;

  const ClassesRosterSource({
    required GetOfflineClassroomsUseCase classrooms,
    required GetOfflineRosterUseCase roster,
  }) : _classrooms = classrooms,
       _roster = roster;

  @override
  Future<Either<Failure, List<SessionClass>>> classes(
    String academicYearId,
  ) async => (await _classrooms(academicYearId: academicYearId)).map(
    (classrooms) => [
      for (final classroom in classrooms)
        SessionClass(id: classroom.id, name: classroom.name),
    ],
  );

  @override
  Future<Either<Failure, List<SessionStudent>>> roster(
    String classroomId,
  ) async => (await _roster(classroomId: classroomId)).map(
    (members) => [
      for (final member in members)
        SessionStudent(
          id: member.studentId,
          lastName: member.studentLastName,
          middleName: member.studentMiddleName,
          firstName: member.studentFirstName,
        ),
    ],
  );
}
