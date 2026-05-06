import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/features/attendances/domain/repository/disciplinary_case_repository.dart';

class CreateDisciplinaryCaseUseCase {
  final DisciplinaryCaseRepository _repository;

  const CreateDisciplinaryCaseUseCase(this._repository);

  Future<Either<Failure, DisciplinaryCaseSummary>> call({
    required String studentId,
    required String studentFirstName,
    required String studentLastName,
    String? studentMiddleName,
    required StudentGender studentGender,
    required DateTime disciplinaryCaseDate,
    required String academicYearId,
    required String title,
    required String content,
  }) => _repository.createDisciplinaryCase(
    studentId: studentId,
    studentFirstName: studentFirstName,
    studentLastName: studentLastName,
    studentMiddleName: studentMiddleName,
    studentGender: studentGender,
    disciplinaryCaseDate: disciplinaryCaseDate,
    academicYearId: academicYearId,
    title: title,
    content: content,
  );
}
