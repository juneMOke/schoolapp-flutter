import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/data/models/generate_otp_request_model.dart';
import 'package:school_app_flutter/features/auth/data/models/validate_otp_request_model.dart';
import 'package:school_app_flutter/features/auth/data/models/validate_otp_response_model.dart';

part 'forgot_password_remote_data_source.g.dart';
@RestApi()
abstract class ForgotPasswordRemoteDataSource {
  factory ForgotPasswordRemoteDataSource(Dio dio, {String baseUrl}) =
      _ForgotPasswordRemoteDataSource;

  @POST(AppConstants.generateOtpEndpoint)
  Future<void> generateOtp(@Body() GenerateOtpRequestModel request);

  @POST(AppConstants.validateOtpEndpoint)
  Future<ValidateOtpResponseModel> validateOtp(
    @Body() ValidateOtpRequestModel request,
  );
}
