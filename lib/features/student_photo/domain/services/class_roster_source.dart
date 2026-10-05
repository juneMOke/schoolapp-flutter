import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/student_photo/domain/entities/photo_session.dart';

/// Les classes et leurs élèves, tels que la séance photo les parcourt.
///
/// Un port : la photo ne connaît pas le module Classes, c'est la DI qui
/// branche ses lectures locales ici.
abstract class ClassRosterSource {
  /// Les classes de l'année [academicYearId].
  Future<Either<Failure, List<SessionClass>>> classes(String academicYearId);

  /// Les élèves inscrits dans la classe [classroomId].
  Future<Either<Failure, List<SessionStudent>>> roster(String classroomId);
}
