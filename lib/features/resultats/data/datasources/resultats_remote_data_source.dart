import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/classes/data/models/classroom_member_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/periode_scolaire_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultat_focus_model.dart';
import 'package:school_app_flutter/features/resultats/data/models/resultats_classe_model.dart';

part 'resultats_remote_data_source.g.dart';

/// Endpoints de la feature **résultats par classe** — tous authentifiés (JWT).
///
/// Le marqueur d'authentification est transmis via [Extras] (comme
/// `getMyCourses`) ; la base URL est gérée par `DioClient` (jamais hardcodée).
@RestApi()
abstract class ResultatsRemoteDataSource {
  factory ResultatsRemoteDataSource(Dio dio, {String baseUrl}) =
      _ResultatsRemoteDataSource;

  /// Vue classe (synthèse + table) — calcul live côté backend.
  @GET(AppConstants.resultatsClasseEndpoint)
  Future<ResultatsClasseModel> getResultatsClasse(
    @Extras() Map<String, dynamic> extras,
    @Query('classroomId') String classroomId,
    @Query('periodeScolaireId') String periodeScolaireId,
    @Query('seuil') double? seuil, // omis par Retrofit si null (défaut back 50)
  );

  /// Vue focus d'un élève — calcul live côté backend.
  @GET(AppConstants.resultatFocusEndpoint)
  Future<ResultatFocusModel> getResultatFocus(
    @Extras() Map<String, dynamic> extras,
    @Path('studentId') String studentId,
    @Query('classroomId') String classroomId,
    @Query('periodeScolaireId') String periodeScolaireId,
  );

  /// Recherche roster scopée classe (mode « Par élève »), ordonnée par le back.
  @GET(AppConstants.classroomMembersSearchEndpoint)
  Future<List<ClassroomMemberModel>> searchRoster(
    @Extras() Map<String, dynamic> extras,
    @Path('classroomId') String classroomId,
    @Query('academicYearId') String academicYearId,
    @Query('nom') String? nom,
    @Query('postnom') String? postnom,
    @Query('prenom') String? prenom,
  );

  /// Grandes périodes d'une classe (source des `periodeScolaireId`), avec la
  /// période courante marquée. Scopé classe : un seul query param `classroomId`.
  @GET(AppConstants.resultatsPeriodesEndpoint)
  Future<List<PeriodeScolaireModel>> getPeriodesScolaires(
    @Extras() Map<String, dynamic> extras,
    @Query('classroomId') String classroomId,
  );
}
