import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/data/models/payment_allocations_model.dart';
import 'package:school_app_flutter/features/finance/data/models/student_charges_model.dart';

part 'student_charges_remote_data_source.g.dart';

@RestApi()
abstract class StudentChargesRemoteDataSource {
  factory StudentChargesRemoteDataSource(Dio dio, {String baseUrl}) =
      _StudentChargesRemoteDataSource;

  @POST(AppConstants.initializeStudentChargesEndpoint)
  Future<List<StudentChargesModel>> initializeChargesForStudent(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Query('levelId') String levelId,
  );

  @GET(AppConstants.listStudentChargesByStudentAndAcademicYearEndpoint)
  Future<List<StudentChargesModel>> listStudentChargesByStudentAndAcademicYear(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Path('academicYearId') String academicYearId,
  );

  @GET(AppConstants.listPaymentAllocationsByChargeIdEndpoint)
  Future<List<PaymentAllocationsModel>> listPaymentAllocationsByChargeId(
    @Extras() Map<String, dynamic> extras,
    @Path('chargeId') String chargeId,
  );

  @PUT(AppConstants.updateStudentChargeExpectedAmountEndpoint)
  Future<StudentChargesModel> updateStudentChargeExpectedAmount(
    @Extras() Map<String, dynamic> extras,
    @Path('studentChargeId') String studentChargeId,
    @Query('studentId') String studentId,
    @Query('expectedAmountInCents') int expectedAmountInCents,
  );
}
