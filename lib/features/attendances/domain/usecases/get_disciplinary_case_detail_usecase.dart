import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';

class GetDisciplinaryCaseDetailUseCase {
  final DisciplinaryCaseRepository _repository;

  const GetDisciplinaryCaseDetailUseCase(this._repository);

  Future<Either<Failure, DisciplinaryCaseDetail>> call({
    required String caseId,
  }) => _repository.getDisciplinaryCaseDetail(caseId: caseId);
}
