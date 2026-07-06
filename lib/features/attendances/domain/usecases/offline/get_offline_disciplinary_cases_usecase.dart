import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/offline/disciplinary_case_offline_repository.dart';

/// Lecture locale des cas disciplinaires d'un élève (DF-2).
class GetOfflineDisciplinaryCasesUseCase {
  final DisciplinaryCaseOfflineRepository _repository;

  const GetOfflineDisciplinaryCasesUseCase(this._repository);

  Future<Either<Failure, List<OfflineDisciplinaryCase>>> call({
    required String studentId,
    required String academicYearId,
  }) => _repository.getCasesForStudent(
    studentId: studentId,
    academicYearId: academicYearId,
  );
}
