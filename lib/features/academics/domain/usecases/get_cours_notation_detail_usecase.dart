import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/repositories/course_repository.dart';

class GetCoursNotationDetailUseCase {
  final CourseRepository _repository;

  const GetCoursNotationDetailUseCase(this._repository);

  Future<Either<Failure, CoursNotationDetail>> call(String coursId) =>
      _repository.getCoursNotationDetail(coursId);
}
