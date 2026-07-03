import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_session_request_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/create_time_slot_request_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/session_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/time_slot_model.dart';
import 'package:school_app_flutter/features/schedule/data/models/weekly_timetable_model.dart';

part 'schedule_remote_data_source.g.dart';

@RestApi()
abstract class ScheduleRemoteDataSource {
  factory ScheduleRemoteDataSource(Dio dio, {String baseUrl}) =
      _ScheduleRemoteDataSource;

  /// Emploi du temps de l'enseignant connecté (résolu côté backend via le JWT).
  ///
  /// On transmet uniquement le marqueur d'authentification via [extras].
  @GET(AppConstants.myTimetableEndpoint)
  Future<WeeklyTimetableModel> getMyTimetable(
    @Extras() Map<String, dynamic> extras,
    @Query('academicYearId') String academicYearId,
  );

  /// Grille d'une classe (surface conseil pédagogique / admin).
  @GET(AppConstants.classroomGridEndpoint)
  Future<WeeklyTimetableModel> getClassroomGrid(
    @Extras() Map<String, dynamic> extras,
    @Query('classroomId') String classroomId,
    @Query('academicYearId') String academicYearId,
  );

  /// Crée un créneau de sonnerie.
  @POST(AppConstants.timeSlotsEndpoint)
  Future<TimeSlotModel> createTimeSlot(
    @Extras() Map<String, dynamic> extras,
    @Body() CreateTimeSlotRequestModel request,
  );

  /// Place un cours à l'emploi du temps.
  @POST(AppConstants.sessionsEndpoint)
  Future<SessionModel> createSession(
    @Extras() Map<String, dynamic> extras,
    @Body() CreateSessionRequestModel request,
  );

  /// Retire une séance (HTTP 204, sans contenu).
  @DELETE(AppConstants.sessionByIdEndpoint)
  Future<void> deleteSession(
    @Extras() Map<String, dynamic> extras,
    @Path('id') String id,
  );
}
