import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ack_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_draft_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_read_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/dao/enrollment_ref_dao.dart';
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
  getIt.registerLazySingleton<EnrollmentRefDao>(
    () => EnrollmentRefDao(getIt<Database>()),
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

  // ── Repositories offline-first ──────────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentOfflineRepository>(
    () => EnrollmentOfflineRepositoryImpl(
      readDao: getIt<EnrollmentReadDao>(),
      draftDao: getIt<EnrollmentDraftDao>(),
      refDao: getIt<EnrollmentRefDao>(),
      idGenerator: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerLazySingleton<FinanceOfflineRepository>(
    () => FinanceOfflineRepositoryImpl(
      dao: getIt<FinanceLocalDao>(),
      idGenerator: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  // Pulls Inscription (référentiel / cohorte / préinscriptions / delta). La
  // grille tarifaire du bundle référentiel est déléguée à la Facturation via
  // un seam étroit (même précédent que le gate PAYMENT ci-dessous).
  getIt.registerLazySingleton<EnrollmentPullRepository>(
    () => EnrollmentPullRepositoryImpl(
      api: getIt<EnrollmentPullApi>(),
      refDao: getIt<EnrollmentRefDao>(),
      replaceTariffs: (tariffs, academicYearIds) => getIt<FinanceLocalDao>()
          .replaceTariffsForYears(tariffs, academicYearIds: academicYearIds),
      syncMetaDao: getIt<SyncMetaDao>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
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
    () => SyncEnrollmentPullsUseCase(getIt<EnrollmentPullRepository>()),
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
      isStudentEnrollmentSynced: (studentId) =>
          getIt<EnrollmentReadDao>().isStudentEnrollmentSynced(studentId),
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
}
