import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';

class GetStudentChargesUseCase {
  final StudentChargesRepository _repository;

  const GetStudentChargesUseCase(this._repository);

  Future<Either<Failure, List<StudentCharge>>> call(
    GetStudentChargesParams params,
  ) => _repository.getStudentCharges(
    studentId: params.studentId,
    levelId: params.levelId,
  );
}

class GetStudentChargesParams extends Equatable {
  final String studentId;
  final String levelId;

  const GetStudentChargesParams({
    required this.studentId,
    required this.levelId,
  });

  @override
  List<Object?> get props => [studentId, levelId];
}

class GetStudentChargesByAcademicYearUseCase {
  final StudentChargesRepository _repository;

  const GetStudentChargesByAcademicYearUseCase(this._repository);

  Future<Either<Failure, List<StudentCharge>>> call(
    GetStudentChargesByAcademicYearParams params,
  ) => _repository.getStudentChargesByAcademicYear(
    studentId: params.studentId,
    academicYearId: params.academicYearId,
  );
}

class GetStudentChargesByAcademicYearParams extends Equatable {
  final String studentId;
  final String academicYearId;

  const GetStudentChargesByAcademicYearParams({
    required this.studentId,
    required this.academicYearId,
  });

  @override
  List<Object?> get props => [studentId, academicYearId];
}
