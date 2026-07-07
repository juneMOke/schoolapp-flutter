import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/enrollment_local_dao.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_offline_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_outbox_handler.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/enrollment_sync_api.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/repositories/enrollment_offline_repository.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/confirm_enrollment_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/finalize_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_draft_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_address_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_guardians_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_identity_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_previous_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/save_draft_target_academic_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/search_local_enrollments_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/start_draft_use_case.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_draft_bloc.dart';
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
  getIt.registerLazySingleton<EnrollmentLocalDao>(
    () => EnrollmentLocalDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<FinanceLocalDao>(
    () => FinanceLocalDao(getIt<Database>(), getIt<IdGenerator>()),
  );

  // ── APIs Retrofit de synchro ────────────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentSyncApi>(
    () => EnrollmentSyncApi(getIt<Dio>()),
  );
  getIt.registerLazySingleton<FinanceSyncApi>(
    () => FinanceSyncApi(getIt<Dio>()),
  );

  // ── Repositories offline-first ──────────────────────────────────────────────
  getIt.registerLazySingleton<EnrollmentOfflineRepository>(
    () => EnrollmentOfflineRepositoryImpl(
      dao: getIt<EnrollmentLocalDao>(),
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

  // ── Usecases ────────────────────────────────────────────────────────────────
  getIt.registerFactory<ConfirmEnrollmentUseCase>(
    () => ConfirmEnrollmentUseCase(getIt<EnrollmentOfflineRepository>()),
  );
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
  getIt.registerFactory<EnrollmentOfflineBloc>(
    () => EnrollmentOfflineBloc(
      getEnrollments: getIt<GetLocalEnrollmentsUseCase>(),
      search: getIt<SearchLocalEnrollmentsUseCase>(),
      getDetail: getIt<GetLocalEnrollmentDetailUseCase>(),
      confirm: getIt<ConfirmEnrollmentUseCase>(),
    ),
  );
  getIt.registerFactory<EnrollmentDraftBloc>(
    () => EnrollmentDraftBloc(
      startDraft: getIt<StartDraftUseCase>(),
      saveIdentity: getIt<SaveDraftIdentityUseCase>(),
      saveAddress: getIt<SaveDraftAddressUseCase>(),
      savePreviousAcademic: getIt<SaveDraftPreviousAcademicUseCase>(),
      saveTargetAcademic: getIt<SaveDraftTargetAcademicUseCase>(),
      saveGuardians: getIt<SaveDraftGuardiansUseCase>(),
      getDetail: getIt<GetDraftDetailUseCase>(),
      finalize: getIt<FinalizeDraftUseCase>(),
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
      dao: getIt<EnrollmentLocalDao>(),
      extras: extras,
    ),
  );
  getIt<SyncEngine>().registerHandler(
    PaymentOutboxHandler(
      api: getIt<FinanceSyncApi>(),
      dao: getIt<FinanceLocalDao>(),
      isStudentEnrollmentSynced: (studentId) =>
          getIt<EnrollmentLocalDao>().isStudentEnrollmentSynced(studentId),
      extras: extras,
    ),
  );
}
