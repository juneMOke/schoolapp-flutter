import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/data/models/payments_model.dart';

part 'payments_remote_data_source.g.dart';

@RestApi()
abstract class PaymentsRemoteDataSource {
  factory PaymentsRemoteDataSource(Dio dio, {String baseUrl}) =
      _PaymentsRemoteDataSource;

  @GET(AppConstants.listPaymentsByStudentAndAcademicYearEndpoint)
  Future<List<PaymentModel>> listPaymentsByStudentAndAcademicYear(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Path('academicYearId') String academicYearId,
  );
}