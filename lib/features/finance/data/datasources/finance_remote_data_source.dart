import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/data/models/fee_tariff_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_recovery_response_model.dart';
import 'package:school_app_flutter/features/finance/data/models/finance_till_response_model.dart';

part 'finance_remote_data_source.g.dart';

@RestApi()
abstract class FinanceRemoteDataSource {
  factory FinanceRemoteDataSource(Dio dio, {String baseUrl}) =
      _FinanceRemoteDataSource;

  @GET(AppConstants.feeTariffsEndpoint)
  Future<List<FeeTariffModel>> listTariffsByLevel(
    @Extras() Map<String, dynamic> extras,
    @Query('levelId') String levelId,
  );

  /// Le recouvrement de l'année scolaire courante.
  ///
  /// **Aucun paramètre de requête**, et c'est le contrat : l'école vient du
  /// jeton, l'année est la courante. Un `period` envoyé par habitude serait
  /// ignoré — la réponse dira toujours `"year"`.
  @GET(AppConstants.financeRecoveryStatsEndpoint)
  Future<FinanceRecoveryResponseModel> getFinanceRecovery(
    @Extras() Map<String, dynamic> extras,
  );

  /// La caisse de la fenêtre — frais scolaires et ventes boutique.
  ///
  /// `period` seul, et c'est délibéré : le serveur accepte aussi une ancre
  /// (`date`, `month`, `week`) pour viser une fenêtre passée, mais l'écran ne
  /// la propose pas encore. Déclarer ici trois paramètres toujours `null`
  /// referait la plomberie dormante que `month` et `week` ont été sur
  /// l'ancienne route : trois ans dans la signature, jamais envoyés une fois,
  /// donc jamais éprouvés. Ils arriveront avec le sélecteur qui les remplit.
  ///
  /// ⚠️ Le jour où ils arrivent : une ancre qui ne correspond pas à la période
  /// part en **400**, pas en repli silencieux — le sélecteur devra remettre
  /// l'ancre à zéro à chaque changement de période.
  @GET(AppConstants.financeTillStatsEndpoint)
  Future<FinanceTillResponseModel> getFinanceTill(
    @Extras() Map<String, dynamic> extras,
    @Query('period') String period,
  );
}
