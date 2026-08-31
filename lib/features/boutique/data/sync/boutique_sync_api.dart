import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_pull_models.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_sync_models.dart';

part 'boutique_sync_api.g.dart';

/// Surface réseau de la caisse boutique.
///
/// **Le catalogue n'est pas ici** : il descend dans la section
/// `boutiqueArticles` du bundle référentiel. Cette interface ne porte que
/// l'argent et sa pièce.
@RestApi()
abstract class BoutiqueSyncApi {
  factory BoutiqueSyncApi(Dio dio, {String baseUrl}) = _BoutiqueSyncApi;

  /// **Idempotent sur `sale.id`** (uuid client honoré) : un rejeu après coupure
  /// ne compte JAMAIS l'argent deux fois. `201` = enregistrée, `200` = rejeu
  /// (mêmes valeurs canoniques) — les deux sont des succès pour Retrofit, et
  /// l'ACK s'applique à l'identique.
  ///
  /// **Jamais de rejet métier** : un écart de prix, un catalogue devenu muet ou
  /// une devise changée ressortent en 201 avec une divergence signalée. Les
  /// seuls 422 sont des erreurs techniques — donc des bugs client.
  ///
  /// Exige `boutique.sale.write` **et** `editique.write` : soumettre une vente,
  /// c'est aussi faire sceller une pièce.
  @POST(AppConstants.syncBoutiqueSalesEndpoint)
  Future<BoutiqueSaleResponse> commitSale(
    @Extras() Map<String, dynamic> extras,
    @Body() BoutiqueSaleRequest request,
  );

  /// Delta des ventes de l'année — **dont celles de l'autre guichet**.
  ///
  /// Deux choses ne se produisent jamais sans lui : le total de caisse d'un
  /// poste ne compte que ses propres ventes, et un `receiptDocumentId` scellé
  /// après coup ne redescend pas — le poste garderait un ticket provisoire pour
  /// une pièce qui existe.
  ///
  /// **304 = rien de neuf** (sans corps), à ne pas confondre avec
  /// `hasMore: false`, qui est la dernière page d'un cycle NON vide.
  ///
  /// Le catalogue, lui, **ne descend pas ici** : il est une section du socle
  /// référentiel.
  @GET(AppConstants.syncBoutiqueSalesEndpoint)
  Future<HttpResponse<BoutiqueSalePageDto>> pullSales(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
  );

  /// Réclame (ou réimprime) le reçu de vente scellé — rend les **octets** du
  /// PDF, et pose l'en-tête `X-Document-Id`.
  ///
  /// **La sortie du cas que l'écran ne pouvait pas traiter** : le scellement au
  /// push est best-effort, et l'ACK peut rendre `documents: []` sur un 201
  /// parfaitement en ligne. Sans cette route, la promesse « la caisse
  /// récupérera le scellé » n'était tenue par rien.
  ///
  /// **Idempotente sous verrou** : la rejouer ne brûle pas un second numéro de
  /// séquence. Elle est donc sans danger à appeler en boucle depuis un poste qui
  /// rattrape sa file.
  ///
  /// Exige les deux mêmes permissions que l'encaissement — réclamer un reçu
  /// n'est pas un geste plus léger, c'est le même scellement.
  @POST(AppConstants.emitBoutiqueSaleReceiptEndpoint)
  @DioResponseType(ResponseType.bytes)
  Future<HttpResponse<Uint8List>> emitSaleReceipt(
    @Extras() Map<String, dynamic> extras,
    @Path('saleId') String saleId,
  );
}
