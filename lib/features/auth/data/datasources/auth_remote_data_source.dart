import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/auth/data/models/login_request_model.dart';
import 'package:school_app_flutter/features/auth/data/models/login_response_model.dart';
import 'package:school_app_flutter/features/auth/data/models/reset_password_request_model.dart';

part 'auth_remote_data_source.g.dart';

@RestApi()
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio, {String baseUrl}) =
      _AuthRemoteDataSource;

  @POST(AppConstants.loginEndpoint)
  Future<LoginResponseModel> login(@Body() LoginRequestModel request);

  @POST(AppConstants.resetPasswordEndpoint)
  Future<void> resetPassword(
    @Body() ResetPasswordRequest request, {
    @Header('X-OTP-Token') required String token,
  });
}
