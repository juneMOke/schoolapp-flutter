import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_push.dart';

part 'journal_sync_api.g.dart';

/// Surface de synchro du journal de classe : la descente des entrées d'un
/// cours et l'envoi d'une saisie.
@RestApi()
abstract class JournalSyncApi {
  factory JournalSyncApi(Dio dio, {String baseUrl}) = _JournalSyncApi;

  /// Delta keyset des entrées d'un cours. `304` → [DioException] 304 ;
  /// `403 COURS_NOT_OWNED` = le cours n'est plus au professeur.
  @GET(AppConstants.syncAcademicsJournalEndpoint)
  Future<HttpResponse<JournalEntryPageDto>> pullEntries(
    @Extras() Map<String, dynamic> extras,
    @Query('coursId') String coursId,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
  );

  /// Envoyer une entrée (le dernier enregistrement gagne) ; l'accusé porte
  /// l'entrée retenue et son verdict.
  @POST(AppConstants.syncAcademicsJournalEndpoint)
  Future<JournalEntryAck> saveEntry(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
  );
}
