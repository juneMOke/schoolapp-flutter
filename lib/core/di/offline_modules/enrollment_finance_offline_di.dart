import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/device/device_identity_service.dart';
import 'package:school_app_flutter/features/boutique/data/local/boutique_catalog_dao.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/coordinator_payments_sync.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/parent_search_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/pre_enrollments_school_guard.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_offline_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_pull_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_pull_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/finalize_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_draft_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_pre_enrollment_use_case.dart';
import 'package:school_app_flutter/features/documents/data/local/provisional_ticket_dao.dart';
import 'package:school_app_flutter/features/documents/data/repositories/provisional_ticket_repository_impl.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/build_provisional_ticket_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/documents_local_dossier_cubit.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/find_cached_document_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/list_cached_documents_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_reenrollment_candidate_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/is_student_known_to_server_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_reenrollment_dossier_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_address_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_guardians_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_identity_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_previous_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_target_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_parents_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/seed_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/start_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/dao/payment_anomaly_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payment_anomalies_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_outbox_handler.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_payments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_student_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_charge_aggregates_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_tariffs_for_level_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/has_fee_grid_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/initialize_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/record_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
// Facturation — redirection des lectures online → local-first (Stratégie C).
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/features/finance/data/datasources/payments_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/datasources/student_charges_remote_data_source.dart';
import 'package:school_app_flutter/features/finance/data/repositories/payments_repository_impl.dart';
import 'package:school_app_flutter/features/finance/data/repositories/student_charges_repository_impl.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/payments_repository.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/student_charges_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/payments_offline_first_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/student_charges_offline_first_repository.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_pull_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/sync_finance_pulls_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_ledger_refresher.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_pull_handler.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payment_receipt_document_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_receipt_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_ledger_freshness_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/refresh_ledger_before_collection_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/watch_ledger_revalidation_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';

/// DI de la branche offline A (Inscription + Facturation).
///
/// Appelé par `registerOfflineModules()` (offline_injection.dart) : enregistre
/// les DataSources locales (DAO), les APIs Retrofit de synchro, les repositories
/// offline-first, les usecases/BLoCs, et branche les 2 handlers d'outbox
/// (ENROLLMENT, PAYMENT) sur le `SyncEngine` du socle.
void registerEnrollmentFinanceOffline(GetIt getIt) {
  // ── DAO locaux (sqflite) ────────────────────────────────────────────────────
  // Inscription : DAO séparés par responsabilité (lecture / draft / ack / ref).
  getIt.registerLazySingleton<EnrollmentReadDao>(
    () => EnrollmentReadDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentDraftDao>(
    () => EnrollmentDraftDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentAckDao>(
    () => EnrollmentAckDao(getIt<Database>()),
  );
  // DAO de pull Inscription : découpés par discipline d'écriture — référentiel
  // (bundle full), viviers seed RE/PRE (cohorte + préinscriptions + lectures),
  // réconciliation (delta UPDATE-only + snapshots hydratants).
  getIt.registerLazySingleton<EnrollmentReferentialDao>(
    () => EnrollmentReferentialDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentSeedDao>(
    () => EnrollmentSeedDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<EnrollmentReconciliationDao>(
    () => EnrollmentReconciliationDao(getIt<Database>()),
  );
  // ── Ce qu'une ouverture de session décide du vivier de préinscriptions ──
  // `ref_pre_enrollments` n'a pas de colonne `school_id` : une tablette
  // réaffectée continuait de proposer les candidats de l'établissement
  // précédent. La garde efface le vivier ET rembobine le flux — jamais l'un
  // sans l'autre, cette table étant la seule source d'amorçage d'un brouillon.
  getIt.registerLazySingleton<PreEnrollmentsSchoolGuard>(
    () => PreEnrollmentsSchoolGuard(
      seedDao: getIt<EnrollmentSeedDao>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  // Recherche de tuteur existant (popin "Rechercher un parent", étape
  // Tuteurs) : lecture seule, DAO dédié (nouvelle responsabilité).
  getIt.registerLazySingleton<ParentSearchDao>(
    () => ParentSearchDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<FinanceLocalDao>(
    () => FinanceLocalDao(getIt<Database>(), getIt<IdGenerator>()),
  );

  // ── APIs Retrofit de synchro ────────────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentSyncApi>(
    () => EnrollmentSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EnrollmentPullApi>(
    () => EnrollmentPullApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<FinanceSyncApi>(
    () => FinanceSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<FinancePullApi>(
    () => FinancePullApi(getIt<Dio>()),
  );

  // ── Repositories offline-first ──────────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentOfflineRepository>(
    () => EnrollmentOfflineRepositoryImpl(
      readDao: getIt<EnrollmentReadDao>(),
      draftDao: getIt<EnrollmentDraftDao>(),
      seedDao: getIt<EnrollmentSeedDao>(),
      parentSearchDao: getIt<ParentSearchDao>(),
      idGenerator: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );
  getIt.registerLazySingleton<FinanceOfflineRepository>(
    () => FinanceOfflineRepositoryImpl(
      dao: getIt<FinanceLocalDao>(),
      idGenerator: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
      currentUser: getIt<CurrentUserContext>(),
      // Caissier et appareil stampés sur la ligne de paiement : le ticket
      // provisoire est une projection de `payments` (ADR-012 D-3/RG-012-11).
      authorDirectory: getIt<AuthSessionManager>(),
      deviceIdentity: getIt<DeviceIdentityService>(),
    ),
  );

  // ── Facturation : redirection des LECTURES online → local-first (Strat. C) ──
  // Les BLoCs/widgets online restent inchangés ; on REMPLACE la liaison des
  // repositories consommés par leurs usecases (`StudentChargesRepository` /
  // `PaymentsRepository`, enregistrés en amont dans injection.dart) par des
  // impls offline-first : lecture du grand-livre LOCAL (reste composé, FRONT §5)
  // + rafraîchissement ciblé best-effort (§6 step 2). Admin/create délégués à
  // l'online. `unregister` sûr : lazy singletons pas encore résolus à ce stade.
  // Enregistré plutôt qu'instancié dans la fermeture ci-dessous : c'est ce qui
  // le rend adressable, donc éprouvable sur le conteneur RÉEL
  // (`offline_core_wiring_test.dart`). Une fermeture anonyme aurait le même
  // effet et aucune preuve — le défaut le plus cher de ce chantier a été une
  // garde écrite, testée, et jamais branchée.
  getIt.registerLazySingleton<CoordinatorPaymentsSync>(
    () => CoordinatorPaymentsSync(getIt<PullCoordinator>()),
  );
  getIt.registerLazySingleton<FinanceLedgerRefresher>(
    () => FinanceLedgerRefresher(
      api: getIt<FinancePullApi>(),
      dao: getIt<FinanceLocalDao>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      connectivity: getIt<ConnectivityService>(),
      credentialsProbe: getIt<AuthSessionManager>(),
      extras: getIt<Map<String, dynamic>>(),
      // Le contrat n'a pas d'endpoint paiements scopé élève : la fraîcheur de
      // l'historique (et donc du « total payé » affiché) passe par le cycle
      // GLOBAL des paiements.
      //
      // ⚠️ Et parce qu'il est global, il passe par le COORDINATEUR — jamais en
      // direct sur le repository. C'était la treizième porte dérobée du lot F6 :
      // l'exemption accordée à Finance visait `finance_ledger:<studentId>`, dont
      // la clé est dynamique par élève ; celui-ci porte la clé de plan
      // `finance.payments` et un handler enregistré comme les autres. Appelé en
      // direct, il échappait à l'autorité du plan (F5), au filtre de droits et à
      // la diffusion sur le bus.
      //
      // Résolution paresseuse : les handlers sont enregistrés plus bas dans ce
      // même fichier, et `FinancePullRepository` juste après ce bloc.
      syncPayments: () => getIt<CoordinatorPaymentsSync>()(),
    ),
  );
  getIt.registerLazySingleton<FinancePullRepository>(
    () => FinancePullRepositoryImpl(
      api: getIt<FinancePullApi>(),
      dao: getIt<FinanceLocalDao>(),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  if (getIt.isRegistered<StudentChargesRepository>()) {
    getIt.unregister<StudentChargesRepository>();
  }
  getIt.registerLazySingleton<StudentChargesRepository>(
    () => StudentChargesOfflineFirstRepository(
      dao: getIt<FinanceLocalDao>(),
      refresh: getIt<FinanceLedgerRefresher>().refresh,
      online: StudentChargesRepositoryImpl(
        remoteDataSource: getIt<StudentChargesRemoteDataSource>(),
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    ),
  );
  if (getIt.isRegistered<PaymentsRepository>()) {
    getIt.unregister<PaymentsRepository>();
  }
  getIt.registerLazySingleton<PaymentsRepository>(
    () => PaymentsOfflineFirstRepository(
      dao: getIt<FinanceLocalDao>(),
      refresh: getIt<FinanceLedgerRefresher>().refresh,
      online: PaymentsRepositoryImpl(
        remoteDataSource: getIt<PaymentsRemoteDataSource>(),
        requiredAuth: getIt<Map<String, dynamic>>(),
      ),
    ),
  );
  // Pulls Inscription (référentiel / cohorte / préinscriptions / delta). La
  // grille tarifaire du bundle référentiel est déléguée à la Facturation, et le
  // catalogue boutique à la caisse, via deux seams étroits (même précédent que
  // le gate PAYMENT ci-dessous).
  getIt.registerLazySingleton<EnrollmentPullRepository>(
    () => EnrollmentPullRepositoryImpl(
      api: getIt<EnrollmentPullApi>(),
      referentialDao: getIt<EnrollmentReferentialDao>(),
      seedDao: getIt<EnrollmentSeedDao>(),
      reconciliationDao: getIt<EnrollmentReconciliationDao>(),
      replaceTariffs: (tariffs, academicYearIds) => getIt<FinanceLocalDao>()
          .replaceTariffsForYears(tariffs, academicYearIds: academicYearIds),
      // Même seam, même raison : le bundle porte le catalogue de la caisse, et
      // `enrollment` n'a rien à savoir de la boutique. Le `schoolId` est résolu
      // à l'appel et non à l'enregistrement — la DI offline est montée AVANT
      // l'authentification, l'école n'est pas encore connue ici.
      replaceBoutiqueArticles: (articles, academicYearIds) =>
          getIt<BoutiqueCatalogDao>().replaceArticlesForYears(
            articles,
            schoolId: getIt<CurrentUserContext>().schoolId ?? '',
            academicYearIds: academicYearIds,
          ),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
      currentUser: getIt<CurrentUserContext>(),
    ),
  );

  // ── Usecases ────────────────────────────────────────────────────────────────
  getIt.registerFactory<GetLocalEnrollmentsUseCase>(
    () => GetLocalEnrollmentsUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<GetLocalEnrollmentDetailUseCase>(
    () => GetLocalEnrollmentDetailUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SearchLocalEnrollmentsUseCase>(
    () => SearchLocalEnrollmentsUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  // Wizard offline-first : brouillon local persisté (M1).
  getIt.registerFactory<StartDraftUseCase>(
    () => StartDraftUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SeedDraftUseCase>(
    () => SeedDraftUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  // Seed RE/PRE depuis le local (cohorte N-1 / préinscriptions).
  getIt.registerFactory<GetReenrollmentCandidateUseCase>(
    () => GetReenrollmentCandidateUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<ProbeReenrollmentDossierUseCase>(
    () => ProbeReenrollmentDossierUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  // Garde d'éditique : le serveur connaît-il déjà cet élève ? Lue par le module
  // documents (pièces scopées élève), d'où sa place ici plutôt qu'en DI online.
  getIt.registerFactory<IsStudentKnownToServerUseCase>(
    () => IsStudentKnownToServerUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  // ── Anomalies d'encaissement (ADR-012 D-5, amendé) ─────────────────────────
  // Hors de l'outbox et hors de la pastille de synchro : une anomalie survit à
  // la synchro réussie qui l'a révélée, et ne s'éteint que sur accusé explicite.
  getIt.registerLazySingleton<PaymentAnomalyDao>(
    () => PaymentAnomalyDao(getIt<Database>()),
  );
  // `registerFactory`, comme TOUS les BLoCs du projet (règle non-négociable #2)
  // et comme `SyncStatusCubit` : l'instance unique app-lifetime est tenue par
  // `main.dart`, qui la fournit à l'arbre par `.value`. Un lazySingleton en DI
  // survivrait à un `getIt.reset()` de test et interdirait toute instance
  // isolée.
  getIt.registerFactory<PaymentAnomaliesCubit>(
    () => PaymentAnomaliesCubit(
      getIt<PaymentAnomalyDao>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );

  // ── Éditique : ticket provisoire (ADR-012 D-3) ─────────────────────────────
  // Lectures dédiées + composition 100 % locale : aucun appel réseau, c'est
  // toute la raison d'être du ticket.
  getIt.registerLazySingleton<ProvisionalTicketDao>(
    () => ProvisionalTicketDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<ProvisionalTicketRepository>(
    () => ProvisionalTicketRepositoryImpl(
      dao: getIt<ProvisionalTicketDao>(),
      // Le solde vient du domaine Facturation, seul détenteur de la sémantique
      // money-grade du reste à payer — jamais recomposé ici.
      finance: getIt<FinanceOfflineRepository>(),
      // Sert à ne proposer le rattrapage d'impression que sur les versements
      // encaissés par CETTE tablette.
      deviceIdentity: getIt<DeviceIdentityService>(),
    ),
  );
  getIt.registerFactory<AwaitsTicketPrintUseCase>(
    () => AwaitsTicketPrintUseCase(getIt<ProvisionalTicketRepository>()),
  );
  getIt.registerFactory<MarkTicketPrintedUseCase>(
    () => MarkTicketPrintedUseCase(getIt<ProvisionalTicketRepository>()),
  );
  getIt.registerFactory<BuildProvisionalTicketUseCase>(
    () => BuildProvisionalTicketUseCase(getIt<ProvisionalTicketRepository>()),
  );

  getIt.registerFactory<EditiqueEligibilityCubit>(
    () => EditiqueEligibilityCubit(getIt<IsStudentKnownToServerUseCase>()),
  );
  // Ce que la tablette sait du dossier : axe de synchro, pièces déjà scellées,
  // et — depuis L3.5 — celles dont elle détient réellement les octets, seule
  // source de ce qui est consultable hors ligne.
  getIt.registerFactory<DocumentsLocalDossierCubit>(
    () => DocumentsLocalDossierCubit(
      getIt<GetLocalEnrollmentDetailUseCase>(),
      getIt<ListCachedDocumentsUseCase>(),
    ),
  );
  getIt.registerFactory<GetPreEnrollmentUseCase>(
    () => GetPreEnrollmentUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  // Hydratation au montage des scopes : une seule dépendance, le coordinateur
  // (ADR-015 F6). Gardes, ordre, permissions et diffusion sont partis dans le
  // socle ; ces use cases ne portent plus que la liste des ressources dont leur
  // écran a besoin. Résolution paresseuse du `PullCoordinator` : les handlers
  // sont enregistrés en bas de cette fonction, bien après ces deux lignes.
  getIt.registerFactory<SyncEnrollmentPullsUseCase>(
    () => SyncEnrollmentPullsUseCase(getIt<PullCoordinator>()),
  );
  getIt.registerFactory<SyncFinancePullsUseCase>(
    () => SyncFinancePullsUseCase(getIt<PullCoordinator>()),
  );
  getIt.registerFactory<SaveDraftIdentityUseCase>(
    () => SaveDraftIdentityUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SaveDraftAddressUseCase>(
    () => SaveDraftAddressUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SaveDraftPreviousAcademicUseCase>(
    () =>
        SaveDraftPreviousAcademicUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SaveDraftTargetAcademicUseCase>(
    () => SaveDraftTargetAcademicUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SaveDraftGuardiansUseCase>(
    () => SaveDraftGuardiansUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SearchParentsUseCase>(
    () => SearchParentsUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<GetDraftDetailUseCase>(
    () => GetDraftDetailUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<FinalizeDraftUseCase>(
    () => FinalizeDraftUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<RecordPaymentUseCase>(
    () => RecordPaymentUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetPayerSuggestionsUseCase>(
    () => GetPayerSuggestionsUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<SearchPayersUseCase>(
    () => SearchPayersUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetLocalStudentChargesUseCase>(
    () => GetLocalStudentChargesUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetLocalPaymentsUseCase>(
    () => GetLocalPaymentsUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<HasFeeGridUseCase>(
    () => HasFeeGridUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetFeeTariffsForLevelUseCase>(
    () => GetFeeTariffsForLevelUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetFeeChargeAggregatesUseCase>(
    () => GetFeeChargeAggregatesUseCase(getIt<FinanceOfflineRepository>()),
  );

  getIt.registerFactory<InitializeChargesUseCase>(
    () => InitializeChargesUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetLedgerFreshnessUseCase>(
    () => GetLedgerFreshnessUseCase(getIt<FinanceLedgerRefresher>()),
  );
  getIt.registerFactory<WatchLedgerRevalidationUseCase>(
    () => WatchLedgerRevalidationUseCase(getIt<FinanceLedgerRefresher>()),
  );
  getIt.registerFactory<RefreshLedgerBeforeCollectionUseCase>(
    () => RefreshLedgerBeforeCollectionUseCase(getIt<FinanceLedgerRefresher>()),
  );
  getIt.registerFactory<GetPaymentReceiptDocumentUseCase>(
    () => GetPaymentReceiptDocumentUseCase(getIt<FinanceOfflineRepository>()),
  );

  // ── BLoCs (registerFactory) ─────────────────────────────────────────────────
  // Bloc offline UNIQUE du module Inscription (convergence lecture + brouillon
  // par étape + finalisation + pull).
  getIt.registerFactory<EnrollmentOfflineBloc>(
    () => EnrollmentOfflineBloc(
      getDetail: getIt<GetLocalEnrollmentDetailUseCase>(),
      startDraft: getIt<StartDraftUseCase>(),
      seedDraft: getIt<SeedDraftUseCase>(),
      getReenrollmentCandidate: getIt<GetReenrollmentCandidateUseCase>(),
      probeReenrollment: getIt<ProbeReenrollmentDossierUseCase>(),
      getPreEnrollment: getIt<GetPreEnrollmentUseCase>(),
      saveIdentity: getIt<SaveDraftIdentityUseCase>(),
      saveAddress: getIt<SaveDraftAddressUseCase>(),
      savePreviousAcademic: getIt<SaveDraftPreviousAcademicUseCase>(),
      saveTargetAcademic: getIt<SaveDraftTargetAcademicUseCase>(),
      saveGuardians: getIt<SaveDraftGuardiansUseCase>(),
      getDraftDetail: getIt<GetDraftDetailUseCase>(),
      finalize: getIt<FinalizeDraftUseCase>(),
      syncPulls: getIt<SyncEnrollmentPullsUseCase>(),
    ),
  );
  // Bloc DÉDIÉ du listing LOCAL (bascule dure 100 % local) — séparé du bloc
  // convergé ci-dessus pour éviter toute collision d'état (détail/brouillon
  // poussés) et ne pas le gonfler. Aucune lecture réseau.
  getIt.registerFactory<EnrollmentLocalListBloc>(
    () => EnrollmentLocalListBloc(
      getEnrollments: getIt<GetLocalEnrollmentsUseCase>(),
      search: getIt<SearchLocalEnrollmentsUseCase>(),
    ),
  );
  // Bloc transitoire de la popin "Rechercher un parent" (étape Tuteurs) —
  // créé/fermé avec la popin.
  getIt.registerFactory<ParentSearchBloc>(
    () => ParentSearchBloc(search: getIt<SearchParentsUseCase>()),
  );
  // Bloc transitoire de la popin « Choisir un payeur » (encaissement) —
  // créé/fermé avec la popin, comme la recherche de tuteur.
  getIt.registerFactory<PayerSearchBloc>(
    () => PayerSearchBloc(
      suggestions: getIt<GetPayerSuggestionsUseCase>(),
      search: getIt<SearchPayersUseCase>(),
    ),
  );
  getIt.registerFactory<FinanceOfflineBloc>(
    () => FinanceOfflineBloc(
      getCharges: getIt<GetLocalStudentChargesUseCase>(),
      getPayments: getIt<GetLocalPaymentsUseCase>(),
      recordPayment: getIt<RecordPaymentUseCase>(),
    ),
  );
  getIt.registerFactory<LedgerRevalidationCubit>(
    () => LedgerRevalidationCubit(getIt<WatchLedgerRevalidationUseCase>()),
  );
  getIt.registerFactory<LedgerFreshnessCubit>(
    () => LedgerFreshnessCubit(getIt<GetLedgerFreshnessUseCase>()),
  );
  // Factory : la ligne de rattrapage vit et meurt avec la modale de détail.
  getIt.registerFactory<TicketPrintStatusCubit>(
    () => TicketPrintStatusCubit(getIt<AwaitsTicketPrintUseCase>()),
  );
  getIt.registerFactory<PaymentReceiptCubit>(
    () => PaymentReceiptCubit(
      getIt<GetPaymentReceiptDocumentUseCase>(),
      getIt<FindCachedDocumentUseCase>(),
    ),
  );

  // ── Handlers d'outbox → SyncEngine ──────────────────────────────────────────
  final extras = getIt<Map<String, dynamic>>();
  getIt<SyncEngine>().registerHandler(
    EnrollmentOutboxHandler(
      api: getIt<EnrollmentSyncApi>(),
      dao: getIt<EnrollmentAckDao>(),
      extras: extras,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    PaymentOutboxHandler(
      api: getIt<FinanceSyncApi>(),
      dao: getIt<FinanceLocalDao>(),
      dependency: (studentId, academicYearId) => getIt<EnrollmentReadDao>()
          .studentEnrollmentDependency(studentId, academicYearId),
      extras: extras,
    ),
  );

  // ── Handlers de pull (routés par ressource sur le coordinateur) ────────────
  // Le référentiel est enregistré en premier : c'est le socle (années/niveaux/
  // tarifs) dont dépendent logiquement les autres caches. L'ordre est désormais
  // PORTEUR pour la paire snapshots/delta : le pull HYDRATANT (snapshots) INSÈRE
  // les lignes que le delta MAIGRE ne fait qu'UPDATE — snapshots DOIT donc
  // précéder enrollmentDelta (le coordinateur exécute dans l'ordre
  // d'enregistrement).
  //
  // Depuis le repli F6, cet ordre n'est plus recopié nulle part : c'est la SEULE
  // déclaration. `SyncEnrollmentPullsUseCase` ne donne qu'un ENSEMBLE de
  // ressources au coordinateur, qui itère ce registre-ci — les accolades du use
  // case n'ordonnent rien. L'arête est verrouillée par
  // `test/core/di/offline_pull_registration_order_test.dart`.
  final pullRepository = getIt<EnrollmentPullRepository>();
  getIt<PullCoordinator>()
    ..registerHandler(EnrollmentPullHandler.referential(pullRepository))
    ..registerHandler(EnrollmentPullHandler.reenrollmentCohort(pullRepository))
    ..registerHandler(EnrollmentPullHandler.preEnrollments(pullRepository))
    ..registerHandler(EnrollmentPullHandler.enrollmentSnapshots(pullRepository))
    ..registerHandler(EnrollmentPullHandler.enrollmentDelta(pullRepository));

  // Pulls KEYSET du grand-livre Facturation (§2.1 créances, §2.2 paiements).
  // Créances D'ABORD (la vérité du grand-livre : soldes/statuts autoritaires),
  // paiements ENSUITE (les événements, y compris ceux de l'autre poste).
  //
  // ⚠️ CET ORDRE EST UN CHOIX MONEY-GRADE, NE PAS L'INVERSER. Les deux pulls ne
  // sont pas atomiques entre eux ; le sens de la panne dépend de l'ordre :
  //  - créances OK / paiements KO (ordre actuel) → le solde autoritaire compte
  //    déjà un paiement local resté non-SYNCED, que `getChargesByStudent`
  //    redéduit → créance affichée SUR-payée → le caissier REFUSE un
  //    encaissement. Friction, aucun argent perdu. Se résorbe seul (rejeu
  //    outbox, pull des paiements, ou le refresher qui enchaîne les deux).
  //  - paiements OK / créances KO (ordre inverse) → le paiement passe SYNCED et
  //    sort du `pending` alors que `amount_paid` est encore périmé → créance
  //    affichée IMPAYÉE → le caissier RÉENCAISSE. Argent perdu.
  // Le contrat n'expose aucun `serverSeenAt` sur le paiement : sans ce signal on
  // ne peut pas rendre la lecture exacte pendant la fenêtre — on choisit donc le
  // sens de panne conservateur.
  final financePullRepository = getIt<FinancePullRepository>();
  getIt<PullCoordinator>()
    ..registerHandler(FinancePullHandler.studentCharges(financePullRepository))
    ..registerHandler(FinancePullHandler.payments(financePullRepository));
}
