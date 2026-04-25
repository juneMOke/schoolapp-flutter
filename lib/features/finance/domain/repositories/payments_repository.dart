import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment.dart';

abstract class PaymentsRepository {
  Future<Either<Failure, List<Payment>>> getPaymentsByStudentAndAcademicYear({
    required String studentId,
    required String academicYearId,
  });
}