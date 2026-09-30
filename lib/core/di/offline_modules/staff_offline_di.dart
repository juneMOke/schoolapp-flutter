import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/di/offline_modules/staff_documents_di.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_document_type_dao.dart';
import 'package:school_app_flutter/core/offline/id_generator.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_contract_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_correction_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_contract_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_contract_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_contract_use_cases.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_contracts_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_sync_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_write_dao.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_member_outbox_handler.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/staff_member_use_cases.dart';
import 'package:school_app_flutter/core/offline/pull_completion_bus.dart';
import 'package:school_app_flutter/core/offline/sync_engine.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_repository.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/load_staff_file_use_case.dart';
import 'package:school_app_flutter/features/staff/domain/usecases/sync_staff_pulls_use_case.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_file_cubit.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_snapshot_source.dart';
import 'package:school_app_flutter/core/offline/current_user_context.dart';
import 'package:school_app_flutter/core/offline/keyset_pull_runner.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/sync_meta_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_contract_dao.dart';
import 'package:school_app_flutter/features/staff/data/local/staff_member_dao.dart';
import 'package:school_app_flutter/features/staff/data/repositories/staff_pull_repository_impl.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_pull_handlers.dart';
import 'package:school_app_flutter/features/staff/data/sync/staff_sync_api.dart';
import 'package:school_app_flutter/features/staff/domain/repositories/staff_pull_repository.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Le fichier du personnel (RH, sous-module A) : ses tables locales, ses trois
/// descentes et, lot après lot, ses remontées et ses écrans.
///
/// Le module ne dépend d'aucun autre module métier. Les pièces exigées lui
/// arrivent par le référentiel, qui écrit `ref_staff_document_types` par un
/// seam résolvant [StaffDocumentTypeDao] paresseusement.
void registerStaffOffline(GetIt getIt) {
  getIt.registerLazySingleton<StaffMemberDao>(
    () => StaffMemberDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffMemberWriteDao>(
    () => StaffMemberWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffMemberSyncDao>(
    () => StaffMemberSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffContractDao>(
    () => StaffContractDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffContractWriteDao>(
    () => StaffContractWriteDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffContractSyncDao>(
    () => StaffContractSyncDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffDocumentDao>(
    () => StaffDocumentDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffDocumentTypeDao>(
    () => StaffDocumentTypeDao(getIt<Database>()),
  );
  getIt.registerLazySingleton<StaffSyncApi>(() => StaffSyncApi(getIt<Dio>()));

  // ── Lecture locale ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<StaffRepository>(
    () => StaffRepositoryImpl(
      members: getIt<StaffMemberDao>(),
      contracts: getIt<StaffContractDao>(),
      writer: getIt<StaffMemberWriteDao>(),
      documents: getIt<StaffDocumentDao>(),
      types: getIt<StaffDocumentTypeDao>(),
      syncMeta: getIt<SyncMetaDao>(),
      currentUser: getIt<CurrentUserContext>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadStaffFileUseCase>(
    () => LoadStaffFileUseCase(getIt<StaffRepository>()),
  );
  getIt.registerFactory<SaveStaffMemberUseCase>(
    () => SaveStaffMemberUseCase(getIt<StaffRepository>()),
  );
  getIt.registerFactory<LoadStaffMemberUseCase>(
    () => LoadStaffMemberUseCase(getIt<StaffRepository>()),
  );
  getIt.registerLazySingleton<StaffContractRepository>(
    () => StaffContractRepositoryImpl(
      contracts: getIt<StaffContractDao>(),
      writer: getIt<StaffContractWriteDao>(),
      currentUser: getIt<CurrentUserContext>(),
      ids: getIt<IdGenerator>(),
      syncEngine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<LoadStaffContractsUseCase>(
    () => LoadStaffContractsUseCase(getIt<StaffContractRepository>()),
  );
  getIt.registerFactory<AddStaffContractUseCase>(
    () => AddStaffContractUseCase(getIt<StaffContractRepository>()),
  );
  getIt.registerFactory<CorrectStaffContractUseCase>(
    () => CorrectStaffContractUseCase(getIt<StaffContractRepository>()),
  );
  getIt.registerFactory<SyncStaffPullsUseCase>(
    () => SyncStaffPullsUseCase(getIt<PullCoordinator>()),
  );

  // ── Présentation ────────────────────────────────────────────────────────
  getIt.registerFactory<StaffSnapshotSource>(
    () => StaffSnapshotSource(
      load: getIt<LoadStaffFileUseCase>(),
      pulls: getIt<SyncStaffPullsUseCase>(),
      bus: getIt<PullCompletionBus>(),
      engine: getIt<SyncEngine>(),
    ),
  );
  getIt.registerFactory<StaffFileCubit>(
    () => StaffFileCubit(source: getIt<StaffSnapshotSource>()),
  );
  getIt.registerFactory<StaffContractsCubit>(
    () => StaffContractsCubit(
      load: getIt<LoadStaffContractsUseCase>(),
      add: getIt<AddStaffContractUseCase>(),
      correct: getIt<CorrectStaffContractUseCase>(),
    ),
  );

  // ── Descente ────────────────────────────────────────────────────────────
  // Trois flux, trois droits : le plan n'annonce à une tablette que ce que son
  // compte a le droit de lire, et le coordinateur ne tire que ce qui est
  // annoncé.
  getIt.registerLazySingleton<StaffPullRepository>(
    () => StaffPullRepositoryImpl(
      api: getIt<StaffSyncApi>(),
      runner: KeysetPullRunner(getIt<SyncMetaDao>()),
      members: getIt<StaffMemberDao>(),
      contracts: getIt<StaffContractDao>(),
      documents: getIt<StaffDocumentDao>(),
      currentUser: getIt<CurrentUserContext>(),
      requiredAuth: getIt<Map<String, dynamic>>(),
    ),
  );
  final coordinator = getIt<PullCoordinator>();
  final pulls = getIt<StaffPullRepository>();
  coordinator.registerHandler(StaffPullHandler.members(pulls));
  coordinator.registerHandler(StaffPullHandler.contracts(pulls));
  coordinator.registerHandler(StaffPullHandler.documents(pulls));

  // ── Remontée → SyncEngine ───────────────────────────────────────────────
  // Trois gestes, trois entrées : la pose d'un contrat attend l'accusé de sa
  // fiche, la correction celui de la période corrigée (`blocked`).
  final engine = getIt<SyncEngine>();
  engine.registerHandler(
    StaffMemberOutboxHandler(
      api: getIt<StaffSyncApi>(),
      dao: getIt<StaffMemberSyncDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  engine.registerHandler(
    StaffContractOutboxHandler(
      api: getIt<StaffSyncApi>(),
      dao: getIt<StaffContractSyncDao>(),
      members: getIt<StaffMemberDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );
  engine.registerHandler(
    StaffContractCorrectionOutboxHandler(
      api: getIt<StaffSyncApi>(),
      dao: getIt<StaffContractSyncDao>(),
      currentUser: getIt<CurrentUserContext>(),
      extras: getIt<Map<String, dynamic>>(),
    ),
  );

  registerStaffDocuments(getIt);
}
