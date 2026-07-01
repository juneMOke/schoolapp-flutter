import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/course_summary_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/cours_notation_detail_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/create_evaluation_request_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/evaluation_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/note_eleve_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/note_evaluation_model.dart';
import 'package:school_app_flutter/features/academics/data/models/notation/saisir_note_request_model.dart';

part 'course_remote_data_source.g.dart';

@RestApi()
abstract class CourseRemoteDataSource {
  factory CourseRemoteDataSource(Dio dio, {String baseUrl}) =
      _CourseRemoteDataSource;

  /// Liste les cours de l'enseignant connecté, regroupés par classe.
  ///
  /// L'enseignant est résolu côté backend depuis le sujet du JWT ; on transmet
  /// uniquement le marqueur d'authentification via [extras].
  @GET(AppConstants.myCoursesEndpoint)
  Future<List<CourseSummaryModel>> getMyCourses(
    @Extras() Map<String, dynamic> extras,
  );

  /// Détail de notation d'un cours, groupé par période puis sous-période.
  @GET(AppConstants.coursNotationDetailEndpoint)
  Future<CoursNotationDetailModel> getCoursNotationDetail(
    @Extras() Map<String, dynamic> extras,
    @Path('coursId') String coursId,
  );

  /// Crée une évaluation (interro/devoir/examen) sous le cours [coursId].
  ///
  /// L'école est résolue côté backend depuis le JWT (multi-tenant) ; le corps
  /// porte le type, la date, le barème, le poids et le rattachement temporel.
  @POST(AppConstants.createEvaluationEndpoint)
  Future<EvaluationModel> createEvaluation(
    @Extras() Map<String, dynamic> extras,
    @Path('coursId') String coursId,
    @Body() CreateEvaluationRequestModel request,
  );

  /// Grille de saisie : chaque élève de la classe du cours + sa note (nulle si
  /// pas encore saisie) pour l'évaluation [evaluationId].
  @GET(AppConstants.notesElevesEndpoint)
  Future<List<NoteEleveModel>> getNotesEleves(
    @Extras() Map<String, dynamic> extras,
    @Path('evaluationId') String evaluationId,
  );

  /// Saisit/rattrape (upsert idempotent) la note d'un élève pour l'évaluation
  /// [evaluationId] et renvoie la note persistée.
  @PUT(AppConstants.saisirNoteEndpoint)
  Future<NoteEvaluationModel> saisirNote(
    @Extras() Map<String, dynamic> extras,
    @Path('evaluationId') String evaluationId,
    @Body() SaisirNoteRequestModel request,
  );
}
