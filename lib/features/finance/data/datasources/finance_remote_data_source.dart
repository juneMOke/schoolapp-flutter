// `Headers` est déclaré par dio ET par retrofit : ici c'est l'annotation
// retrofit qu'on veut, celle de dio est masquée.
import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';
import 'dart:typed_data';

import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/finance/data/models/fee_tariff_model.dart';
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
    @Query('from') String? from,
    @Query('to') String? to,
  );

  /// Les paiements de la fenêtre, **toutes caisses**, page par page.
  ///
  /// ⚠️ **`currency` n'est délibérément pas envoyée.** Le contrat la porte
  /// toujours — elle cadre la table sur une seule caisse — mais cet écran veut
  /// l'inverse : « tous les paiements de la période ». Absente, le serveur rend
  /// toutes les caisses, chaque ligne portant sa devise.
  ///
  /// Ce mode est sûr **parce que le filtre vit dans la requête**, avec le
  /// `LIMIT` : la page reste pleine, `totalElements` et `withoutReceiptNumber`
  /// restent justes, la pagination ne saute pas. C'est précisément ce qu'un
  /// filtrage côté client après réception ne peut pas tenir — il rendrait une
  /// page de huit réduite à trois.
  ///
  /// ⚠️ **Seconde permission** (`finance.payment.read`) : un porteur du seul
  /// pilotage reçoit 200 sur l'agrégat et **403 ici**. L'appel vit donc dans
  /// son propre BLoC, et son échec ne doit pas emporter les cartes.
  @GET(AppConstants.financeTillReceiptsEndpoint)
  Future<TillReceiptPageModel> getTillReceipts(
    @Extras() Map<String, dynamic> extras,
    @Query('period') String period,
    @Query('page') int page,
    @Query('size') int size,
    @Query('from') String? from,
    @Query('to') String? to,
  );

  /// Le rapport PDF de la fenêtre, **toutes caisses**.
  ///
  /// ⚠️ **`currency` n'est plus envoyée.** Le contrat la porte toujours — elle
  /// cadre le document sur une seule caisse — mais l'écran veut ce que la table
  /// montre : tous les paiements de la période. Absente, le serveur rend les
  /// deux unités, chaque ligne avec la sienne, et le pied porte **un total par
  /// devise** — jamais leur somme, qui serait un nombre que personne ne peut
  /// recompter.
  ///
  /// `HttpResponse` et non `Uint8List` nu : le nom du fichier ne vit que dans
  /// le `Content-Disposition`, et il porte les bornes réellement retenues —
  /// deux rapports de deux journées ne doivent pas s'écraser l'un l'autre dans
  /// le dossier de téléchargement.
  ///
  /// `@DioResponseType(ResponseType.bytes)` est indispensable : sans lui, Dio
  /// tenterait de désérialiser le PDF comme du JSON et lèverait sur le premier
  /// octet. Et l'`Accept` doit couvrir le PDF **et** le JSON du corps d'erreur,
  /// sans quoi le 400 du plafond ressortirait en 500 au corps vide — cf.
  /// [AppConstants.pdfAcceptHeader].
  ///
  /// Aucune ancre (`date`, `week`, `month`) n'est envoyée : l'écran ne cadre
  /// que des périodes **courantes** et des intervalles libres, et le serveur
  /// refuse en 400 une ancre qui ne relève pas de sa période.
  ///
  /// ⚠️ **[options] existe pour une seule raison : le délai.** Le
  /// `receiveTimeout` du client vaut 12 s, calibré sur des réponses JSON de
  /// guichet ; composer ce document prend **plusieurs secondes** sur une
  /// grosse fenêtre. Sans allongement, un rapport mensuel expirerait côté
  /// client pendant que le serveur continue de le produire — et l'appel
  /// suivant se heurterait au 429 du rendu toujours en cours, ce qui rendrait
  /// le geste inexplicable. L'appelant y pose 60 s, le délai que le contrat
  /// recommande.
  @GET(AppConstants.financeTillReceiptsReportEndpoint)
  @DioResponseType(ResponseType.bytes)
  @Headers(<String, String>{'Accept': AppConstants.pdfAcceptHeader})
  Future<HttpResponse<Uint8List>> getTillReceiptsReport(
    @Extras() Map<String, dynamic> extras,
    @Query('period') String period,
    @Query('from') String? from,
    @Query('to') String? to,
    @DioOptions() Options options,
  );
}
