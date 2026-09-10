import 'dart:typed_data';

import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

part 'relance_list_remote_data_source.g.dart';

/// Le **seul appel réseau** du tableau de bord du Recouvrement — et il écrit un
/// document, il ne lit rien.
@RestApi()
abstract class RelanceListRemoteDataSource {
  factory RelanceListRemoteDataSource(Dio dio, {String? baseUrl}) =
      _RelanceListRemoteDataSource;

  /// Émet la liste de relance des lignes qu'on lui donne.
  ///
  /// `@DioResponseType(ResponseType.bytes)` est indispensable : sans lui, Dio
  /// tenterait de désérialiser le PDF comme du JSON et lèverait sur le premier
  /// octet. Et l'`Accept` doit couvrir le PDF **et** le JSON du corps d'erreur,
  /// sans quoi le 400 du plafond ressortirait en 500 au corps vide.
  ///
  /// ⚠️ **[options] existe pour le délai et pour la compression.** Le
  /// `receiveTimeout` du client vaut 12 s, calibré sur du JSON de guichet ;
  /// composer ce document prend plusieurs secondes. Et le corps monte à 1,6 Mio
  /// décompressé au plafond — l'appelant pose donc `Content-Encoding: gzip`,
  /// que le serveur décompresse, pour ramener le téléversement à moins de
  /// 300 Ko sur un canal montant de guichet.
  @POST(AppConstants.recouvrementRelanceListEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> emitRelanceList(
    @Extras() Map<String, dynamic> extras,
    @Body() Map<String, dynamic> body,
    @DioOptions() Options options,
  );
}
