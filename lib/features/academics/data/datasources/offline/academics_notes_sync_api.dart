import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/notes_batch_push_models.dart';

part 'academics_notes_sync_api.g.dart';

/// Client de push d'un lot de notes (régime C) — `{authorId?, evaluationId,
/// notes[]}` vers `POST /api/v1/sync/academics/notes`. **Toujours 200** : la
/// réponse porte un **outcome par ligne** (APPLIED / SUPERSEDED / REJECTED). Une
/// note sur période close ne fait jamais échouer le lot. Datasource dédiée
/// offline : n'altère pas le contrat online.
@RestApi()
abstract class AcademicsNotesSyncApi {
  factory AcademicsNotesSyncApi(Dio dio, {String baseUrl}) =
      _AcademicsNotesSyncApi;

  @POST(AppConstants.syncAcademicsNotesEndpoint)
  Future<NotesBatchResponseModel> submitNotes(
    @Extras() Map<String, dynamic> extras,
    @Body() NotesBatchPushRequestModel request,
  );
}
