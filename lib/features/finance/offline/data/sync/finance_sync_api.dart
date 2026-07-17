import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

part 'finance_sync_api.g.dart';

/// Interface Dart de l'agrégat paiement (FF-Lot 2/4) :
/// - POST `/api/v1/sync/payments` — push idempotent de l'encaissement
///   (`openapi_billing_sync` §submitPayment) ;
/// - GET pull de la grille tarifaire (`/api/v1/sync/finance/tariffs`).
///
/// Le grand-livre (créances / paiements) se tire par [FinancePullApi] — contrat
/// keyset `openapi_billing_sync` (ADR-008/009), en masse comme au point read.
@RestApi()
abstract class FinanceSyncApi {
  factory FinanceSyncApi(Dio dio, {String baseUrl}) = _FinanceSyncApi;

  /// **Idempotent sur `payment.id`** (uuid client honoré) : un rejeu après
  /// coupure ne compte JAMAIS l'argent deux fois. `201` = enregistré, `200` =
  /// rejeu (mêmes valeurs canoniques) — les deux sont des succès pour Retrofit,
  /// et l'ACK s'applique à l'identique. Jamais de rejet métier : un trop-perçu
  /// est accepté puis signalé (`overpayment`).
  @POST(AppConstants.syncPaymentsEndpoint)
  Future<PaymentAggregateResponse> commitPayment(
    @Extras() Map<String, dynamic> extras,
    @Body() PaymentAggregateRequest request,
  );

  @GET(AppConstants.syncFinanceTariffsEndpoint)
  Future<FeeTariffDelta> pullTariffs(
    @Extras() Map<String, dynamic> extras,
    @Query('academicYearId') String academicYearId,
    @Query('updatedSince') int? updatedSince,
  );
}
