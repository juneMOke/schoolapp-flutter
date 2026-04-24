import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/student/data/models/create_parent_request.dart';
import 'package:school_app_flutter/features/student/data/models/parent_summary_model.dart';
import 'package:school_app_flutter/features/student/data/models/update_parent_request.dart';
import 'package:school_app_flutter/features/student/data/models/updated_parent_response.dart';

part 'parent_remote_data_source.g.dart';

@RestApi()
abstract class ParentRemoteDataSource {
  factory ParentRemoteDataSource(Dio dio, {String baseUrl}) =
      _ParentRemoteDataSource;

  @PUT(AppConstants.parentUpdateEndpoint)
  Future<UpdatedParentResponse> updateParent(
    @Extras() Map<String, dynamic> extras,
    @Path('parentId') String parentId,
    @Body() UpdateParentRequest request,
  );

  @POST(AppConstants.parentCreateEndpoint)
  Future<ParentSummaryModel> createParent(
    @Extras() Map<String, dynamic> extras,
    @Body() CreateParentRequest request,
  );

  @DELETE(AppConstants.parentUnlinkEndpoint)
  Future<void> unlinkParent(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Path('parentId') String parentId,
  );
}
