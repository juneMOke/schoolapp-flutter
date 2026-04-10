import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/student/data/models/student_academic_info_model.dart';
import 'package:school_app_flutter/features/student/data/models/student_detail_model.dart';
import 'package:school_app_flutter/features/student/data/models/update_student_academic_info_request.dart';
import 'package:school_app_flutter/features/student/data/models/update_student_address_request.dart';
import 'package:school_app_flutter/features/student/data/models/update_student_personal_info_request.dart';

part 'student_remote_data_source.g.dart';

@RestApi()
abstract class StudentRemoteDataSource {
  factory StudentRemoteDataSource(Dio dio, {String baseUrl}) =
      _StudentRemoteDataSource;

  @PUT(AppConstants.studentPersonalInfoEndpoint)
  Future<StudentDetailModel> updateStudentPersonalInfo(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Body() UpdateStudentPersonalInfoRequest request,
  );

  @PUT(AppConstants.studentAddressEndpoint)
  Future<StudentDetailModel> updateStudentAddress(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Body() UpdateStudentAddressRequest request,
  );

  @PUT(AppConstants.studentAcademicInfoEndpoint)
  Future<StudentAcademicInfoModel> updateStudentAcademicInfo(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Body() UpdateStudentAcademicInfoRequest request,
  );
}