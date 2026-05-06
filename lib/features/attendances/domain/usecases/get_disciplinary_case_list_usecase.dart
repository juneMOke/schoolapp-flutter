import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';

class GetDisciplinaryCaseListUseCase {
  final DisciplinaryCaseRepository _repository;

  const GetDisciplinaryCaseListUseCase(this._repository);

  Future<Either<Failure, List<DisciplinaryCaseSummary>>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.getDisciplinaryCaseList(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
