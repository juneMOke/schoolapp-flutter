import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/course_summary.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';

class GetMyCoursesUseCase {
  final CourseRepository _repository;

  const GetMyCoursesUseCase(this._repository);

  Future<Either<Failure, List<CourseSummary>>> call() =>
      _repository.getMyCourses();
}
