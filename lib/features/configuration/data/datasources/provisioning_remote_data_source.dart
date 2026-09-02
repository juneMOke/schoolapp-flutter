import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/configuration/data/models/fee_code_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/fee_tariff_payload_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_catalog_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_plan_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/provisioning_request_model.dart';
import 'package:school_app_flutter/features/configuration/data/models/school_identity_model.dart';

part 'provisioning_remote_data_source.g.dart';

/// Les routes de la mise en service.
///
/// **Aucune ne prend d'identifiant d'école**, sauf `/schools/{schoolId}` : le
/// serveur lit l'école dans le jeton. Et sur celle-là, l'identifiant du chemin
/// est confronté à celui du jeton — un écart rend 403, pas 404.
@RestApi()
abstract class ProvisioningRemoteDataSource {
  factory ProvisioningRemoteDataSource(Dio dio, {String baseUrl}) =
      _ProvisioningRemoteDataSource;

  /// Catalogue du système éducatif. Référentiel figé, identique pour toutes les
  /// écoles — cacheable pour la durée de la session, invalidé sur `version`.
  @GET(AppConstants.provisioningCatalogEndpoint)
  Future<ProvisioningCatalogModel> getCatalog(
    @Extras() Map<String, dynamic> extras,
  );

  /// Les sections de frais de l'école : titre, ordre et visibilité (V115). Le
  /// client n'en filtre aucune — c'est le serveur qui retire les masquées.
  ///
  /// [includeHidden] est réservé à l'écran de nommage, qui doit montrer ce qui
  /// est masqué : sans lui, rétablir une section serait impossible.
  @GET(AppConstants.feeCodesEndpoint)
  Future<List<FeeCodeModel>> getFeeCodes(
    @Extras() Map<String, dynamic> extras,
    @Query('includeHidden') bool includeHidden,
  );

  /// Nomme, classe et masque un lot de sections ; rend le catalogue complet
  /// après coup, masquées comprises.
  @POST(AppConstants.feeCodesEndpoint)
  Future<List<FeeCodeModel>> saveFeeCodeSections(
    @Extras() Map<String, dynamic> extras,
    @Body() FeeCodeSectionsPayloadModel body,
  );

  /// Identité de l'établissement, relue avant l'étape 1 — le formulaire est
  /// pré-rempli, jamais vide : l'école existe déjà.
  @GET(AppConstants.schoolByIdEndpoint)
  Future<SchoolIdentityModel> getSchool(
    @Extras() Map<String, dynamic> extras,
    @Path('schoolId') String schoolId,
  );

  /// PUT complet des huit champs. Seule écriture réelle des quatre premières
  /// étapes.
  @PUT(AppConstants.schoolByIdEndpoint)
  Future<SchoolIdentityModel> updateSchool(
    @Extras() Map<String, dynamic> extras,
    @Path('schoolId') String schoolId,
    @Body() SchoolIdentityModel body,
  );

  /// Tarifs d'un niveau — la lecture des réglages.
  @GET(AppConstants.feeTariffsEndpoint)
  Future<List<FeeTariffResponseModel>> listTariffs(
    @Extras() Map<String, dynamic> extras,
    @Query('levelId') String levelId,
  );

  /// Crée un tarif. **Un tarif = un niveau** : l'assiette de l'assistant
  /// n'existe plus ici.
  @POST(AppConstants.feeTariffsEndpoint)
  Future<FeeTariffResponseModel> createTariff(
    @Extras() Map<String, dynamic> extras,
    @Body() FeeTariffPayloadModel body,
  );

  @PUT('${AppConstants.feeTariffsEndpoint}/{tariffId}')
  Future<FeeTariffResponseModel> updateTariff(
    @Extras() Map<String, dynamic> extras,
    @Path('tariffId') String tariffId,
    @Body() FeeTariffPayloadModel body,
  );

  @DELETE('${AppConstants.feeTariffsEndpoint}/{tariffId}')
  Future<void> deleteTariff(
    @Extras() Map<String, dynamic> extras,
    @Path('tariffId') String tariffId,
  );

  /// Simulation (`dryRun=true`) ou activation (`false`).
  ///
  /// Une seule méthode pour les deux, comme le serveur n'a qu'une route : ce que
  /// la simulation annonce est ce que l'activation écrira, et deux méthodes
  /// distinctes auraient invité à les faire diverger.
  @POST(AppConstants.provisioningApplyEndpoint)
  Future<ProvisioningPlanModel> apply(
    @Extras() Map<String, dynamic> extras,
    @Query('dryRun') bool dryRun,
    @Body() ProvisioningRequestModel body,
  );
}
