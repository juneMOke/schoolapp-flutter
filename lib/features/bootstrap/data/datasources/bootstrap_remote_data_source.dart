import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_model.dart';

part 'bootstrap_remote_data_source.g.dart';

@RestApi()
abstract class BootstrapRemoteDataSource {
  factory BootstrapRemoteDataSource(Dio dio, {String baseUrl}) =
      _BootstrapRemoteDataSource;

  @GET(AppConstants.bootstrapEndpoint)
  Future<BootstrapModel> getBootstrap(
    @Extras() Map<String, dynamic> extras
  );
}
