import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_catalog.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_plan.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';

/// Le contrat de la mise en service.
///
/// **Module 100 % en ligne**, sans outbox : la simulation et l'activation le
/// sont par nature, et les comptes affichés viennent toutes du serveur. Le seul
/// état local est le brouillon, qui n'est pas de la synchronisation mais de la
/// reprise de saisie.
abstract class ProvisioningRepository {
  /// Catalogue du système éducatif.
  ///
  /// Mis en cache pour la durée de la session : c'est un référentiel figé,
  /// identique pour toutes les écoles. [forceRefresh] rejoue l'appel — utile
  /// après un 422 « code inconnu », qui signale précisément un cache périmé.
  Future<Either<Failure, ProvisioningCatalog>> loadCatalog({
    bool forceRefresh = false,
  });

  /// Types de frais proposables, mis en cache comme le catalogue.
  Future<Either<Failure, List<FeeCodeOption>>> loadFeeCodes({
    bool forceRefresh = false,
  });

  /// Identité de l'établissement de la session.
  Future<Either<Failure, SchoolIdentity>> loadSchoolIdentity();

  /// Écrit l'identité — PUT complet des huit champs.
  Future<Either<Failure, SchoolIdentity>> saveSchoolIdentity(
    SchoolIdentity identity,
  );

  /// Simule sans rien écrire. Source de tous les chiffres affichés à partir de
  /// l'étape 3.
  Future<Either<Failure, ProvisioningPlan>> simulate(
    ProvisioningRequest request,
  );

  /// Tarifs d'un niveau, après activation.
  Future<Either<Failure, List<FeeTariff>>> loadTariffs(String schoolLevelId);

  /// Crée un tarif sur un niveau.
  Future<Either<Failure, FeeTariff>> createTariff(FeeTariffDraft draft);

  /// Remplace un tarif.
  Future<Either<Failure, FeeTariff>> updateTariff(
    String tariffId,
    FeeTariffDraft draft,
  );

  /// Supprime un tarif.
  Future<Either<Failure, Unit>> deleteTariff(String tariffId);

  /// Active l'établissement : **une transaction, tout ou rien**.
  ///
  /// Cycles, niveaux, classes, cours et tarifs sont écrits ensemble, ou rien ne
  /// l'est. Pas d'appel partiel de rattrapage en cas d'échec.
  Future<Either<Failure, ProvisioningPlan>> activate(
    ProvisioningRequest request,
  );
}
