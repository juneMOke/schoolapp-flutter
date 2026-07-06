import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_delta_model.dart';

part 'classroom_sync_api.g.dart';

/// Client du pull delta des classes (CF2). Miroir back CB-2 — l'endpoint
/// `/api/v1/sync/classrooms` n'existe pas encore côté serveur ; câblé côté
/// client conformément à la spec, testé en unitaire avec Dio mocké.
@RestApi()
abstract class ClassroomSyncApi {
  factory ClassroomSyncApi(Dio dio, {String baseUrl}) = _ClassroomSyncApi;

  /// Delta des `ref_classrooms` + `ref_classroom_members` modifiés depuis
  /// [updatedSince] (epoch ms, `null` = pull initial complet). 304 Not Modified
  /// honoré côté repository (delta minimal).
  @GET(AppConstants.syncClassroomsEndpoint)
  Future<ClassroomDeltaModel> pullClassrooms(
    @Extras() Map<String, dynamic> extras,
    @Query('academicYearId') String academicYearId,
    @Query('updatedSince') int? updatedSince,
  );
}
