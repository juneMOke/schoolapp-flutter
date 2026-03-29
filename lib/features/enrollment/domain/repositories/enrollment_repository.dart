import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/academic_fee.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/paginated_response.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/student_summary.dart';

abstract class EnrollmentRepository {
  Future<Either<Failure, List<StudentSummary>>> getPreRegistrations({
    required String status,
    required String academicYearId,
  });

  Future<Either<Failure, List<StudentSummary>>> searchStudents({
    String? firstName,
    String? lastName,
    String? middleName,
    required String academicYearId,
  });

  Future<Either<Failure, StudentDetail>> getStudentDetail({
    required String enrollmentId,
  });

  Future<Either<Failure, List<SchoolLevelGroup>>> getSchoolLevelGroups({
    required String academicYearId,
  });

  Future<Either<Failure, List<SchoolLevel>>> getSchoolLevels({
    required String levelGroupId,
    required String academicYearId,
  });

  Future<Either<Failure, PaginatedResponse<AcademicFee>>> getAcademicFees({
    required String levelId,
    required String academicYearId,
    required int page,
    required int size,
  });
}
