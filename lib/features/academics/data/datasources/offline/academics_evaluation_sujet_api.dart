import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/academics_metier_pull_models.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/sujet/sujet_wire_models.dart';

part 'academics_evaluation_sujet_api.g.dart';

/// Client des écritures du sujet d'une évaluation : le sujet et le journal des
/// copies (par l'outbox), les publications (en ligne, jamais rejouées).
@RestApi()
abstract class AcademicsEvaluationSujetApi {
  factory AcademicsEvaluationSujetApi(Dio dio, {String baseUrl}) =
      _AcademicsEvaluationSujetApi;

  /// Remplace le sujet ; rend l'évaluation entière, sujet compris.
  @PUT(AppConstants.syncAcademicsEvaluationSujetEndpoint)
  Future<EvaluationDeltaDto> replaceSujet(
    @Extras() Map<String, dynamic> extras,
    @Path('evaluationId') String evaluationId,
    @Body() Map<String, dynamic> body,
  );

  /// Ajoute une diffusion au journal ; un rejeu rend 200.
  @POST(AppConstants.syncAcademicsEvaluationCopieLogEndpoint)
  Future<EvaluationDeltaDto> logCopie(
    @Extras() Map<String, dynamic> extras,
    @Path('evaluationId') String evaluationId,
    @Body() Map<String, dynamic> body,
  );

  /// Publie le sujet, le corrigé ou les notes ; rend son état
  /// (`PublicationState`).
  @POST(AppConstants.syncAcademicsEvaluationPublicationEndpoint)
  Future<PublicationStateModel> publish(
    @Extras() Map<String, dynamic> extras,
    @Path('evaluationId') String evaluationId,
    @Path('kind') String kind,
  );

  /// Retire une publication (204, même si elle n'existait pas).
  @DELETE(AppConstants.syncAcademicsEvaluationPublicationEndpoint)
  Future<void> withdraw(
    @Extras() Map<String, dynamic> extras,
    @Path('evaluationId') String evaluationId,
    @Path('kind') String kind,
  );
}
