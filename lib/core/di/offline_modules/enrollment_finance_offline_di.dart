import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/auth/data/services/auth_session_manager.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_reconciliation_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_referential_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_seed_dao.dart';
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
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_reenrollment_candidate_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/probe_reenrollment_dossier_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_address_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_guardians_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_identity_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_previous_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_target_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/seed_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/start_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/data/local/finance_local_dao.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_offline_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/finance_sync_api.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/payment_outbox_handler.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_payments_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_local_student_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/initialize_charges_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/record_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
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
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_ledger_freshness_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';

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
    ),
  );

  // ── Facturation : redirection des LECTURES online → local-first (Strat. C) ──
  // Les BLoCs/widgets online restent inchangés ; on REMPLACE la liaison des
  // repositories consommés par leurs usecases (`StudentChargesRepository` /
  // `PaymentsRepository`, enregistrés en amont dans injection.dart) par des
  // impls offline-first : lecture du grand-livre LOCAL (reste composé, FRONT §5)
  // + rafraîchissement ciblé best-effort (§6 step 2). Admin/create délégués à
  // l'online. `unregister` sûr : lazy singletons pas encore résolus à ce stade.
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
      // global. Résolu paresseusement — `FinancePullRepository` est enregistré
      // juste après.
      syncPayments: () async =>
          (await getIt<FinancePullRepository>().syncPayments()).isRight(),
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
  // grille tarifaire du bundle référentiel est déléguée à la Facturation via
  // un seam étroit (même précédent que le gate PAYMENT ci-dessous).
  getIt.registerLazySingleton<EnrollmentPullRepository>(
    () => EnrollmentPullRepositoryImpl(
      api: getIt<EnrollmentPullApi>(),
      referentialDao: getIt<EnrollmentReferentialDao>(),
      seedDao: getIt<EnrollmentSeedDao>(),
      reconciliationDao: getIt<EnrollmentReconciliationDao>(),
      replaceTariffs: (tariffs, academicYearIds) => getIt<FinanceLocalDao>()
          .replaceTariffsForYears(tariffs, academicYearIds: academicYearIds),
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
  getIt.registerFactory<GetPreEnrollmentUseCase>(
    () => GetPreEnrollmentUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<SyncEnrollmentPullsUseCase>(
    () => SyncEnrollmentPullsUseCase(
      getIt<EnrollmentPullRepository>(),
      getIt<AuthSessionManager>(),
      getIt<ConnectivityService>(),
    ),
  );
  getIt.registerFactory<SyncFinancePullsUseCase>(
    () => SyncFinancePullsUseCase(
      getIt<FinancePullRepository>(),
      getIt<AuthSessionManager>(),
      getIt<ConnectivityService>(),
    ),
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
  getIt.registerFactory<GetDraftDetailUseCase>(
    () => GetDraftDetailUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<FinalizeDraftUseCase>(
    () => FinalizeDraftUseCase(getIt<EnrollmentOfflineRepository>()),
  );
  getIt.registerFactory<RecordPaymentUseCase>(
    () => RecordPaymentUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetLocalStudentChargesUseCase>(
    () => GetLocalStudentChargesUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetLocalPaymentsUseCase>(
    () => GetLocalPaymentsUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<InitializeChargesUseCase>(
    () => InitializeChargesUseCase(getIt<FinanceOfflineRepository>()),
  );
  getIt.registerFactory<GetLedgerFreshnessUseCase>(
    () => GetLedgerFreshnessUseCase(getIt<FinanceLedgerRefresher>()),
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
  getIt.registerFactory<FinanceOfflineBloc>(
    () => FinanceOfflineBloc(
      getCharges: getIt<GetLocalStudentChargesUseCase>(),
      getPayments: getIt<GetLocalPaymentsUseCase>(),
      recordPayment: getIt<RecordPaymentUseCase>(),
    ),
  );
  getIt.registerFactory<LedgerFreshnessCubit>(
    () => LedgerFreshnessCubit(getIt<GetLedgerFreshnessUseCase>()),
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
  // d'enregistrement). Cf. la même liste dans SyncEnrollmentPullsUseCase.
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
