import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_models.dart';

part 'finance_pull_api.g.dart';

/// Clients des PULL KEYSET Facturation — miroir *lecture* de
/// `openapi_billing_sync.yaml` (ADR-008/009).
///
/// [HttpResponse] pour exposer le statut à l'appelant (le `304 Not Modified`
/// — applicatif, émis sur cycle vide, sans validateur de cache HTTP — arrive
/// comme une [DioException] de statut 304, idiome socle).
///
/// **Jeton unique `cursor`** (contrat 1.1.0) : jeton **opaque base64url**
/// renvoyé VERBATIM (jamais décodé ni recalculé). Le client suit `nextCursor`
/// tant que `hasMore`, puis bascule sur `nextWatermark` en fin de cycle et le
/// repasse sur ce **même** paramètre. Un curseur forgé ou émis pour une autre
/// ressource → 400 (repartir du bootstrap, `cursor` absent). `limit` borné
/// [1, 500] (défaut serveur 100). Le périmètre (école/année) est porté par le JWT.
@RestApi()
abstract class FinancePullApi {
  factory FinancePullApi(Dio dio, {String baseUrl}) = _FinancePullApi;

  /// Créances élèves (le plus gros volume). `studentId` optionnel = restreint à
  /// un élève (rafraîchissement ciblé avant encaissement).
  @GET(AppConstants.syncStudentChargesEndpoint)
  Future<HttpResponse<StudentChargePageDto>> pullStudentCharges(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
    @Query('studentId') String? studentId,
  );

  /// Paiements — y compris ceux de l'autre poste de perception (anti-divergence
  /// de snapshot). Sert la réconciliation, jamais l'affichage (l'UI lit le local).
  @GET(AppConstants.syncPaymentsEndpoint)
  Future<HttpResponse<PaymentPageDto>> pullPayments(
    @Extras() Map<String, dynamic> extras,
    @Query('cursor') String? cursor,
    @Query('limit') int? limit,
    @Query('academicYearId') String? academicYearId,
  );
}
