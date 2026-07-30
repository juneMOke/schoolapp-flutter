import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/assign_classroom_member_request_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_member_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_model.dart';
import 'package:school_app_flutter/features/classes/data/models/level_distribution_overview_model.dart';
import 'package:school_app_flutter/features/classes/data/models/distribution_request_model.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_stats_response_model.dart';

part 'classroom_remote_data_source.g.dart';

@RestApi()
abstract class ClassroomRemoteDataSource {
  factory ClassroomRemoteDataSource(Dio dio, {String baseUrl}) =
      _ClassroomRemoteDataSource;

  @GET(AppConstants.classroomsEndpoint)
  Future<List<ClassroomModel>> listClassroomsByLevelAndAcademicYear(
    @Extras() Map<String, dynamic> extras,
    @Query('schoolLevelGroupId') String schoolLevelGroupId,
    @Query('schoolLevelId') String schoolLevelId,
    @Query('academicYearId') String academicYearId,
  );

  @GET(AppConstants.classroomMembersEndpoint)
  Future<List<ClassroomMemberModel>> listClassroomMembers(
    @Extras() Map<String, dynamic> extras,
    @Path('classroomId') String classroomId,
    @Query('academicYearId') String academicYearId,
  );

  /// Première affectation d'un élève **non réparti** (201 → membre canonique).
  /// Même chemin que le GET ci-dessus, verbe POST.
  ///
  /// Un non-réparti n'a pas encore de ligne roster, donc pas de
  /// `classroomMemberId` : l'identité transportée est son `enrollmentId`.
  /// Le DÉPLACEMENT d'un membre déjà en classe est un geste distinct, traité
  /// hors ligne par l'événement `classroom_transfers` (outbox), pas ici.
  /// Erreurs métier du contrat : 422 si le niveau de l'inscription diffère de
  /// celui de la classe, 400 si l'inscription a déjà une classe pour l'année.
  @POST(AppConstants.classroomMembersEndpoint)
  Future<ClassroomMemberModel> assignEnrollmentToClassroom(
    @Extras() Map<String, dynamic> extras,
    @Path('classroomId') String classroomId,
    @Body() AssignClassroomMemberRequestModel request,
  );

  @GET(AppConstants.classroomDistributionOverviewEndpoint)
  Future<LevelDistributionOverviewModel> getLevelDistributionOverview(
    @Extras() Map<String, dynamic> extras,
    @Query('academicYearId') String academicYearId,
    @Query('schoolLevelId') String schoolLevelId,
  );

  @GET(AppConstants.classroomStatsEndpoint)
  Future<ClassroomStatsResponseModel> getClassroomStats(
    @Extras() Map<String, dynamic> extras,
  );

  @POST(AppConstants.classroomsDistributeEndpoint)
  Future<void> distributeStudentsToClassrooms(
    @Extras() Map<String, dynamic> extras,
    @Body() DistributionRequestModel request,
  );
}
