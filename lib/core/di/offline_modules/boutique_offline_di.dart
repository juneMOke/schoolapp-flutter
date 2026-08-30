import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_history_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_history_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_history_repository.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sale_detail_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_history_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/mark_sale_ticket_printed_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_history_bloc.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_pull_dao.dart';
import 'package:school_app_flutter/features/boutique/data/ticket/sale_ticket_composer.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_sale_write_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_pull_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_pull_handler.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_pull_repository.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_sale_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sale_outbox_handler.dart';
import 'package:school_app_flutter/features/boutique/data/sync/boutique_sync_api.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_sale_repository.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/record_boutique_sale_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_catalog_dao.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_payer_directory_dao.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_payer_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_payer_repository.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/find_boutique_payer_use_case.dart';
import 'package:school_app_flutter/features/boutique/data/repositories/boutique_catalog_repository_impl.dart';
import 'package:school_app_flutter/features/boutique/domain/repositories/boutique_catalog_repository.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/beneficiary_picker_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/boutique_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';

/// Registrar de la branche offline **Boutique** — la caisse point-de-vente
/// (ADR-020). Appelé depuis `registerOfflineModules`.
///
/// **Enregistré AVANT la branche A**, et ce n'est pas cosmétique : le pull du
/// bundle référentiel, qui appartient à `enrollment`, délègue la section
/// `boutiqueArticles` à [BoutiqueCatalogDao] par un seam. Le seam résout
/// paresseusement, donc l'ordre ne casserait rien — mais le lire dans le bon
/// sens évite de chercher qui dépend de qui.
///
/// **Aucune frontière franchie.** `enrollment` n'importe pas `boutique` : il
/// reçoit une fonction. L'isolation du module (invariant I-4) est la raison
/// d'être de la boutique, et c'est par un import « juste pour cette fois »
/// qu'elle commencerait à se défaire.
void registerBoutiqueOffline(GetIt getIt) {
  getIt.registerLazySingleton<BoutiqueCatalogDao>(
    () => BoutiqueCatalogDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<BoutiquePayerDirectoryDao>(
    () => BoutiquePayerDirectoryDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<BoutiquePayerRepository>(
    () => BoutiquePayerRepositoryImpl(
      dao: getIt<BoutiquePayerDirectoryDao>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerFactory<FindBoutiquePayerUseCase>(
    () => FindBoutiquePayerUseCase(getIt<BoutiquePayerRepository>()),
  );
  getIt.registerLazySingleton<BoutiqueCatalogRepository>(
    () => BoutiqueCatalogRepositoryImpl(
      dao: getIt<BoutiqueCatalogDao>(),
      currentUser: getIt<CurrentUserContext>(),
      // Résolu À L'APPEL, jamais capturé : un droit accordé ou retiré en cours
      // de session (refresh, ADR-014 §4) doit changer ce que l'écran montre au
      // rendu suivant, pas au prochain redémarrage.
      permissions: () => getIt<CurrentPermissions>().permissions,
    ),
  );
  getIt.registerFactory<GetBoutiqueCatalogUseCase>(
    () => GetBoutiqueCatalogUseCase(getIt<BoutiqueCatalogRepository>()),
  );
  // `registerFactory`, jamais singleton : le panier vit dans l'état du bloc, et
  // un bloc partagé ferait réapparaître la vente d'un autre écran.
  getIt.registerFactory<BoutiqueBloc>(
    () => BoutiqueBloc(
      getCatalog: getIt<GetBoutiqueCatalogUseCase>(),
      findPayer: getIt<FindBoutiquePayerUseCase>(),
      recordSale: getIt<RecordBoutiqueSaleUseCase>(),
      ids: getIt<IdGenerator>(),
    ),
  );
  // L'année est un PARAMÈTRE, pas une dépendance : elle vient du contexte
  // académique résolu par l'écran, et la capturer ici la figerait au premier
  // montage — survivant à un rollover.
  // ── Encaissement ────────────────────────────────────────────────────────
  getIt.registerLazySingleton<BoutiqueSaleWriteDao>(
    () => BoutiqueSaleWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<BoutiqueSyncApi>(
    () => BoutiqueSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<BoutiqueSaleRepository>(
    () => BoutiqueSaleRepositoryImpl(
      dao: getIt<BoutiqueSaleWriteDao>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      device: getIt<DeviceIdentityService>(),
    ),
  );
  getIt.registerFactory<RecordBoutiqueSaleUseCase>(
    () => RecordBoutiqueSaleUseCase(getIt<BoutiqueSaleRepository>()),
  );

  // ── Historique de caisse ────────────────────────────────────────────────
  // Lecture LOCALE seule : une caisse se consulte le jour où le réseau manque,
  // et c'est aussi ce qui rend les ventes non encore parties visibles ici.
  getIt.registerLazySingleton<BoutiqueSaleHistoryDao>(
    () => BoutiqueSaleHistoryDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<BoutiqueHistoryRepository>(
    () => BoutiqueHistoryRepositoryImpl(
      dao: getIt<BoutiqueSaleHistoryDao>(),
      currentUser: getIt<CurrentUserContext>(),
      now: DateTime.now,
    ),
  );
  getIt.registerFactory<GetBoutiqueSalesHistoryUseCase>(
    () => GetBoutiqueSalesHistoryUseCase(getIt<BoutiqueHistoryRepository>()),
  );
  getIt.registerFactory<GetBoutiqueSaleDetailUseCase>(
    () => GetBoutiqueSaleDetailUseCase(getIt<BoutiqueHistoryRepository>()),
  );
  getIt.registerFactory<MarkSaleTicketPrintedUseCase>(
    () => MarkSaleTicketPrintedUseCase(getIt<BoutiqueHistoryRepository>()),
  );
  // `registerFactory`, jamais singleton : la fenêtre choisie appartient à
  // l'écran ouvert, et un bloc partagé ferait revenir la période d'une visite
  // précédente.
  getIt.registerFactory<BoutiqueHistoryBloc>(
    () => BoutiqueHistoryBloc(
      getHistory: getIt<GetBoutiqueSalesHistoryUseCase>(),
    ),
  );

  getIt.registerFactoryParam<BeneficiaryPickerCubit, String, void>(
    (academicYearId, _) => BeneficiaryPickerCubit(
      search: getIt<SearchLocalEnrollmentsUseCase>(),
      academicYearId: academicYearId,
    ),
  );

  getIt.registerLazySingleton<SaleTicketComposer>(
    () => SaleTicketComposer(getIt<Database>()),
  );

  // ── Pull des ventes ─────────────────────────────────────────────────────
  getIt.registerLazySingleton<BoutiqueSalePullDao>(
    () => BoutiqueSalePullDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<BoutiquePullRepository>(
    () => BoutiquePullRepositoryImpl(
      api: getIt<BoutiqueSyncApi>(),
      dao: getIt<BoutiqueSalePullDao>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      currentUser: getIt<CurrentUserContext>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
      // Résolue À CHAQUE cycle, jamais capturée : une année figée au montage
      // survivrait au rollover, et le poste continuerait de tirer les ventes
      // de l'exercice révolu.
      currentAcademicYearId: () =>
          getIt<EnrollmentReferentialDao>().findCurrentAcademicYearId(
            getIt<CurrentUserContext>().schoolId ?? '',
          ),
    ),
  );
  getIt<PullCoordinator>().registerHandler(
    BoutiqueSalePullHandler(getIt<BoutiquePullRepository>()),
  );

  // ── Handler d'outbox → SyncEngine ───────────────────────────────────────
  //
  // La garde de dépendance est la MÊME sonde que celle du paiement : l'état
  // local de l'inscription de l'élève, scopé année. La recopier ici plutôt que
  // de la partager garderait deux vérités sur la même arête.
  getIt<SyncEngine>().registerHandler(
    BoutiqueSaleOutboxHandler(
      api: getIt<BoutiqueSyncApi>(),
      dao: getIt<BoutiqueSaleWriteDao>(),
      dependency: (studentId, academicYearId) => getIt<EnrollmentReadDao>()
          .studentEnrollmentDependency(studentId, academicYearId),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
}
