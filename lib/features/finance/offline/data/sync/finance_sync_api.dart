import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_sync_models.dart';

part 'finance_sync_api.g.dart';

/// Interface Dart de l'agrégat paiement + pulls (FF-Lot 2/4).
/// - POST `/api/v1/finance/payments` (enrichi : id client honoré, paidAt, method) ;
/// - GET pull tarifs / ledger (`/api/v1/sync/finance/*`, pending-backend).
@RestApi()
abstract class FinanceSyncApi {
  factory FinanceSyncApi(Dio dio, {String baseUrl}) = _FinanceSyncApi;

  @POST(AppConstants.createPaymentEndpoint)
  Future<PaymentCommitAck> commitPayment(
    @Extras() Map<String, dynamic> extras,
    @Body() CreatePaymentRequest request,
  );

  @GET(AppConstants.syncFinanceTariffsEndpoint)
  Future<FeeTariffDelta> pullTariffs(
    @Extras() Map<String, dynamic> extras,
    @Query('academicYearId') String academicYearId,
    @Query('updatedSince') int? updatedSince,
  );

  @GET(AppConstants.syncFinanceLedgerEndpoint)
  Future<LedgerDelta> pullLedger(
    @Extras() Map<String, dynamic> extras,
    @Query('studentId') String studentId,
    @Query('academicYearId') String academicYearId,
    @Query('updatedSince') int? updatedSince,
  );
}
