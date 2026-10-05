import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/chapitre_dto.dart';
import 'package:school_app_flutter/features/course_programme/data/sync/programme_push_models.dart';

part 'programme_sync_api.g.dart';

/// Surface JSON du programme de cours : la descente des chapitres d'un cours,
/// et les gestes de la tablette. Les échanges binaires (fichier d'une
/// ressource) sont dans `ProgrammeTransferApi`.
@RestApi()
abstract class ProgrammeSyncApi {
  factory ProgrammeSyncApi(Dio dio, {String baseUrl}) = _ProgrammeSyncApi;

  /// Delta keyset des chapitres d'un cours. `304` → [DioException] 304 ;
  /// `403 COURS_NOT_OWNED` = le cours n'est plus au professeur.
  @GET(AppConstants.syncAcademicsChapitresEndpoint)
  Future<HttpResponse<ChapitrePageDto>> pullChapitres(
    @Extras() Map<String, dynamic> extras,
    @Query('coursId') String coursId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  /// Créer ou modifier la fiche d'un chapitre (le dernier enregistrement
  /// gagne) ; l'accusé porte la fiche retenue et son verdict.
  @POST(AppConstants.syncAcademicsChapitresEndpoint)
  Future<ChapitreFicheAck> saveChapitre(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> fiche,
  );

  /// Supprimer un chapitre — 204, rejouable.
  @DELETE(AppConstants.syncAcademicsChapitreEndpoint)
  Future<void> deleteChapitre(
    @Extras() Map<String, dynamic> extras,
    @Path('chapitreId') String chapitreId,
  );

  /// Réordonner les chapitres d'un cours ; rend l'ordre retenu.
  @PUT(AppConstants.syncAcademicsChapitresOrdreEndpoint)
  Future<ChapitreOrdreAck> reorderChapitres(
    @Extras() Map<String, dynamic> extras,
    @Path('coursId') String coursId,
    @Body() Map<String, dynamic> body,
  );

  /// Ajouter une note de séance — 201, 200 si rejouée.
  @POST(AppConstants.syncAcademicsChapitreNotesEndpoint)
  Future<void> addNote(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );

  /// Supprimer une note de séance — 204, rejouable.
  @DELETE(AppConstants.syncAcademicsChapitreNoteEndpoint)
  Future<void> deleteNote(
    @Extras() Map<String, dynamic> extras,
    @Path('noteId') String noteId,
  );

  /// Retirer une ressource — 204, rejouable.
  @DELETE(AppConstants.syncAcademicsChapitreRessourceEndpoint)
  Future<void> deleteRessource(
    @Extras() Map<String, dynamic> extras,
    @Path('chapitreId') String chapitreId,
    @Path('ressourceId') String ressourceId,
  );
}
