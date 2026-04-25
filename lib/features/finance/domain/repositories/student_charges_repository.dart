import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';

abstract class StudentChargesRepository {
  Future<Either<Failure, List<StudentCharge>>> getStudentCharges({
    required String studentId,
    required String levelId,
  });

  Future<Either<Failure, List<StudentCharge>>>
  getStudentChargesByAcademicYear({
    required String studentId,
    required String academicYearId,
  });

  Future<Either<Failure, StudentCharge>> updateStudentChargeExpectedAmount({
    required String studentChargeId,
    required String studentId,
    required double expectedAmountInCents,
  });
}
