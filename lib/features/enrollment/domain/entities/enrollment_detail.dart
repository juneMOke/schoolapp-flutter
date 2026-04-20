import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_school_detail.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/gender.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';

class EnrollmentDetail {
  final StudentDetail studentDetail;
  final List<ParentSummary> parentDetails;
  final EnrollmentSchoolDetail enrollmentDetail;

  EnrollmentDetail({
    required this.studentDetail,
    required this.parentDetails,
    required this.enrollmentDetail,
  });

  factory EnrollmentDetail.empty() => EnrollmentDetail(
    studentDetail: const StudentDetail(
      id: '',
      firstName: '',
      lastName: '',
      surname: '',
      dateOfBirth: '',
      gender: Gender.male,
      birthPlace: '',
      nationality: '',
      photoUrl: null,
      city: '',
      district: '',
      municipality: '',
      address: '',
      schoolLevel: SchoolLevel(id: '', name: '', code: '', displayOrder: 0),
      schoolLevelGroup: SchoolLevelGroup(id: '', name: '', code: ''),
    ),
    parentDetails: const [],
    enrollmentDetail: const EnrollmentSchoolDetail(
      id: '',
      status: EnrollmentStatus.pending,
      academicYearId: '',
      enrollmentCode: '',
      previousSchoolName: '',
      previousAcademicYear: '',
      previousSchoolLevelGroup: '',
      previousSchoolLevel: '',
      previousRate: 0,
      previousRank: null,
      validatedPreviousYear: false,
      schoolLevelGroupId: '',
      schoolLevelId: '',
    ),
  );
}
